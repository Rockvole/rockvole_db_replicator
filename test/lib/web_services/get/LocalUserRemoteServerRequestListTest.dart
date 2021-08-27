import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class LocalUserRemoteServerRequestListTest extends AbstractRequestTest {
  static final bool C_FRESH_DATABASE = true;
  static final int C_USER_ID = 2;
  static final String C_TASK_DESCRIPTION = "Clean Car";
  static final String C_TASK_ITEM_DESCRIPTION = "Vacuum Carpets";
  static late RestGetAuthenticationUtils restInformationUtils;
  static late List<RemoteDto> remoteDtoList;

  LocalUserRemoteServerRequestListTest(SchemaMetaData smd,
      SchemaMetaData smdSys, ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  Future<DbTransaction> test001_SetUp(
      WardenType localWT,
      WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    localTransaction = await super.test001_SetUp(
        WardenType.USER,
        WardenType.READ_SERVER,
        localDatabaseName: "client_db",
        remoteDatabaseName: "server_db",
        rowLimit: 1);
    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    await remoteTransaction.getConnection().connect();
    return localTransaction;
  }

  Future<void> test005_CloneFromCsv(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test005_CloneFromCsv(
        localTransaction,
        tableTypeEnumSet: null,
        trTableTypeEnumSet: null,
        dropPartitions: true);
  }

  Future<void> test007_CloneFromCsvToRemote(
      DbTransaction transaction,
      {
      Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    majTableTypeEnumSet.add(UserMixin.C_TABLE_ID);
    majTableTypeEnumSet.add(UserStoreMixin.C_TABLE_ID);
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: majTableTypeEnumSet,
        trTableTypeEnumSet: majTrTableTypeEnumSet,
        dropPartitions: true);
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();
    UserDao remoteUserDao = UserDao(smd, remoteTransaction);
    await remoteUserDao.init();
    UserStoreDao remoteUserStoreDao = UserStoreDao(smd, remoteTransaction);
    await remoteUserStoreDao.init();
    try {
      UserDto remoteUserDto = await remoteUserDao.getUserDtoById(C_USER_ID);
      expect(remoteUserDto.warden, WardenType.USER);
      UserStoreDto remoteUserStoreDto =
          await remoteUserStoreDao.getUserStoreDtoById(C_USER_ID);
      await localUserTools.setCurrentUserDto(
          smd, localTransaction, remoteUserDto);
      await localUserTools.setCurrentUserStoreDto(
          smd, localTransaction, remoteUserStoreDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
  }

  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(
        localWardenType, WardenType.NULL, transaction: localTransaction);

    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    try {
      AbstractRequestTest.remoteDto =
          await restInformationUtils.requestAuthenticationFromServer(
              AbstractRequestTest.C_VERSION,
              serverDatabase: AbstractRequestTest.C_REMOTE_DB,
              testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    restGetLatestRowsUtils = RestGetLatestRowsUtils(localWardenType, remoteWardenType, smd, smdSys,
        localTransaction, localUserTools, defaults); // Load current user
    await restGetLatestRowsUtils.init();
  }

  @override
  Future<void> test060_Configuration() async {
    await super.test060_Configuration();
    await super.requestLatestRows(37214895);

    late ConfigurationDto configurationDto;
    try {
      configurationDto = await configurationDao.getConfigurationDtoById(970000);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(configurationDto.configuration_name,
        ConfigurationNameEnum.ROWS_SYNC_INTERVAL_MINS);
  }

  @override
  Future<void> test070_TaskItem() async {
    await super.test070_TaskItem();
    await super.requestLatestRows(56455);

    late TaskItemDto taskItemDto;
    try {
      taskItemDto = await taskItemDao.getTaskItemDtoById(1);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(taskItemDto.item_description, C_TASK_ITEM_DESCRIPTION);
  }

  @override
  Future<void> test120_Task() async {
    await super.test120_Task();
    await super.requestLatestRows(556240);

    late TaskDto taskDto;
    try {
      taskDto = await taskDao.getTaskDtoById(1);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(taskDto.task_description, C_TASK_DESCRIPTION);
  }

  @override
  Future<void> test130_User() async {
    await super.test130_User();
    bool found = true;
    await super.requestLatestRows(114809933);

    try {
      await userDao.getUserDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        found = false;
      else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    if (found) fail(TestHelper_Check.C_ENTRY_SHOULD_NOT_EXIST);
  }

  @override
  Future<void> test140_UserStore() async {
    await super.test140_UserStore();
    bool found = true;
    await super.requestLatestRows(120772103);

    try {
      await userStoreDao.getUserStoreDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        found = false;
      else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    if (found) fail(TestHelper_Check.C_ENTRY_SHOULD_NOT_EXIST);
  }

  Future<void> test170_GetLatestWaterLine() async {
    print(AbstractRequestTest.preamble + "GetLatestWaterLine");
    WaterLineDto waterLineDto = WaterLineDto.sep(117089216,
        WaterState.SERVER_APPROVED, WaterError.NONE, TaskMixin.C_TABLE_ID, smd);
    try {
      await waterLineDao.insertWaterLineDto(waterLineDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
    ClientWarden clientWarden = ClientWarden(WardenType.USER, waterLineDao);
    int latestTs = await clientWarden.getLatestTs();
    expect(latestTs, 117089216);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
