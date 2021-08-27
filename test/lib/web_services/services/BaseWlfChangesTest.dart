import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class BaseWlfChangesTest extends AbstractPermissionRequestTest {
  static late List<RemoteDto> remoteDtoList;
  static late AbstractFieldWarden abstractFieldWarden;
  
  static final int C_TABLE_FIELD_ID = 500503;
  static final String C_TABLE_FULL_NAME = "TaskItem";
  static final int C_TIME_STAMP = 894759;
  static final int C_TASK_ID = 11;
  static final int C_TASK_ITEM_ID = 10;
  static final int C_GROUP_ID = 12;
  static final String C_ITEM_DESCRIPTION = "SitUps";
  static final String C_TASK_DESCRIPTION = "Exercise";

  BaseWlfChangesTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  Future<DbTransaction> test001_SetUp(
      WardenType localWT,
      WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
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
    // Test local joins by removing these clones
    minTableTypeEnumSet.add(TaskItemMixin.C_TABLE_ID);
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
    // Test remote joins by removing these clones
    //tableTypeEnumSet.add(TableType.INGREDIENT_NAME);
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: tableTypeEnumSet,
        trTableTypeEnumSet: trTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test010_InsertCurrentUser() {
    return super.test010_InsertCurrentUser();
  }

  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(
        WardenType.USER,
        WardenType.USER,
        transaction: localTransaction);
    try {
      restGetLatestWaterLineFieldsUtils = RestGetLatestWaterLineFieldsUtils(
          WardenType.USER,
          WardenType.USER,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restGetLatestWaterLineFieldsUtils.init();
      restRequestSelectedRowsUtils = RestRequestSelectedRowsUtils(
          WardenType.USER, WardenType.READ_SERVER,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
      await restRequestSelectedRowsUtils.init();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.toString());
    }
  }

  Future<void> test029_UserViewsTaskItem() async {
    await super.test029_UserViewsTaskItem();
    WaterLineFieldDto? waterLineFieldDto;
    WaterLineField waterLineField = WaterLineField(
        localWardenType, remoteWardenType, smdSys, localTransaction);
    await waterLineField.init();
    try {
      await waterLineField.viewEntry(C_TASK_ITEM_ID, C_TABLE_FIELD_ID);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TABLE_FIELD_ID,
        ChangeType.NOTIFY,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!,
        NotifyState.CLIENT_OUT_OF_DATE,
        null,
        UiType.VIEWED,
        null,
        false,
        null,
        true);

    await super.requestUpdatedRows();
    waterLineFieldDto = await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
        C_TASK_ITEM_ID,
        C_TABLE_FIELD_ID,
        ChangeType.NOTIFY,
        WaterLineFieldDto.C_USER_ID_NONE,
        smdSys,
        localTransaction);
    await TestHelper_Check.checkWaterLineFieldDto(
        waterLineFieldDto!,
        NotifyState.CLIENT_UP_TO_DATE,
        null,
        UiType.VIEWED,
        null,
        false,
        null,
        false);
    await TestHelper_Check.checkWaterLineFieldMaxAdded(ChangeType.NOTIFY, null,
        true, waterLineFieldDto.remote_ts, false, smdSys, localTransaction);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
