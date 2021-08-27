import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

abstract class AbstractRequestTest {
  static final int C_VERSION = 99;
  static final bool C_FRESH_DATABASE = true;
  static final String C_TEST_PASSWORD = "q1dX4i";
  static final String C_ENTRY_INVALID = "Entry is invalid";
  static final String C_ENTRY_ILLEGAL = "Entry is illegal";
  static final String C_ENTRY_NOT_FOUND = "Entry not found";
  static final String C_ENTRY_ALREADY_EXISTS = "Entry already exists";
  static final String C_ENTRY_SHOULD_EXIST = "Entry should already exist";
  static final String C_ENTRY_SHOULD_NOT_EXIST = "Entry should not exist";
  static final String C_ENTRY_MUST_BE_ILLEGAL_STATE =
      "Must throw an Illegal state exception";
  static final String C_ENTRY_MUST_BE_INVALID_STATE =
      "Must throw an Invalid state exception";
  static final String C_SERVER_NOT_FOUND = "Server not found";
  static final String C_PARTITION_EXCEPTION = "Partition Problem";
  static int C_RECORD_LIMIT = 3;

  static final String C_IMPORT_DIRECTORY_LOCATION = "ancillary/import";
  static String C_LOCAL_DB = "client_db";
  static String C_REMOTE_DB = "server_db";

  late Set<int> minTableTypeEnumSet;
  late Set<int> minTrTableTypeEnumSet;
  late Set<int> majTableTypeEnumSet;
  late Set<int> majTrTableTypeEnumSet;

  static late int userTs;
  late CloneTables localCloneTables;
  late CloneTables remoteCloneTables;
  late DropTables localDropTables;
  late DropTables remoteDropTables;

  late DbTransaction localTransaction;
  late DbTransaction remoteTransaction;
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  ConfigurationNameDefaults defaults;
  static late TableMetaData tableMd;
  late UserTools localUserTools;
  late RestGetLatestRowsUtils restGetLatestRowsUtils;
  late RestPostNewRowUtils restPostNewRowUtils;
  late RestRequestSelectedRowsUtils restRequestSelectedRowsUtils;
  late RestGetLatestWaterLineFieldsUtils restGetLatestWaterLineFieldsUtils;
  late RestPostWaterLineFieldsUtils restPostWaterLineFieldsUtils;

  late ConfigurationDao configurationDao;
  late UserDao userDao;
  late UserStoreDao userStoreDao;
  late WaterLineDao waterLineDao;
  late WaterLineFieldDao waterLineFieldDao;

  late ConfigurationTrDao configurationTrDao;
  late UserTrDao userTrDao;
  late UserStoreTrDao userStoreTrDao;

  late TaskDao taskDao;
  late TaskTrDao taskTrDao;
  late TaskItemDao taskItemDao;
  late TaskItemTrDao taskItemTrDao;

  static late RemoteDto remoteDto;
  static late List<RemoteDto> remoteDtoList;
  late WardenType localWardenType;
  late WardenType remoteWardenType;
  static String preamble =
      "--------------------------------------------------------------------------------------- ";
  AbstractRequestTest(this.smd, this.smdSys, this.defaults);

