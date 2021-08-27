import 'package:csv/csv.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class DataBaseFunctions {
  static const String C_DATABASE_NAME = "default_db";

  // --------------------------------------------------------------------------------------- UPGRADE USER
  static Future<UserDto?> alterUserByTransaction(String email,
      WardenType wardenType, SchemaMetaData smd, DbTransaction transaction,
      {bool closeTransaction = true}) async {
    // Retrieve User
    UserDto? userDto;
    try {
      UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
      await userStoreDao.init();
      UserStoreDto? userStoreDto;
      try {
        userStoreDto = await userStoreDao.getUserStoreDtoByUnique(email);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("$e");
          return null;
        }
      }
      UserDao userDao = UserDao(smd, transaction);
      await userDao.init();
      try {
        userDto = await userDao.getUserDtoById(userStoreDto!.id!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("$e");
          return null;
        }
      }
      if (wardenType != null) userDto!.warden = wardenType;
      userDto!.pass_key = "";
      try {
        await userDao.setUserDto(userDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("$e");
          return null;
        }
      }
    } finally {
      if (closeTransaction) {
        await transaction.connection.close();
        await transaction.endTransaction();
        await transaction.closePool();
      }
    }
    return userDto;
  }

  static Future<void> alterUser(String email, WardenType wardenType,
      SchemaMetaData smd, String database) async {
    MySqlStore poolStore = MySqlStore();
    AbstractPool pool = poolStore.getMySqlPool(database);
    DbTransaction transaction = DbTransaction(pool);
    try {
      await transaction.beginTransaction();
    } catch (e) {
      print("WS $e");
    }
    await alterUserByTransaction(email, wardenType, smd, transaction);
  }

  // --------------------------------------------------------------------------------------- CHANGE CONFIGURATION
  static Future<void> updateConfiguration(
      WardenType configurationWardenType,
      ConfigurationNameEnum configurationNameEnum,
      int? ordinal,
      int? valueNumber,
      String? valueString,
      bool writeTr,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      String database,
      ConfigurationNameDefaults defaults) async {
    if (defaults == null)
      throw ArgumentError(AbstractTableTransactions.C_MUST_PASS_DEFAULTS);
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(database);

    try {
      await updateConfigurationByTransaction(
          configurationWardenType,
          configurationNameEnum,
          ordinal,
          valueNumber,
          valueString,
          writeTr,
          smd,
          smdSys,
          mysqlTransaction,
          defaults);
    } finally {
      await mysqlTransaction.connection.close();
      await mysqlTransaction.endTransaction();
      await mysqlTransaction.closePool();
    }
  }

  static Future<void> updateConfigurationByTransaction(
      WardenType configurationWardenType,
      ConfigurationNameEnum configurationNameEnum,
      int? ordinal,
      int? valueNumber,
      String? valueString,
      bool writeTr,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      ConfigurationNameDefaults defaults) async {
    if (defaults == null)
      throw ArgumentError(AbstractTableTransactions.C_MUST_PASS_DEFAULTS);
    if (ordinal == null) ordinal = 0;
    if (!writeTr) {
      // If local & remote Wardens are the same dont update WaterLine / HC for propagation
      ConfigurationDao configurationDao =
          ConfigurationDao(smd, transaction, defaults);
      await configurationDao.init(initTable: false);
      await configurationDao.insertDefaultValues();
      ConfigurationDto configurationDto = ConfigurationDto.sep(
          null,
          0,
          configurationWardenType,
          configurationNameEnum,
          ordinal,
          valueNumber,
          valueString,
          defaults);
      try {
        await configurationDao.setConfigurationDto(configurationDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("$e");
          return null;
        }
      }
    } else {
      TrDto trDto = TrDto.wee(ConfigurationMixin.C_TABLE_ID);
      trDto.sep(null, OperationType.UPDATE, 0, null, "Update by Script", null,
          ConfigurationMixin.C_TABLE_ID);
      ConfigurationTrDto configurationTrDto = ConfigurationTrDto.sep(
          null,
          0,
          configurationWardenType,
          configurationNameEnum,
          ordinal,
          valueNumber,
          valueString,
          trDto,
          defaults);

      ConfigurationTransactions configurationTransactions =
          ConfigurationTransactions.sep(configurationTrDto);
      await configurationTransactions.init(WardenType.WRITE_SERVER,
          WardenType.WRITE_SERVER, smd, smdSys, transaction,
          defaults: defaults);
      AbstractWarden abstractWarden = WardenFactory.getAbstractWarden(
          WardenType.WRITE_SERVER, WardenType.WRITE_SERVER);
      await abstractWarden.init(smd, smdSys, transaction);
      abstractWarden.initialize(configurationTransactions,
          passedWaterState: WaterState.SERVER_APPROVED);
      try {
        await abstractWarden.write();
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
          print("WS $e");
        }
      }
    }
  }

//---------------------------------------------------------------------------------------- LIST STRAYS
// Import the database by processing each water_line entry in the system
  static Future<void> listStrays(bool purge, SchemaMetaData smdSys) async {
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    try {
      await StrayTables.showAllStrays(purge, smdSys, mysqlTransaction);
    } finally {
      await mysqlTransaction.connection.close();
      await mysqlTransaction.endTransaction();
      await mysqlTransaction.closePool();
    }
    print("Imported to " + C_DATABASE_NAME + " mysql");
  }

