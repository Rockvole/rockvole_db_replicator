import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class LocalServerRemoteServerRequestTest extends AbstractRequestTest {
  static final bool C_FRESH_DATABASE = true;
  static final int C_USER_ID = 11;
  static final WaterState C_STATE_TYPE = WaterState.SERVER_APPROVED;

  LocalServerRemoteServerRequestTest(SchemaMetaData smd, SchemaMetaData smdSys,
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
        WardenType.READ_SERVER,
        WardenType.WRITE_SERVER,
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
      expect(remoteUserDto.warden, WardenType.READ_SERVER);
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
    await super.requestLatestRows(13000500);

    late ConfigurationTrDto configurationTrDto;
    try {
      FieldData fieldData = ConfigurationTrDto.getSelectFieldData();
      RawRowData rawRowData = await configurationTrDao
          .getRawRowDataByTs(13000501, fieldData: fieldData);
      configurationTrDto =
          ConfigurationTrDto.field(rawRowData.getFieldData(), defaults);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(configurationTrDto.configuration_name,
        ConfigurationNameEnum.ROWS_NEXT_SYNC_CHANGES_TS);
  }

  @override
  Future<void> test070_TaskItem() async {
    await super.test070_TaskItem();
    await super.requestLatestRows(32850563);

    late TaskItemTrDto taskItemTrDto;
    try {
      taskItemTrDto = await taskItemTrDao.getTaskItemTrDtoByTs(32850564);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(taskItemTrDto.item_description, "Mow Lawn");
  }

  @override
  Future<void> test120_Task() async {
    await super.test120_Task();
    await super.requestLatestRows(32287602);

    late TaskTrDto taskTrDto;
    try {
      taskTrDto = await taskTrDao.getTaskTrDtoByTs(32287603);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(taskTrDto.task_description, "Shopping");
  }

  @override
  Future<void> test130_User() async {
    await super.test130_User();
    await super.requestLatestRows(114809933);

    late UserDto userDto;
    try {
      userDto = await userDao.getUserDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(userDto.pass_key, "hd67ma");

    late UserTrDto userTrDto;
    FieldData fieldData = UserDto.getSelectFieldData();
    try {
      RawRowData rawRowData =
          await userTrDao.getRawRowDataByTs(114809935, fieldData: fieldData);
      userTrDto = UserTrDto.field(rawRowData.getFieldData());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(userTrDto.pass_key, "hd67ma");
  }

  @override
  Future<void> test140_UserStore() async {
    await super.test140_UserStore();
    await super.requestLatestRows(120772103);

    late UserStoreDto userStoreDto;
    try {
      userStoreDto = await userStoreDao.getUserStoreDtoById(5);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(userStoreDto.name, "Hilary");

    late UserStoreTrDto userStoreTrDto;
    FieldData fieldData = UserStoreDto.getSelectFieldData();
    try {
      RawRowData rawRowData = await userStoreTrDao.getRawRowDataByTs(120772104,
          fieldData: fieldData);
      userStoreTrDto = UserStoreTrDto.field(rawRowData.getFieldData());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    expect(userStoreTrDto.name, "Hilary");
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
