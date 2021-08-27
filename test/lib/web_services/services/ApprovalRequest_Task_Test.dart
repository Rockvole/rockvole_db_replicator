import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class ApprovalRequest_Task_Test extends AbstractPermissionRequestTest {
  static final int C_TASK_ID = 11;
  static final String C_TASK_DESCRIPTION = "Exercise";
  static final String C_TASK_ITEM_DESCRIPTION = "Push-Ups";
  static final bool C_TASK_COMPLETE = false;
  static final bool C_TASK_ITEM_COMPLETE = false;
  static final int C_TABLE_TYPE = TaskMixin.C_TABLE_ID;
  static final String C_TABLE_FULL_NAME = "Task";
  static final int C_FOOD_CATEGORY_ID = 10;
  static final int C_SERVER_TASK_ID = 11;
  static final String C_SERVER_TASK_DESCRIPTION = "Exercise";
  static final bool C_SERVER_TASK_COMPLETE = true;
  static final int C_USER_TASK_ID = 2000000000;
  static final int C_USER_TASK_ITEM_ID = 2000000000;
  static final int C_TASK_ITEM_ID = 38;
  static late int C_TASK_ITEM_TABLE_FIELD_ID;
  static TaskDto? taskDto;
  static TaskTrDto? taskTrDto;
  static late TaskItemDto taskItemDto;
  static TaskItemTrDto? taskItemTrDto;
  static int localTaskTs = 0;
  static int localTaskItemTs = 0;

  ApprovalRequest_Task_Test(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
  Future<DbTransaction> test001_SetUp(
      WardenType? localWT,
      WardenType? remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    C_TASK_ITEM_TABLE_FIELD_ID = smd
        .getField(TaskItemMixin.C_TABLE_ID, 'item_description')
        .table_field_id;
    return await super.test001_SetUp(
        WardenType.USER,
        WardenType.USER,
        localDatabaseName: "client_db",
        remoteDatabaseName: "server_db"
        );
  }

  @override
  Future<void> test005_CloneFromCsv(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test005_CloneFromCsv(
        localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: true);
  }

  @override
  Future<void> test007_CloneFromCsvToRemote(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTrTableTypeEnumSet.add(WaterLineFieldDto.C_TABLE_ID);
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test010_InsertCurrentUser() {
    return super.test010_InsertCurrentUser();
  }

  @override
  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(
        WardenType.ADMIN,
        WardenType.WRITE_SERVER,
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
      restRequestSelectedRowsUtils = RestRequestSelectedRowsUtils(
          WardenType.ADMIN,
          WardenType.WRITE_SERVER,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restRequestSelectedRowsUtils.init();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail(e.cause!);
    }
  }

  Future<void> test049_User_Create_Task() async {
    await super.test049_User_Create_Task();
    await TaskCrudHelper.insertTask(C_TASK_DESCRIPTION, C_TASK_COMPLETE,
        localTransaction, localWardenType, remoteWardenType, smd, smdSys);

    TaskDto? taskDto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, localTransaction);
    TestTaskDataStruct taskStruct = TestTaskDataStruct(
        id: C_USER_TASK_ID,
        task_description: C_TASK_DESCRIPTION,
        task_complete: C_TASK_COMPLETE,
        idSpace: IdentSpace.USER_SPACE,
        ensureExists: true);
    TestHelper_Check.checkTask(taskDto, taskStruct);
    taskTrDto = await TestHelper_Fetch.fetchTaskTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.USER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        ensureExists: true,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskTrDto, trStruct);
  }

  Future<void> test059_User_Post_Task() async {
    await super.test059_User_Post_Task();
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: AbstractRequestTest.userTs,
        water_table_id: C_TABLE_TYPE,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    taskDto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, localTransaction);
    TestTaskDataStruct taskStruct = TestTaskDataStruct(
        id: C_SERVER_TASK_ID,
        task_description: C_SERVER_TASK_DESCRIPTION,
        task_complete: false,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true);
    TestHelper_Check.checkTask(taskDto, taskStruct);
    taskTrDto = await TestHelper_Fetch.fetchTaskTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        ensureExists: true,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskTrDto, trStruct);
    expect(taskTrDto!.task_description, C_TASK_DESCRIPTION);

    // Test Remote DB
    taskDto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, remoteTransaction);
    TestTaskDataStruct taskRemoteStruct = TestTaskDataStruct(
        id: C_SERVER_TASK_ID,
        task_description: C_SERVER_TASK_DESCRIPTION,
        task_complete: false,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true);
    TestHelper_Check.checkTask(taskDto, taskRemoteStruct);
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            C_TABLE_TYPE, null, null, true, smdSys, remoteTransaction);
    TaskTrDto? trDto = await TestHelper_Fetch.fetchTaskTr(
        remoteWaterLineDto!.water_ts!, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(trDto, trRemoteStruct);
  }

  Future<void> test069_User_Create_TaskItem() async {
    await super.test069_User_Create_TaskItem();

    await TaskCrudHelper.insertTaskItem(
        C_TASK_ID,
        C_TASK_ITEM_DESCRIPTION,
        C_TASK_ITEM_COMPLETE,
        localTransaction,
        localWardenType,
        remoteWardenType,
        smd,
        smdSys);

    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_SERVER_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct struct = TestTaskItemDataStruct(
        id: C_USER_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkTaskItem(dto, struct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs + 1, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.USER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
  }

  Future<void> test079_User_Post_TaskItem() async {
    await super.test079_User_Post_TaskItem();
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractRequestTest.userTs + 1, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: AbstractRequestTest.userTs + 1,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);
    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_SERVER_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(dto, taskStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs + 1, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.item_description, C_TASK_ITEM_DESCRIPTION);

    // Test Remote DB
    dto = await TestHelper_Fetch.fetchTaskItem(
        C_SERVER_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
    TestTaskItemDataStruct taskItemStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(dto, taskItemStruct);
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            TaskItemMixin.C_TABLE_ID,
            null,
            null,
            true,
            smdSys,
            remoteTransaction);
    int waterLineTs = remoteWaterLineDto!.water_ts!;
    TaskItemTrDto? trDto = await TestHelper_Fetch.fetchTaskItemTr(
        waterLineTs, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(trDto, trRemoteStruct);
    waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        waterLineTs, smdSys, remoteTransaction);
    TestWaterLineDataStruct waterRemoteStruct = TestWaterLineDataStruct(
        water_ts: waterLineTs,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.SERVER_PENDING,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterRemoteStruct);
  }

  // Convert local user to admin so we can approve this
  Future<void> test110_InsertCurrentAdmin(
      {UserDto? userDto, UserStoreDto? userStoreDto}) {
    return super.test110_InsertCurrentAdmin();
  }

  Future<void> test118_RemoveLocalUserEntries() async {
    await super.test118_RemoveLocalUserEntries();
    try {
      await taskDao.deleteTaskByUnique(C_TASK_ID);
      await taskTrDao.deleteTrRowByTs(AbstractRequestTest.userTs);
      await waterLineDao.deleteWaterLineByTs(AbstractRequestTest.userTs);

      await taskItemDao.deleteTaskItemByUnique(C_SERVER_TASK_ID);
      await taskItemTrDao.deleteTrRowByTs(AbstractRequestTest.userTs + 1);
      await waterLineDao.deleteWaterLineByTs(AbstractRequestTest.userTs + 1);

      await waterLineDao.deleteWaterLineByTs(AbstractRequestTest.userTs + 2);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
        print("$e");
    }
  }

  Future<void> test200_Get_Pending_Admin() async {
    await super.requestPendingAdmin(C_TABLE_FULL_NAME, limit: 49);
    List<RemoteDto> pendingRemoteDtoList=[];
    AbstractRequestTest.remoteDtoList.forEach((RemoteDto rDto) {
      if(rDto.waterLineDto!.water_state==WaterState.SERVER_PENDING) pendingRemoteDtoList.add(rDto);
    });
    localTaskTs = pendingRemoteDtoList[0].waterLineDto!.water_ts!;
    localTaskItemTs =
        pendingRemoteDtoList[1].waterLineDto!.water_ts!;
  }

  @override
  Future<void> test210_Wait() async {
    await super.test210_Wait();
  }

  Future<void> test220_Approve_Task() async {
    await TestHelper_Request.approveByAdmin(
        localTaskTs, false, smdSys, localTransaction);
  }

  Future<void> Admin_Post_AppRej_Task(
      WaterState waterState, bool isPresent) async {
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        localTaskTs, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: localTaskTs,
        water_table_id: TaskMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        water_error: WaterError.NONE,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    TaskDto? dto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, localTransaction);
    TestTaskDataStruct taskStruct = TestTaskDataStruct(
        id: C_SERVER_TASK_ID,
        task_description: C_SERVER_TASK_DESCRIPTION,
        task_complete: false,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: isPresent);
    TestHelper_Check.checkTask(dto, taskStruct);
    taskTrDto = await TestHelper_Fetch.fetchTaskTr(
        localTaskTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskTrDto, trStruct);
    expect(taskTrDto!.id, C_SERVER_TASK_ID);
    expect(taskTrDto!.task_description, C_TASK_DESCRIPTION);

    // Test Remote DB
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            C_TABLE_TYPE, waterState, null, true, smdSys, remoteTransaction);
    AbstractPermissionRequestTest.remoteTs = remoteWaterLineDto!.water_ts!;
    waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestWaterLineDataStruct waterRemoteStruct = TestWaterLineDataStruct(
        water_ts: AbstractPermissionRequestTest.remoteTs,
        water_table_id: TaskMixin.C_TABLE_ID,
        water_state: waterState,
        water_error: WaterError.NONE,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterRemoteStruct);

    dto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, remoteTransaction);
    TestTaskDataStruct taskRemoteStruct = TestTaskDataStruct(
        id: C_SERVER_TASK_ID,
        task_description: C_SERVER_TASK_DESCRIPTION,
        task_complete: C_TASK_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: isPresent);
    TestHelper_Check.checkTask(dto, taskRemoteStruct);
    TaskTrDto? trDto = await TestHelper_Fetch.fetchTaskTr(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(trDto, trRemoteStruct);
  }

  Future<void> test300_Admin_Post_Approved_Task() async {
    await super.test300_Admin_Post_Approved_Task();
    await Admin_Post_AppRej_Task(WaterState.SERVER_APPROVED, true);
  }

  Future<void> test310_Approve_TaskItem() async {
    await super.test310_Approve_TaskItem();
    await TestHelper_Request.approveByAdmin(
        localTaskItemTs, false, smdSys, localTransaction);
  }

  Future<void> Admin_Post_AppRej_TaskItem(
      WaterState waterState, bool isPresent) async {
    try {
      await super.postOneRow(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    WaterLineDto waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        localTaskItemTs, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: localTaskItemTs,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        water_error: WaterError.NONE,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);

    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_SERVER_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskItemStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: isPresent);
    TestHelper_Check.checkTaskItem(dto, taskItemStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        localTaskItemTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.id, C_TASK_ITEM_ID);
    expect(taskItemTrDto!.item_description, C_TASK_ITEM_DESCRIPTION);

    // Test Remote DB
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            TaskItemMixin.C_TABLE_ID,
            waterState,
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
        water_state: waterState,
        water_error: WaterError.NONE,
        tsSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterRemoteStruct);

    dto = await TestHelper_Fetch.fetchTaskItem(
        C_SERVER_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
    TestTaskItemDataStruct taskItemRemoteStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: isPresent);
    TestHelper_Check.checkTaskItem(dto, taskItemRemoteStruct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractPermissionRequestTest.remoteTs, smdSys, remoteTransaction);
    TestTrDataStruct trRemoteStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trRemoteStruct);
  }

  Future<void> test320_Admin_Post_Approved_TaskItem() async {
    await super.test320_Admin_Post_Approved_TaskItem();
    await Admin_Post_AppRej_TaskItem(WaterState.SERVER_APPROVED, true);
  }

  Future<void> test325_RequestEmptyTaskItem() async {
    await super.test325_RequestEmptyTaskItem();
    WaterLineField waterLineField = WaterLineField(
        localWardenType, WardenType.USER, smdSys, localTransaction);
    await waterLineField.init();
    try {
      await waterLineField.viewEntry(
          C_TASK_ITEM_ID, C_TASK_ITEM_TABLE_FIELD_ID);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    await super.requestUpdatedRows();
    WaterLineFieldDto? waterLineFieldDto;
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TASK_ITEM_TABLE_FIELD_ID,
        ChangeType.NOTIFY,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!,
        NotifyState.CLIENT_UP_TO_DATE,
        null,
        UiType.VIEWED,
        null,
        false,
        0,
        false);
    await TestHelper_Check.checkWaterLineFieldMaxAdded(
        ChangeType.NOTIFY, null, true, 0, false, smdSys, localTransaction);
  }

  Future<void> test350_Request_Rows() async {
    await super.test350_Request_Rows();

    await super.requestLatestRows(null);

    // Test Local DB
    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct taskItemStruct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true);
    TestHelper_Check.checkTaskItem(dto, taskItemStruct);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
