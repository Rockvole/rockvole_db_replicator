import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class WlfLike_TaskTest extends AbstractPermissionRequestTest {
  // aversion_name => task
  // aversion => task_item
  static final String C_PARTITION_PART_NAME = "Fish Fingers";
  static late AbstractFieldWarden abstractFieldWarden;

  static late int C_TASK_TABLE_FIELD_ID;
  static final int C_TIME_STAMP = 9474623;
  static final int C_ID = 1;

  static final String C_TASK_DESCRIPTION = "Clean Car";
  static final int C_PART_ID = 1;
  static final int C_LIKE_COUNT = 9895;

  static final int C_TASK_ITEM_ID = 8;
  static final String C_TASK_ITEM_DESCRIPTION = "Push-Ups";

  WlfLike_TaskTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  Future<DbTransaction> test001_SetUp(
      WardenType localWT,
      WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    C_TASK_TABLE_FIELD_ID =
        smd.getField(TaskMixin.C_TABLE_ID, 'task_description').table_field_id;
    return await super.test001_SetUp(
        WardenType.ADMIN,
        WardenType.ADMIN,
        localDatabaseName: "client_db",
        remoteDatabaseName: "server_db");
  }

  Future<void> test005_CloneFromCsv(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTableTypeEnumSet.add(TaskMixin.C_TABLE_ID);
    await super.test005_CloneFromCsv(
        localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
    abstractFieldWarden = AbstractFieldWarden(
        localWardenType, remoteWardenType, smd, smdSys, localTransaction);
  }

  Future<void> test007_CloneFromCsvToRemote(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        dropPartitions: false);
  }

  Future<void> test012_InsertCurrentAdmin() async {
    await super.test110_InsertCurrentAdmin();
  }

  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    localWardenType = WardenType.USER;
    remoteWardenType = WardenType.USER;
    await super.test015_UpdateConfiguration(
        localWardenType, remoteWardenType, transaction: localTransaction);
    try {
      restGetLatestWaterLineFieldsUtils = RestGetLatestWaterLineFieldsUtils(
          localWardenType,
          remoteWardenType,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restGetLatestWaterLineFieldsUtils.init();
      restPostWaterLineFieldsUtils = RestPostWaterLineFieldsUtils(
          localWardenType,
          remoteWardenType,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults);
      await restPostWaterLineFieldsUtils.init();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.toString());
    }
  }

  // Add entry in water_line_field to show user has this product in a list.
  Future<void> test048_Like_Task() async {
    await super.test048_Like_Task();
    WaterLineFieldDto? waterLineFieldDto;
    try {
      waterLineFieldDto = WaterLineFieldDto.sep(
          C_ID,
          C_TASK_TABLE_FIELD_ID,
          ChangeType.LIKE,
          WaterLineFieldDto.C_USER_ID_NONE,
          null,
          null,
          null,
          C_TIME_STAMP,
          null,
          smd);
      await abstractFieldWarden.init(waterLineFieldDto);
      await abstractFieldWarden.write();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    // Test Local DB
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    TestHelper_Check.checkWaterLineFieldDto(waterLineFieldDto!,
        NotifyState.CLIENT_STORED, null, null, null, true, null, true);
  }

  Future<void> test058_Post_Fields() async {
    await super.test058_Post_Fields();
    TaskDto? dto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, remoteTransaction);
    TestTaskDataStruct taskStruct = TestTaskDataStruct(
        idSpace: IdentSpace.SERVER_SPACE, ensureExists: true);
    TestHelper_Check.checkTask(dto, taskStruct);

    await super.postWaterLineFields();
    WaterLineFieldDto? waterLineFieldDto;
    // Test Remote DB
    dto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, remoteTransaction);
    TestTaskDataStruct taskRemoteStruct = TestTaskDataStruct(
        idSpace: IdentSpace.SERVER_SPACE, ensureExists: true);
    TestHelper_Check.checkTask(dto, taskRemoteStruct);
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        remoteTransaction);
    TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!, null, null, null, null, false, null, true);
    await TestHelper_Check.checkWaterLineFieldMaxAdded(
        ChangeType.LIKE,
        waterLineFieldDto.local_ts,
        false,
        null,
        true,
        smdSys,
        remoteTransaction);

    // Test Local DB
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    TestHelper_Check.checkWaterLineFieldDto(waterLineFieldDto!,
        NotifyState.CLIENT_SENT, null, null, null, true, null, true);
  }

  @override
  Future<void> test068_Insert_LikeCount() async {
    await super.test068_Insert_LikeCount();
    WaterLineFieldDto? waterLineFieldDto;
    try {
      waterLineFieldDto = WaterLineFieldDto.sep(
          C_TASK_ITEM_ID,
          C_TASK_TABLE_FIELD_ID,
          ChangeType.LIKE,
          WaterLineFieldDto.C_USER_ID_NONE,
          null,
          null,
          null,
          C_TIME_STAMP,
          null,
          smd);
      await abstractFieldWarden.init(waterLineFieldDto);
      await abstractFieldWarden.write();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
    await super.postWaterLineFields();
    // Test Local DB
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    TestHelper_Check.checkWaterLineFieldDto(waterLineFieldDto!,
        NotifyState.CLIENT_SENT, null, null, null, true, null, true);
    await TestHelper_Check.ensureWaterLineFieldMaxNotAdded(
        ChangeType.LIKE, smdSys, localTransaction);

    // Test Remote DB
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        remoteTransaction);
    TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!, null, null, null, null, false, null, true);
  }

  Future<void> test078_SimulateRemoteLikes() async {
    await super.test078_SimulateRemoteLikes();
    // Remove water_line_field entry locally so we simulate this user did not like
    WaterLineFieldDao waterLineFieldDao =
        WaterLineFieldDao.sep(smdSys, localTransaction);
    await waterLineFieldDao.init();
    try {
      await waterLineFieldDao.deleteWaterLineFieldByUnique(
          C_TASK_ITEM_ID,
          C_TASK_TABLE_FIELD_ID,
          ChangeType.LIKE,
          WaterLineFieldDto.C_USER_ID_NONE);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND) fail(e.cause!);
    }
    TaskDto? dto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, localTransaction);
    TestTaskDataStruct struct = TestTaskDataStruct(
        id: C_ID,
        task_description: C_TASK_DESCRIPTION,
        task_complete: false,
        idSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true);
    TestHelper_Check.checkTask(dto, struct);

    // Change remote like count to simulate additional likes
    TaskDao taskDao = TaskDao(smd, remoteTransaction);
    await taskDao.init();
    try {
      await taskDao.updateTask(C_TASK_ITEM_ID, 'test description', false);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
  }

  Future<void> test088_Admin_Get_Fields() async {
    await super.test088_Admin_Get_Fields();
    await super.requestUpdatedWaterLineFields(ChangeSuperType.VOTING, null);

    WaterLineFieldDto? waterLineFieldDto;
    // Test Remote DB
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        remoteTransaction);
    TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!, null, null, null, null, false, null, true);
    await TestHelper_Check.checkWaterLineFieldMaxAdded(
        ChangeType.LIKE,
        waterLineFieldDto.local_ts,
        false,
        null,
        true,
        smdSys,
        remoteTransaction);

    // Test Local DB
    TaskDto? taskDto = await TestHelper_Fetch.fetchTask(
        C_TASK_DESCRIPTION, smd, localTransaction);
    TestTaskDataStruct taskStruct = TestTaskDataStruct(
        id: C_ID, idSpace: IdentSpace.SERVER_SPACE, ensureExists: true);
    TestHelper_Check.checkTask(taskDto, taskStruct);
    await TestHelper_Check.ensureWaterLineFieldNotAdded(
        C_TASK_ITEM_ID,
        C_TASK_TABLE_FIELD_ID,
        ChangeType.LIKE,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