  Future<DbTransaction> test001_SetUp(WardenType localWT, WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int rowLimit = 3}) async {
    print(preamble + "SetUp");
    if (localDatabaseName != null) C_LOCAL_DB = localDatabaseName;
    if (remoteDatabaseName != null) C_REMOTE_DB = remoteDatabaseName;
    C_RECORD_LIMIT = rowLimit;
    this.smd = smd;
    this.smdSys = smdSys;
    localWardenType = localWT;
    remoteWardenType = remoteWT;
    DbTransaction transaction =
        await DataBaseHelper.getDbTransaction(localDatabaseName);
    await transaction.getConnection().connect();

    localUserTools = UserTools();

    minTableTypeEnumSet = {TaskMixin.C_TABLE_ID, TaskItemMixin.C_TABLE_ID};
    minTrTableTypeEnumSet = {TaskMixin.C_TABLE_ID, TaskItemMixin.C_TABLE_ID};

    majTableTypeEnumSet = minTableTypeEnumSet.toSet();
    majTrTableTypeEnumSet = {
      TaskMixin.C_TABLE_ID,
      TaskItemMixin.C_TABLE_ID,
      ConfigurationMixin.C_TABLE_ID,
      UserMixin.C_TABLE_ID,
      UserStoreMixin.C_TABLE_ID
    };
    return transaction;
  }

  Future<void> test005_CloneFromCsv(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    print(preamble +
        "LOCAL:Clone from csv to ${transaction.connection.dbType}:${transaction.pool.dataBaseName}");

    if (C_FRESH_DATABASE) {
      localDropTables = await dropSomeTables(transaction);
    }
    await initializeTables(C_RECORD_LIMIT, transaction);

    userTs = WaterLineDto.min_id_for_user;
    await TestHelper_Request.cloneByEnumSet(tableTypeEnumSet,
        C_IMPORT_DIRECTORY_LOCATION, transaction, smd, defaults,
        ignoreDuplicates: true);
    await TestHelper_Request.cloneByEnumSet(trTableTypeEnumSet,
        C_IMPORT_DIRECTORY_LOCATION, transaction, smdSys, defaults,
        ignoreDuplicates: true);

    print(preamble + "User Clone from csv");
  }

  Future<void> test007_CloneFromCsvToRemote(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    print(preamble +
        "REMOTE:Clone from csv to ${transaction.connection.dbType}:${transaction.pool.dataBaseName}");

    if (C_FRESH_DATABASE) {
      remoteDropTables = await dropSomeTables(transaction);
    }
    await TestHelper_Request.cloneByEnumSet(tableTypeEnumSet,
        C_IMPORT_DIRECTORY_LOCATION, transaction, smd, defaults,
        ignoreDuplicates: true);
    await TestHelper_Request.cloneByEnumSet(trTableTypeEnumSet,
        C_IMPORT_DIRECTORY_LOCATION, transaction, smdSys, defaults,
        ignoreDuplicates: true);
    await TestHelper_Check.setCurrentUserId(smd, transaction, 1, defaults);
    ConfigurationDao configurationDao =
        ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    await configurationDao.insertDefaultValues();
    print(preamble + "User Clone from csv to remote");
  }

  Future<void> configureRestUtils() async {
    localUserTools = UserTools();
    restGetLatestRowsUtils = RestGetLatestRowsUtils(
        WardenType.ADMIN,
        WardenType.WRITE_SERVER,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults); // Load current user
    await restGetLatestRowsUtils.init();
    try {
      restPostNewRowUtils = RestPostNewRowUtils(
          localWardenType,
          remoteWardenType,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restPostNewRowUtils.init();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) print("$e");
    }
  }

  Future<void> updateConfigurationUrls(
      WardenType configurationWardenType, DbTransaction transaction) async {
    try {
      await DataBaseFunctions.updateConfigurationByTransaction(
          configurationWardenType,
          ConfigurationNameEnum.WEB_URL,
          0,
          null,
          "localhost",
          false,
          smd,
          smdSys,
          transaction,
          defaults);
      await configureRestUtils();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
    }
  }

  Future<DropTables> dropSomeTables(DbTransaction transaction) async {
    // Drop tables
    DropTables dropTables = DropTables(transaction);
    await dropTables.dropSome(true, smd);
    await dropTables.dropTrSome(true, smdSys);
    return dropTables;
  }

  Future<void> initializeTables(int rowLimit, DbTransaction transaction) async {
    userDao = UserDao(smd, transaction);
    await userDao.init(initTable: true);
    userTrDao = UserTrDao(smdSys, transaction);
    await userTrDao.init(initTable: true);

    userStoreDao = UserStoreDao(smd, transaction);
    await userStoreDao.init(initTable: true);
    userStoreTrDao = UserStoreTrDao(smdSys, transaction);
    await userStoreTrDao.init(initTable: true);

    waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init(initTable: true);
    waterLineFieldDao = WaterLineFieldDao.sep(smdSys, transaction);
    await waterLineFieldDao.init();

    // Configure to retrieve 1 item at a time
    configurationDao = ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    await configurationDao.insertDefaultValues();
    configurationTrDao = ConfigurationTrDao(smdSys, transaction, defaults);
    await configurationTrDao.init(initTable: true);
    try {
      ConfigurationDto configurationDto = ConfigurationDto.sep(
          null,
          0,
          WardenType.USER,
          ConfigurationNameEnum.ROWS_LIMIT,
          0,
          rowLimit,
          null,
          defaults);
      await configurationDao.setConfigurationDto(configurationDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
    // User Tables
    taskDao = TaskDao(smd, transaction);
    await taskDao.init(initTable: true);

    taskTrDao = TaskTrDao(smdSys, transaction);
    await taskTrDao.init(initTable: true);

    taskItemDao = TaskItemDao(smd, transaction);
    await taskItemDao.init(initTable: true);

    taskItemTrDao = TaskItemTrDao(smdSys, transaction);
    await taskItemTrDao.init(initTable: true);
  }

  Future<int> requestPendingAdmin(String tableName, {int? limit}) async {
    print(preamble + "Request Pending Admin " + tableName);
    try {
      remoteDtoList =
          await restGetLatestRowsUtils.requestRemoteDtoListFromServer(
              waterLineTs: 0,
              serverDatabase: C_REMOTE_DB,
              testPassword: C_TEST_PASSWORD,
              limit: limit);
      await restGetLatestRowsUtils.storeRemoteDtoList(remoteDtoList);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    return remoteDtoList[0].waterLineDto!.water_ts!;
  }

  Future<int?> requestLatestRows(int? waterLineTs) async {
    print(preamble + "Request Latest Rows");
    try {
      remoteDtoList =
          await restGetLatestRowsUtils.requestRemoteDtoListFromServer(
              waterLineTs: waterLineTs,
              serverDatabase: C_REMOTE_DB,
              testPassword: C_TEST_PASSWORD,
              compact: false);
      await restGetLatestRowsUtils.storeRemoteDtoList(remoteDtoList);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    return remoteDtoList[0].waterLineDto!.water_ts;
  }

  Future<void> postNewRows(DbTransaction transaction) async {
    print(preamble + "Post New Rows");
    late List<WaterLineDto> waterLineList;
    WaterLineDao wlDao = WaterLineDao.sep(smdSys, transaction);
    await wlDao.init();
    ClientWarden clientWarden = ClientWarden(WardenType.ADMIN, wlDao);
    try {
      waterLineList = await clientWarden.getWaterLineListToSend();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print("WS $e");
    }
    WaterLineDto waterLineDto;
    RemoteDto remoteDto;
    Iterator<WaterLineDto> iter = waterLineList.iterator;
    while (iter.moveNext()) {
      waterLineDto = iter.current;
      try {
        remoteDto = await RemoteDtoFactory.getRemoteDtoFromWaterLineDto(
            waterLineDto, localWardenType, smdSys, transaction, false);
        await restPostNewRowUtils.sendRemoteDtoToServer(remoteDto, C_VERSION,
            serverDatabase: C_REMOTE_DB, testPassword: C_TEST_PASSWORD);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
          fail(e.cause!);
      }
    }
  }

  Future<void> postOneRow(DbTransaction transaction) async {
    late WaterLineDto waterLineDto;
    WaterLineDao wlDao = WaterLineDao.sep(smdSys, transaction);
    await wlDao.init();
    ClientWarden clientWarden = ClientWarden(WardenType.ADMIN, wlDao);
    try {
      waterLineDto = await clientWarden.getNextWaterLineToSend();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print("WS $e");
    }
    try {
      RemoteDto remoteDto = await RemoteDtoFactory.getRemoteDtoFromWaterLineDto(
          waterLineDto, localWardenType, smdSys, transaction, false);
      print("Posting=$remoteDto");
      await restPostNewRowUtils.sendRemoteDtoToServer(remoteDto, C_VERSION,
          serverDatabase: C_REMOTE_DB, testPassword: C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
        fail(e.cause!);
    }
  }

  void confirm() {
    print(preamble + "Now Confirm");
  }

  Future<void> test010_InsertCurrentUser() async {
    print(preamble + "Insert Current User");
  }

  Future<void> test015_UpdateConfiguration(
      WardenType localWT, WardenType remoteWT,
      {DbTransaction? transaction}) async {
    print(preamble + "Update Configuration");
    await updateConfigurationUrls(localWT, transaction!);
  }

  Future<void> test017_InsertUnbalancedUser() async {
    print(preamble + "Insert Unbalanced User");
  }

  Future<void> test020_GetNewUser() async {
    print(preamble + "Get New User");
  }

  Future<void> test025_UpdateUserSurname() async {
    print(preamble + "Update User Surname");
  }

  Future<void> test030_GetMissingUserId() async {
    print(preamble + "Get Missing User Id");
  }

  Future<void> test035_PostUserChange() async {
    print(preamble + "Post User Change");
  }

  Future<void> test040_UserWrongPasskey() async {
    print(preamble + "Authenticate User Wrong Passkey");
  }

  Future<void> test050_InsertUser() async {
    print(preamble + "Insert User");
  }

  Future<void> test055_Authenticate_UpgradeUser() async {
    print(preamble + "Authenticate and Upgrade User to Admin");
  }

  Future<void> test060_Configuration() async {
    print(preamble + "Configuration");
  }

  Future<void> test065_Authenticate_Pending() async {
    print(preamble + "Authenticate With Pending Record");
  }

  Future<void> test070_TaskItem() async {
    print(preamble + "Task Item");
  }

  Future<void> test080_Authenticate_WithRemotePassKeyNoLocal() async {
    print(preamble + "Authenticate With Remote PassKey + No Local PassKey");
  }

  Future<void> test090_Authenticate_NoRemotePassKeyNoLocal() async {
    print(preamble + "Authenticate No Remote PassKey + No Local PassKey");
  }

  Future<void> test100_Authenticate_NoRemotePassKeyWithLocal() async {
    print(preamble + "Authenticate No Remote PassKey + With Local PassKey");
  }

  Future<void> test110_Authenticate_WithAllPassKeys() async {
    print(preamble + "Authenticate With All PassKeys");
  }

  Future<void> test120_Task() async {
    print(preamble + "Task");
  }

  Future<void> test125_InsertUser() async {
    print(preamble + "Insert User");
  }

  Future<void> test130_User() async {
    print(preamble + "User");
  }

  Future<void> test135_Authenticate_CrcNotMatch() async {
    print(preamble + "Authenticate With Crc Not Matching");
  }

  Future<void> test140_UserStore() async {
    print(preamble + "User Store");
  }

  Future<void> test160_UserStore_Other() async {
    print(preamble + "User Store Other");
  }

  Future<void> test150_Check_WaterLineFieldEmpty() async {
    print(preamble + "Check Water Line Field Empty");
  }

  Future<void> test170_GetLatestWaterLine() async {
    print(preamble + "Get Latest Water Line");
  }

  Future<void> test999_Finish() async {
    print(preamble + "Finish");
    await localTransaction.getConnection().close();
    await remoteTransaction.getConnection().close();
  }
}
