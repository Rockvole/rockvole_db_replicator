import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class CrudHelper {
  // ----------------------------------------------------------------------------------------------------------------- CONFIGURATION
  static Future<RemoteDto?> insertConfiguration(
      ConfigurationNameEnum configurationName,
      int valueNumber,
      String? valueString,
      int ts,
      DbTransaction transaction,
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults) async {
    TrDto trDto = TrDto.sep(ts, OperationType.INSERT, 5, null, null, null,
        ConfigurationMixin.C_TABLE_ID);
    ConfigurationTrDto configurationTrDto = ConfigurationTrDto.sep(
        null,
        0,
        WardenType.USER,
        configurationName,
        0,
        valueNumber,
        valueString,
        trDto,
        defaults);
    return writeTables(configurationTrDto, localWardenType, remoteWardenType,
        transaction, smd, smdSys);
  }

  // ----------------------------------------------------------------------------------------------------------------- USER
  static Future<RemoteDto?> insertUser(
      int? id,
      String passKey,
      int subset,
      WardenType wardenType,
      int requestOffsetSecs,
      int registeredTs,
      DbTransaction transaction,
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    TrDto trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
        "Insert into User", 0, UserMixin.C_TABLE_ID);
    UserTrDto userTrDto = UserTrDto.sep(id, passKey, subset, wardenType,
        requestOffsetSecs, registeredTs, trDto);
    return await writeTables(userTrDto, localWardenType,
        remoteWardenType, transaction, smd, smdSys);
  }

  // ----------------------------------------------------------------------------------------------------------------- USER STORE
  static Future<RemoteDto?> insertUserStore(
      int? id,
      String? email,
      int? last_seen_ts,
      String? name,
      String? surname,
      int records_downloaded,
      int changed_approved_count,
      int changed_denied_count,
      DbTransaction transaction,
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    TrDto trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
        "Insert into User Store", 0, UserStoreMixin.C_TABLE_ID);
    UserStoreTrDto userStoreTrDto = UserStoreTrDto.sep(
        id,
        email,
        last_seen_ts,
        name,
        surname,
        records_downloaded,
        changed_approved_count,
        changed_denied_count,
        trDto);
    return await writeTables(userStoreTrDto, localWardenType,
        remoteWardenType, transaction, smd, smdSys);
  }

  // ----------------------------------------------------------------------------------------------------------------- TOOLS
  static Future<RemoteDto?> writeTables(
      TrDto trDto,
      WardenType localWardenType,
      WardenType remoteWardenType,
      DbTransaction transaction,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    RemoteDto? remoteDto = null;
    AbstractTableTransactions tableTransactions = TableTransactions.sep(trDto);
    await tableTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    AbstractWarden abstractWarden =
        WardenFactory.getAbstractWarden(localWardenType, remoteWardenType);
    await abstractWarden.init(smd, smdSys, transaction);
    abstractWarden.initialize(tableTransactions);
    //try {
    remoteDto = await abstractWarden.write();
    //} on SqlException catch (e) {
    //  if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
    //      e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
    //      e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
    //      e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
    //    fail(e.cause.toString());
    //}
    return remoteDto;
  }
}
