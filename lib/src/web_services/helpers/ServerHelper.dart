import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class ServerHelper {
  static const String C_CMD_ROCKVOLE = './rockvole_helper.sh';
  // --------------------------------------------------------------------------------------- SET SERVER
  static Future<void> addServerByDbName(String email, WardenType wardenType,
      SchemaMetaData smd, SchemaMetaData smdSys, String database) async {
    MySqlStore poolStore = MySqlStore();
    AbstractPool pool = poolStore.getMySqlPool(database);
    DbTransaction transaction = DbTransaction(pool);
    try {
      await transaction.beginTransaction();
    } on SqlException catch (e) {
      print("WS $e");
    }
    try {
      await addServer(email, wardenType, smd, smdSys, transaction);
    } finally {
      await transaction.connection.close();
      await transaction.endTransaction();
      await transaction.closePool();
    }
  }

  static Future<void> addServer(
      String email,
      WardenType wardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction) async {
    UserDao userDao = UserDao(smd, transaction);
    await userDao.init();
    int count = 0;
    try {
      List<UserDto> list =
          await userDao.getUserDtoList(null, null, null, wardenType, null);
      count = list.length;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
      } else
        rethrow;
    }
    count++;
    StringUtils stringUtils = StringUtils();
    String passKey = stringUtils.randomAlphaNumericString(20);
    UserDto userDto = UserDto.sep(null, passKey, count, wardenType, 0, 0);
    int requestOffsetSecs = NumberUtils.randInt(0, TimeUtils.C_SECS_IN_DAY);
    RemoteDto? remoteDto = await CrudHelper.insertUser(
        null,
        passKey,
        count,
        wardenType,
        requestOffsetSecs,
        TimeUtils.getNowCustomTs(),
        transaction,
        WardenType.WRITE_SERVER,
        WardenType.WRITE_SERVER,
        smd,
        smdSys);
    await CrudHelper.insertUserStore(
        remoteDto!.trDto.id,
        email,
        0,
        null,
        null,
        0,
        0,
        0,
        transaction,
        WardenType.WRITE_SERVER,
        WardenType.WRITE_SERVER,
        smd,
        smdSys);
    if (remoteDto != null) {
      userDto = UserDto.field(remoteDto.trDto.getFieldDataNoTr);
      print("insert into user values ('" +
          userDto.id.toString() +
          "','" +
          userDto.pass_key.toString() +
          "'," +
          userDto.subset.toString() +
          "," +
          userDto.warden.toString() +
          "," +
          userDto.request_offset_secs.toString() +
          "," +
          userDto.registered_ts.toString() +
          ");");
    }
    await transaction.connection.close();
    await transaction.endTransaction();
    await transaction.closePool();
    if (remoteDto != null) {
      print("");
      print("Now type on the client :");
      print(C_CMD_ROCKVOLE+" setuser " +
          remoteDto.trDto.id.toString() +
          " $email $passKey " +
          Warden.getSimpleWardenString(wardenType));
      print(C_CMD_ROCKVOLE+" setserverid " + remoteDto.trDto.id.toString());
    }
  }

  // --------------------------------------------------------------------------------------- SET SERVER ID
  static Future<void> setServerUserId(
      int currentUserId, SchemaMetaData smd, DbTransaction transaction) async {
    UserTools userTools = UserTools();
    try {
      await userTools.setCurrentUserId(smd, transaction, currentUserId);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
  }

  static Future<void> initializeConfiguration(
      WardenType wardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      ConfigurationNameDefaults defaults) async {
    ConfigurationDao configurationDao =
        ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    try {
      ConfigurationDto configurationDto =
          await configurationDao.getConfigurationDtoByUnique(
              0, wardenType, ConfigurationNameEnum.ROWS_LIMIT, 0);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        print("---------- insert defaults");
        await configurationDao.insertDefaultValues();
        print("---------- insert defaults complete");
      }
    }
  }
}