//---------------------------------------------------------------------------------------- PURGE LOGS
// Purge the database logs
  static Future<void> purgeLogs(int hoursToKeep) async {
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    AbstractDatabase db = mysqlTransaction.getConnection();
    print("Purging logs in " + C_DATABASE_NAME + " mysql");
    DateTime cal = DateTime.now();
    cal.add(Duration(hours: hoursToKeep * -1));
    int unixTime = cal.millisecondsSinceEpoch;

    String sql;
    // ---------------------------------------------------------------------- PROPERTY
    try {
      sql = "   DELETE " + "     FROM logging_event_property ";
      await db.updateQuery(sql);
    } on SqlException catch (e) {
      print("$e");
    }
    // ---------------------------------------------------------------------- EXCEPTION
    try {
      sql = "   DELETE " +
          "     FROM logging_event_exception  " +
          "    WHERE event_id in " +
          "      (   SELECT event_id " +
          "            FROM logging_event " +
          "           WHERE timestmp <" +
          unixTime.toString() +
          "      )";
      await db.updateQuery(sql);
    } on SqlException catch (e) {
      print("$e");
    }
    // ---------------------------------------------------------------------- EVENT
    try {
      sql = "   DELETE " +
          "     FROM logging_event " +
          "    WHERE timestmp <= " +
          unixTime.toString();
      await db.updateQuery(sql);
    } on SqlException catch (e) {
      print("$e");
    }
    try {
      if (db != null) await db.close();
    } on SqlException catch (e) {
      print("$e");
    }
  }

  static Future<void> clean(SchemaMetaData smd, SchemaMetaData smdSys) async {
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    try {
      CleanTables cleanTables = CleanTables(smd, smdSys, mysqlTransaction);
      await cleanTables.init();
      await cleanTables.deleteDuplicates();
    } finally {
      await mysqlTransaction.connection.close();
      await mysqlTransaction.endTransaction();
      await mysqlTransaction.closePool();
    }
  }

  static Future<void> toggleServer(
      SchemaMetaData smd, ConfigurationNameDefaults defaults) async {
    final WardenType C_WARDEN_TYPE = WardenType.USER;
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    try {
      ConfigurationDao configurationDao =
          ConfigurationDao(smd, mysqlTransaction, defaults);
      await configurationDao.init(initTable: true);
      bool testServer = true;
      try {
        await configurationDao.getString(ConfigurationUtils.C_TEST_SUBSET,
            C_WARDEN_TYPE, ConfigurationNameEnum.WEB_URL);
        testServer = true;
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          testServer = false;
      }
      ConfigurationUtils cu =
          ConfigurationUtils(C_WARDEN_TYPE, smd, mysqlTransaction, defaults);
      await cu.init();
      if (testServer) {
        await cu.fetchConfigurationString(ConfigurationNameEnum.WEB_URL);
      } else {
        await cu.storeConfigurationString(
            ConfigurationNameEnum.WEB_URL, ConfigurationUtils.C_TEST_WEB);
      }
    } finally {
      await mysqlTransaction.connection.close();
      await mysqlTransaction.endTransaction();
      await mysqlTransaction.closePool();
    }
  }

  static Future<void> addEntry(int table_id, String? csv, WaterState waterState,
      SchemaMetaData smd, SchemaMetaData smdSys) async {
    WardenType localWardenType = WardenType.WRITE_SERVER;
    WardenType remoteWardenType = WardenType.WRITE_SERVER;
    switch (waterState) {
      case WaterState.CLIENT_STORED:
      case WaterState.CLIENT_REJECTED:
      case WaterState.CLIENT_APPROVED:
        remoteWardenType = WardenType.ADMIN;
        break;
      case WaterState.SERVER_PENDING:
        remoteWardenType = WardenType.USER;
        break;
      case WaterState.SERVER_APPROVED:
      case WaterState.SERVER_REJECTED:
        break;
      default:
        throw ArgumentError("Invalid WaterState " + waterState.toString());
    }
    List<List<dynamic>> csvList = const CsvToListConverter().convert(csv,
        fieldDelimiter: '|',
        textDelimiter: "'",
        textEndDelimiter: "'",
        eol: '\n');
    TableMetaData tmd = smd.getTableByTableId(table_id);
    int offset = 0;
    FieldData fieldData = FieldData.wee(table_id);
    csvList.forEach((List<dynamic> list) {
      list.forEach((dynamic element) {
        FieldMetaData fmd = tmd.getFieldByIndex(offset + 1);
        fieldData.set(fmd.fieldName, element);
        offset++;
      });
    });
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    try {
      TrDto trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
          'Command Line Insert', null, table_id,
          fieldData: fieldData);
      TableTransactions tableTransactions = TableTransactions.sep(trDto);
      await tableTransactions.init(
          localWardenType, remoteWardenType, smd, smdSys, mysqlTransaction);
      AbstractWarden warden =
          WardenFactory.getAbstractWarden(localWardenType, remoteWardenType);
      await warden.init(smd, smdSys, mysqlTransaction);
      warden.initialize(tableTransactions, passedWaterState: waterState);
      RemoteDto? remoteDto = null;
      try {
        remoteDto = await warden.write();
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("$e");
        }
      }
    } finally {
      await mysqlTransaction.connection.close();
      await mysqlTransaction.endTransaction();
      await mysqlTransaction.closePool();
    }
  }
}
