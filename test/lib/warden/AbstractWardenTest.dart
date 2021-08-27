import 'dart:io';
import 'package:test/test.dart';
import 'package:csv/csv.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import '../../rockvole_test.dart';

abstract class AbstractWardenTest {
  static const String C_ENTRY_SHOULD_NOT_EXIST = "Entry should not exist";
  static const String C_ENTRY_MUST_BE_ILLEGAL_STATE =
      "Must throw an Illegal state exception";
  DbTransaction clientDb;
  DbTransaction serverDb;
  late TaskDao clientTaskDao;
  late TaskItemDao clientTaskItemDao;
  late TaskDao serverTaskDao;
  late TaskTrDao serverTaskTrDao;
  late TaskItemDao serverTaskItemDao;
  late WaterLineDao serverWaterLineDao;
  static TableMetaData? tableMd;
  static WaterLine? waterLine;
  late WardenType localWardenType;
  late WardenType remoteWardenType;
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  late int taskMinIdForUser;
  late int taskItemMinIdForUser;
  static String preamble =
      "--------------------------------------------------------------------------------------------- ";
  static String C_FILE_TASK_CSV =
      "/work/projects/dart/rockvole_db/ancillary/import/task.csv";
  static String C_FILE_TASK_ITEM_CSV =
      "/work/projects/dart/rockvole_db/ancillary/import/task_item.csv";
  static String C_TASK_NAME = "task";
  static String C_TASK_ITEM_NAME = "task_item";
  static const int C_TASK_TABLE_ID = 1000;
  static const int C_TASK_ITEM_TABLE_ID = 1001;

  AbstractWardenTest(this.clientDb, this.serverDb);

  Future<void> run_all_tests(WardenType localWardenType, WardenType remoteWardenType) async {
    group(this.runtimeType.toString(), () {
      test("begin db", () async {
        await begin_db();
      });
      test("setup", () async {
        await test_setup(localWardenType, remoteWardenType);
      });
      test("clean client", () async {
        await clean_client();
      });
      test("clean server", () async {
        await clean_server();
      });
      test("import client", () async {
        await import_client();
      });
      test("import server", () async {
        await import_server();
      });
      test("initialize tables", () async {
        await initialize_tables();
      });
      test("insert server", () async {
        await insert_server();
      });
      test("update server", () async {
        await update_server();
      });
      test("delete server", () async {
        await delete_server();
      });
      test("close", () async {
        await close();
      });
    });
  }

  Future<void> begin_db() async {
    await clientDb.beginTransaction();
    await serverDb.beginTransaction();
  }

  Future<void> test_setup(
      WardenType localWardenType, WardenType remoteWardenType) async {
    this.localWardenType = localWardenType;
    this.remoteWardenType = remoteWardenType;
    // Setup dao
    smd=SchemaMetaData(false);
    smd = SchemaMetaDataTools.createSchemaMetaData(smd);
    smd = TaskDto.addSchemaMetaData(smd);
    smd = TaskItemDto.addSchemaMetaData(smd);
    smdSys = TransactionTools.createTrSchemaMetaData(smd);
    clientTaskDao = TaskDao(smd, clientDb);
    await clientTaskDao.init();
    clientTaskItemDao = TaskItemDao(smd, clientDb);
    await clientTaskItemDao.init();
    serverTaskDao = TaskDao(smd, serverDb);
    await serverTaskDao.init();
    serverTaskTrDao = TaskTrDao(smdSys, serverDb);
    await serverTaskTrDao.init();
    serverTaskItemDao = TaskItemDao(smd, serverDb);
    await serverTaskItemDao.init();
    serverWaterLineDao = WaterLineDao.sep(smdSys, serverDb);
    await serverWaterLineDao.init();

    taskMinIdForUser = clientTaskDao.getMinIdForUser;
    taskItemMinIdForUser = clientTaskItemDao.getMinIdForUser;
  }

