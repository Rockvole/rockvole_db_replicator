import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class LocalUserRemoteServerRequestTest extends AbstractRequestTest {
  static final bool C_FRESH_DATABASE = true;
  static final int C_USER_ID = 2;
  static final WaterState C_STATE_TYPE = WaterState.SERVER_APPROVED;

  LocalUserRemoteServerRequestTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
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
    return remoteTransaction;
  }

  @override
  Future<void> test005_CloneFromCsv(
      DbTransaction? transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test005_CloneFromCsv(
        localTransaction,
        tableTypeEnumSet: null,
        trTableTypeEnumSet: null,
        dropPartitions: false);
  }

  @override
  Future<void> test007_CloneFromCsvToRemote(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    majTableTypeEnumSet.add(UserMixin.C_TABLE_ID);
    majTableTypeEnumSet.add(UserStoreMixin.C_TABLE_ID);
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: majTableTypeEnumSet,
        trTableTypeEnumSet: majTrTableTypeEnumSet);
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
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
  }

  @override
  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(
        localWardenType, WardenType.NULL, transaction: localTransaction);

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
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(configurationDto.value_number, 666);
  }

  @override
  Future<void> test070_TaskItem() async {
    await super.test070_TaskItem();
    await super.requestLatestRows(673244);

    late TaskItemDto taskItemDto;
    try {
      taskItemDto = await taskItemDao.getTaskItemDtoById(3);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(taskItemDto.item_description, "Polish Paint");
  }

  @override
  Future<void> test120_Task() async {
    await super.test120_Task();
    await super.requestLatestRows(564645);

    late TaskDto taskDto;
    try {
      taskDto = await taskDao.getTaskDtoById(1);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(taskDto.task_description, "Clean Car");
  }

  @override
  Future<void> test130_User() async {
    await super.test130_User();
    bool found = true;
    await super.requestLatestRows(114809933);

    try {
      await userDao.getUserDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) found = false;
    }
    if (found) fail(AbstractRequestTest.C_ENTRY_SHOULD_NOT_EXIST);
    found = true;

    FieldData fieldData = UserDto.getSelectFieldData();
    try {
      await userTrDao.getRawRowDataByTs(114809934, fieldData: fieldData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) found = false;
    }
    if (found) fail(AbstractRequestTest.C_ENTRY_SHOULD_NOT_EXIST);
  }

  @override
  Future<void> test140_UserStore() async {
    await super.test140_UserStore();
    bool found = true;
    await super.requestLatestRows(120772103);

    try {
      await userStoreDao.getUserStoreDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) found = false;
    }
    if (found) fail(AbstractRequestTest.C_ENTRY_SHOULD_NOT_EXIST);
    found = true;

    FieldData fieldData = UserStoreDto.getSelectFieldData();
    try {
      RawRowData rawRowData = await userStoreTrDao.getRawRowDataByTs(120772104,
          fieldData: fieldData);
      UserStoreTrDto.field(rawRowData.getFieldData());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) found = false;
    }
    if (found) fail(AbstractRequestTest.C_ENTRY_SHOULD_NOT_EXIST);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
