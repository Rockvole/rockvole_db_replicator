import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class PostTaskItemTest extends AbstractPermissionRequestTest {
  static final String C_TASK_NAME = "Exercise";
  static final bool C_TASK_COMPLETE = false;
  static final String C_TASK_ITEM_DESCRIPTION = "Chin-Ups";
  static final bool C_TASK_ITEM_COMPLETE = true;
  static final int C_TABLE_TYPE = TaskMixin.C_TABLE_ID;
  static final String C_TABLE_FULL_NAME = "Task";
  static final int C_TASK_ID = 1;
  static final int C_USER_TASK_ITEM_ID = TaskItemMixin.min_id_for_user;
  static final int C_TASK_ITEM_ID = 38;
  static late TaskItemDto taskItemDto;
  static TaskItemTrDto? taskItemTrDto;

  PostTaskItemTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
  Future<DbTransaction> test001_SetUp(
      WardenType localWT,
      WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    return await super.test001_SetUp(
        WardenType.USER,
        WardenType.USER,
        localDatabaseName: "client_db",
        remoteDatabaseName: "server_db");
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
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();
  }

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

  Future<void> test070_User_Create_TaskItem() async {
    await super.test070_User_Create_TaskItem();

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
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct struct = TestTaskItemDataStruct(
        id: C_USER_TASK_ITEM_ID,
        task_id: C_TASK_ID,
        item_description: C_TASK_ITEM_DESCRIPTION,
        item_complete: C_TASK_ITEM_COMPLETE,
        idSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkTaskItem(dto, struct);

    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
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
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestWaterLineDataStruct waterStruct = TestWaterLineDataStruct(
        water_ts: AbstractRequestTest.userTs,
        water_table_id: TaskItemMixin.C_TABLE_ID,
        water_state: WaterState.CLIENT_SENT,
        tsSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, waterStruct);
    TaskItemDto? dto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, localTransaction);
    TestTaskItemDataStruct struct = TestTaskItemDataStruct(
        id: C_TASK_ITEM_ID, idSpace: IdentSpace.SERVER_SPACE);
    TestHelper_Check.checkTaskItem(dto, struct);
    taskItemTrDto = await TestHelper_Fetch.fetchTaskItemTr(
        AbstractRequestTest.userTs, smdSys, localTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        min_id_for_user: TaskItemMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(taskItemTrDto, trStruct);
    expect(taskItemTrDto!.item_description, C_TASK_ITEM_DESCRIPTION);

    // Test Remote DB
    dto = await TestHelper_Fetch.fetchTaskItem(
        C_TASK_ID, C_TASK_ITEM_DESCRIPTION, smd, remoteTransaction);
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

  Future<void> test090_User_Post_Duplicate_TaskItem() async {
    await super.test090_User_Post_Duplicate_TaskItem();
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, localTransaction);
    await waterLineDao.init();
    try {
      await waterLineDao.updateWaterLine(AbstractRequestTest.userTs,
          TaskItemMixin.C_TABLE_ID, WaterState.CLIENT_STORED, WaterError.NONE);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
        fail(e.cause!);
    }
    try {
      await super.postOneRow(localTransaction);
      fail("Must throw exception");
    } on TransmitStatusException catch (e) {
      if (e.remoteStatus != RemoteStatus.DUPLICATE_ENTRY)
        fail("Expecting duplicate entry");
    }
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