  Future<void> clean_client() async {
    try {
      await clientTaskDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
    try {
      await clientTaskItemDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
  }

  Future<void> clean_server() async {
    try {
      await serverTaskDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
    try {
      await serverTaskTrDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
    try {
      await serverTaskItemDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
    try {
      await serverWaterLineDao.dropTable();
    } on SqlException catch (e) {
      print("ERROR:" + e.cause.toString());
    }
  }

  Future<void> _import_task(String fileName, TaskDao taskDao) async {
    // ------------------------------------------------------------------------- TASK
    var file = File(fileName);
    if (await file.exists()) {
      try {
        await taskDao.createTable();
        String content = file.readAsStringSync();
        List<List<dynamic>> csvList = const CsvToListConverter()
            .convert(content, fieldDelimiter: '|', eol: '\n');
        FieldData fieldData;
        for (List<dynamic> list in csvList) {
          if (list.length == 3) {
            fieldData = FieldData.wee(TaskMixin.C_TABLE_ID);
            fieldData.set('id', list[0]);
            fieldData.set('task_description', list[1]);
            fieldData.set('task_complete', list[2]);
            await taskDao.insert(fieldData);
          }
        }
      } on SqlException catch (e) {
        print("$e");
      }
    }
  }

  Future<void> _import_task_item(String fileName, TaskItemDao taskItemDao) async {
    // ------------------------------------------------------------------------- TASK_ITEM
    File file = File(fileName);
    if (await file.exists()) {
      await taskItemDao.createTable();
      String content = file.readAsStringSync();
      List<List<dynamic>> csvList = const CsvToListConverter()
          .convert(content, fieldDelimiter: '|', eol: '\n');
      FieldData fieldData;
      for (List<dynamic> list in csvList) {
        if (list.length == 4) {
          fieldData = FieldData.wee(TaskMixin.C_TABLE_ID);
          fieldData.set('id', list[0]);
          fieldData.set('task_id', list[1]);
          fieldData.set('item_description', list[2]);
          fieldData.set('item_complete', list[3]);
          await taskItemDao.insert(fieldData);
        }
      }
    }
  }

  Future<void> import_client() async {
    await _import_task(C_FILE_TASK_CSV, clientTaskDao);
    await _import_task_item(C_FILE_TASK_ITEM_CSV, clientTaskItemDao);
  }

  Future<void> import_server() async {
    await _import_task(C_FILE_TASK_CSV, serverTaskDao);
    await _import_task_item(C_FILE_TASK_ITEM_CSV, serverTaskItemDao);
  }

  Future<void> initialize_tables() async {
    await serverWaterLineDao.createTable();
  }

  Future<void> insert_server();
  Future<void> update_server();
  Future<void> delete_server();

  Future<void> close() async {
    await clientDb.getConnection().close();
    await serverDb.getConnection().close();
  }

  Future<AbstractWarden> initializeAbstractWarden(
      TaskTrDto taskTrDto, WaterState passedWaterState) async {
    TableTransactions tableTransactions = TableTransactions.sep(taskTrDto);
    await tableTransactions.init(localWardenType, remoteWardenType, smd, smdSys, serverDb);
    print("is.tt=$tableTransactions");
    AbstractWarden abstractWarden = WardenFactory.getAbstractWarden(
        localWardenType, remoteWardenType);
    await abstractWarden.init(smd, smdSys, serverDb);
    abstractWarden.initialize(tableTransactions,
        passedWaterState: passedWaterState);
    print("initialized $abstractWarden");
    return abstractWarden;
  }

  Future<void> runServerTest(
      int? id,
      WaterState passedWaterState,
      TestTaskDataStruct taskStruct,
      TestTrDataStruct trStruct,
      TestWaterLineDataStruct wlStruct,
      TestTrDataStruct? snapshotTrStruct,
      TestWaterLineDataStruct? snapshotWlStruct) async {
    RemoteDto? remoteDto;
    TaskTrDto taskTrDto = TaskTrDto.sep(
        id, taskStruct.task_description, taskStruct.task_complete, trStruct.getTrDto(TaskMixin.C_TABLE_ID));
    AbstractWarden abstractWarden =
        await initializeAbstractWarden(taskTrDto, passedWaterState);
    try {
      remoteDto = await abstractWarden.write();
    } on SqlException catch (e) {
      fail(e.cause!);
    }
    print("-------------------------- "+abstractWarden.runtimeType.toString()+" Complete");
    // ------------------------------------------------------- CHECK WATER_LINE
    WaterLineDto? testWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTs(trStruct.ts!, smdSys, serverDb);
    TestHelper_Check.checkWaterLineDto(testWaterLineDto, wlStruct);
    // ------------------------------------------------------- CHECK TASK
    TaskDto? testTaskDto =
        await TestHelper_Fetch.fetchTask(taskStruct.task_description!, smd, serverDb);
    TestHelper_Check.checkTask(testTaskDto, taskStruct);
    // ------------------------------------------------------- CHECK TASK_TR
    TaskTrDto? testTaskTrDto = await TestHelper_Fetch.fetchTaskTr(
        remoteDto!.waterLineDto!.water_ts!, smdSys, serverDb);
    TestHelper_Check.checkTrDto(testTaskTrDto, trStruct);
    taskStruct.ensureExists = trStruct.ensureExists;
    TestHelper_Check.checkTaskTr(testTaskTrDto, taskStruct);
    // ----------------------------------------------------------------------------- SNAPSHOT
    // ------------------------------------------------------- CHECK WATER_LINE
    if (snapshotTrStruct != null && snapshotWlStruct != null) {
      WaterLineDto testSnapshotWaterLineDto =
          await TestHelper_Fetch.fetchWaterLineDtoByTs(
              snapshotTrStruct.ts!, smdSys, serverDb);
      TestHelper_Check.checkWaterLineDto(
          testSnapshotWaterLineDto, snapshotWlStruct);
      // ------------------------------------------------------- CHECK TASK_TR
      TaskTrDto? testSnapshotTaskTrDto = await TestHelper_Fetch.fetchTaskTr(
          snapshotTrStruct.ts!, smdSys, serverDb);
      TestHelper_Check.checkTrDto(
          testSnapshotTaskTrDto, snapshotTrStruct);
      TestHelper_Check.checkTaskTr(testTaskTrDto, taskStruct);
    }
  }
}
