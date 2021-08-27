import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class LocalServerRemoteServerRequestListTest extends AbstractRequestTest {
  static final bool C_FRESH_DATABASE = true;
  static final int C_USER_ID = 11;
  static final int C_TASK_ID = 1;
  static final String C_TASK_DESCRIPTION = "Clean Car";
  static final String C_TASK_ITEM_DESCRIPTION = "Vacuum Carpets";
  static final WaterState C_STATE_TYPE = WaterState.SERVER_APPROVED;
  static late List<RemoteDto> remoteDtoList;

  LocalServerRemoteServerRequestListTest(SchemaMetaData smd,
      SchemaMetaData smdSys, ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

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
        );
    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    await remoteTransaction.getConnection().connect();
    return localTransaction;
  }

  Future<void> test005_CloneFromCsv(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test005_CloneFromCsv(localTransaction,
        tableTypeEnumSet: null,
        trTableTypeEnumSet: null,
        dropPartitions: false);
  }

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
        trTableTypeEnumSet: majTrTableTypeEnumSet,
        dropPartitions: false);
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
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
  }

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
    await super.requestLatestRows(35861407);

    super.confirm();
    String? configString;
    try {
      configString = await configurationDao.getString(
          0, WardenType.READ_SERVER, ConfigurationNameEnum.WEB_URL);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(configString, "localhost");

    late ConfigurationTrDto configurationTrDto;
    try {
      configurationTrDto =
          await configurationTrDao.getConfigurationTrDtoByTs(35861408);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(configurationTrDto.value_string, "http://chutney");
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
    expect(C_TASK_ITEM_DESCRIPTION, taskItemDto.item_description);

    late TaskItemTrDto taskItemTrDto;
    try {
      taskItemTrDto = await taskItemTrDao.getTaskItemTrDtoByTs(67474);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(taskItemTrDto.item_description, C_TASK_ITEM_DESCRIPTION);
  }

  @override
  Future<void> test120_Task() async {
    await super.test120_Task();
    await super.requestLatestRows(556240);

    late TaskDto taskDto;
    try {
      taskDto = await taskDao.getTaskDtoById(C_TASK_ID);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(taskDto.task_description, C_TASK_DESCRIPTION);

    late TaskTrDto taskTrDto;
    try {
      taskTrDto = await taskTrDao.getTaskTrDtoByTs(564646);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(taskTrDto.task_description, C_TASK_DESCRIPTION);
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
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(userDto.pass_key, "hd67ma");

    late UserTrDto userTrDto;
    try {
      userTrDto = await userTrDao.getUserTrDtoByTs(114809935);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
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
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(userStoreDto.name, "Hilary");

    late UserStoreTrDto userStoreTrDto;
    try {
      userStoreTrDto = await userStoreTrDao.getUserStoreTrDtoByTs(120772104);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    expect(userStoreTrDto.name, "Hilary");
  }

  Future<void> test150_Check_WaterLineFieldEmpty() async {
    await super.test150_Check_WaterLineFieldEmpty();
    await TestHelper_Check.ensureWaterLineFieldNotAdded(
        107,
        TaskItemMixin.C_TABLE_ID,
        ChangeType.NOTIFY,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
