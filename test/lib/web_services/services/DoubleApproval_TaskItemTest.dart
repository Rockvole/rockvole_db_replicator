import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class DoubleApproval_TaskItemTest extends AbstractPermissionRequestTest {
  static final int C_TABLE_TYPE = TaskItemMixin.C_TABLE_ID;
  static final String C_TABLE_FULL_NAME = "TaskItem";
  static final int C_TASK_ITEM_ID = 38;
  static final String C_TASK_ITEM_DESCRIPTION = "Push-Ups";
  static final bool C_TASK_ITEM_COMPLETE = false;
  static final int C_TASK_ID = 3;
  static TaskItemDto? taskItemDto;
  static TaskItemTrDto? taskItemTrDto;
  static int localTsAdmin1 = 0;
  static int localTsAdmin2 = 0;

  DoubleApproval_TaskItemTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  Future<DbTransaction> test001_SetUp(WardenType localWT, WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    return await super.test001_SetUp(WardenType.USER, WardenType.USER,
        localDatabaseName: "client_db", remoteDatabaseName: "server_db");
  }

  Future<void> test005_CloneFromCsv(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTableTypeEnumSet.add(TaskMixin.C_TABLE_ID);
    await super.test005_CloneFromCsv(localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  Future<void> test007_CloneFromCsvToRemote(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test007_CloneFromCsvToRemote(remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet, dropPartitions: false);
  }

  @override
  Future<void> test010_InsertCurrentUser() {
    return super.test010_InsertCurrentUser();
  }

  Future<void> test015_UpdateConfiguration(
      WardenType localWT, WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(localWardenType, WardenType.NULL,
        transaction: localTransaction);

    try {
      /*
      // This is initialised in AbstractRequestTest.configureRestUtils()
      // Called from test015_UpdateConfiguration()
      restPostNewRowUtils = RestPostNewRowUtils(
          localWardenType,
          remoteWardenType,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restPostNewRowUtils.init();
       */
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.cause!);
    }
  }

  @override
  Future<void> test047_User_Create_TaskItem() async {
    await super.test047_User_Create_TaskItem();

    TrDto trDto = TrDto.sep(null, OperationType.INSERT, 33, null,
        "Insert Task Item Approval", 0, TaskItemMixin.C_TABLE_ID);
    taskItemTrDto = TaskItemTrDto.sep(
        null, C_TASK_ID, C_TASK_ITEM_DESCRIPTION, C_TASK_ITEM_COMPLETE, trDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(taskItemTrDto!);
    await tableTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, localTransaction);
    await AbstractPermissionRequestTest.userWarden
        .init(smd, smdSys, localTransaction);
    AbstractPermissionRequestTest.userWarden.initialize(tableTransactions);
    try {
      await AbstractPermissionRequestTest.userWarden.write();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
        fail(e.cause!);
    }
    TaskItemDto? taskItemDto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskItemStruct =
        TestTaskItemDataStruct(idSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskItemStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.USER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
  }

  Future<void> test067_User_Post_TaskItem() async {
    await super.test067_User_Post_TaskItem();
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: AbstractRequestTest.userTs,
        water_table_id: C_TABLE_TYPE,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    taskItemDto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskStruct =
        TestTaskItemDataStruct(idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.id, C_TASK_ITEM_ID);
    expect(taskItemTrDto!.task_id, C_TASK_ID);

    // Test Remote DB
    taskItemDto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
    TestTaskItemDataStruct taskItemRemoteStruct =
        TestTaskItemDataStruct(idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskItemRemoteStruct);
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            C_TABLE_TYPE, null, null, true, smdSys, remoteTransaction);
    TaskItemTrDto? trDto = await TestHelper_Fetch.fetchTaskItemTr(
        remoteWaterLineDto!.water_ts!, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(trDto, trRemoteStruct);
  }

  // -------------------------------------------------------------------------------------------------------- ADMIN1 RECEIVE
  Future<void> test097_Admin1() async {
    await super.test097_Admin1();
    // Close "post"
    await localTransaction.endTransaction();
    await localTransaction.closePool();

    localTransaction = await DataBaseHelper.getDbTransaction("admin1");
    await dropSomeTables(localTransaction);
  }

  Future<void> test107_UpdateConfiguration_Admin1() async {
    await super.test107_UpdateConfiguration_Admin1();
    localWardenType = WardenType.ADMIN;
    remoteWardenType = WardenType.WRITE_SERVER;
    await updateConfigurationUrls(localWardenType, localTransaction);

    restGetLatestRowsUtils = RestGetLatestRowsUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults); // Load current user
  }

  Future<void> test115_Insert_Current_Admin1() async {
    await super.test115_Insert_Current_Admin1();
    await super.test110_InsertCurrentAdmin();
  }

  Future<void> test117_Get_Pending_Admin1() async {
    await super.requestPendingAdmin("Task Item");
    localTsAdmin1 =
        AbstractRequestTest.remoteDtoList[0].waterLineDto!.water_ts!;
  }

  // -------------------------------------------------------------------------------------------------------- ADMIN2 RECEIVE
  Future<void> test197_Admin2() async {
    await super.test197_Admin2();
    // Close "post"
    await localTransaction.endTransaction();
    await localTransaction.closePool();

    localTransaction = await DataBaseHelper.getDbTransaction("admin2");
    print("----------------- lt=" + localTransaction.toString());
    await dropSomeTables(localTransaction);
  }

  Future<void> test207_UpdateConfiguration_Admin2() async {
    await updateConfigurationUrls(localWardenType, localTransaction);

    restGetLatestRowsUtils = RestGetLatestRowsUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults); // Load current user
  }

  Future<void> test215_InsertCurrentAdmin2() async {
    await super.test215_InsertCurrentAdmin2();
    final int C_ADMIN_ID2 = 5;
    UserDto userDto =
        UserDto.sep(C_ADMIN_ID2, "z3Eq0i", 0, WardenType.ADMIN, 0, 30616256);
    UserStoreDto userStoreDto = UserStoreDto.sep(
        C_ADMIN_ID2, "miley@cyrus.com", 3265478, "Miley", "Cyrus", 0, 0, 0);
    await super.test110_InsertCurrentAdmin(
        userDto: userDto, userStoreDto: userStoreDto);
  }

  Future<void> test217_Get_Pending_Admin2() async {
    await super.requestPendingAdmin("TaskItem");
    localTsAdmin2 =
        AbstractRequestTest.remoteDtoList[0].waterLineDto!.water_ts!;
  }
  // -------------------------------------------------------------------------------------------------------- ADMIN2 APPROVE

  Future<void> test297_Wait() async {
    await super.test210_Wait();
  }

  Future<void> test317_Approve_Admin2() async {
    await TestHelper_Request.approveByAdmin(
        localTsAdmin2, false, smdSys, localTransaction);
  }

  Future<void> test330_Post_Approval_Admin2() async {
    await super.test330_Post_Approval_Admin2();
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        localTsAdmin2, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: localTsAdmin2,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(dto, taskStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        localTsAdmin2, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.task_id, C_TASK_ID);
    expect(taskItemTrDto!.item_description, C_TASK_ITEM_DESCRIPTION);

    // Test Remote DB
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            TaskItemMixin.C_TABLE_ID,
            WaterState.SERVER_APPROVED,
            null,
            true,
            smdSys,
            remoteTransaction);
    AbstractPermissionRequestTest.remoteTs = remoteWaterLineDto!.water_ts!;
    waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestWaterLineDataStruct waterRemoteStruct = TestWaterLineDataStruct(
        water_ts: AbstractPermissionRequestTest.remoteTs,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.SERVER_APPROVED,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterRemoteStruct);

    dto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
    TestTaskItemDataStruct taskItemStruct =
        TestTaskItemDataStruct(idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskItemStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trRemoteStruct);
  }

  // -------------------------------------------------------------------------------------------------------- ADMIN1 APPROVE
  Future<void> test400_Wait_Admin1() async {
    await super.test210_Wait();
    await super.test400_Wait_Admin1();

    // Close "post"
    await localTransaction.endTransaction();
    await localTransaction.closePool();

    localTransaction = await DataBaseHelper.getDbTransaction("admin1");
    await configureRestUtils();
  }

  Future<void> test420_Approve_Admin1() async {
    await TestHelper_Request.approveByAdmin(
        localTsAdmin1, false, smdSys, localTransaction);
  }

  Future<void> test430_Post_Approval_Admin1() async {
    await super.test430_Post_Approval_Admin1();
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        localTsAdmin1, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: localTsAdmin1,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    TaskItemDto? taskItemDto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID, idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        localTsAdmin1, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.task_id, C_TASK_ID);
    expect(taskItemTrDto!.item_description, C_TASK_ITEM_DESCRIPTION);

    // Test Remote DB
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            TaskItemMixin.C_TABLE_ID,
            WaterState.SERVER_APPROVED,
            WaterError.NONE,
            true,
            smdSys,
            remoteTransaction);
    AbstractPermissionRequestTest.remoteTs = remoteWaterLineDto!.water_ts!;
    waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestWaterLineDataStruct waterRemoteStruct = TestWaterLineDataStruct(
        water_ts: AbstractPermissionRequestTest.remoteTs,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.SERVER_APPROVED,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterRemoteStruct);

    taskItemDto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
    TestTaskItemDataStruct taskItemStruct =
        TestTaskItemDataStruct(idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(taskItemDto, taskItemStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trRemoteStruct);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
