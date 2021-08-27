import 'package:test/test.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import '../rockvole_test.dart';

Future<void> test_db_transactions(DbTransaction db) async {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  SchemaMetaData smdSys = TransactionTools.createTrSchemaMetaData(smd);
  TaskItemTrDao taskItemTrDao = TaskItemTrDao(smdSys, db);
  await taskItemTrDao.init();

  group("database transactions", () {
    test('connect', () async {
      await db.getConnection().connect();
    });
    test('drop table', () async {
      try {
        await taskItemTrDao.dropTable();
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum, SqlExceptionEnum.TABLE_NOT_FOUND);
        print("ERROR: $e");
      }
      //exit(45);
    });
    test('create table', () async {
      try {
        bool success = await taskItemTrDao.createTable();
        expect(success, true);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test("insert row 1", () async {
      FieldData fieldDataInsert = FieldData.wee(TaskItemMixin.C_TABLE_ID);
      fieldDataInsert.set('id', 1);
      fieldDataInsert.set('task_id', 1);
      fieldDataInsert.set('item_description', 'Walk zo shops');
      fieldDataInsert.set('item_complete', 0);
      TrDto trDto = TrDto.sep(
          12, OperationType.INSERT, 5, 435642, 'Insert by User', 65478,
          TaskItemMixin.C_TABLE_ID);
      try {
        int? insertTs = await taskItemTrDao.insertTR(trDto, fieldDataInsert);
        expect(insertTs, 12);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test('insert row 2', () async {
      FieldData fieldDataInsert = FieldData.wee(TaskItemMixin.C_TABLE_ID);
      fieldDataInsert.set('id', 2);
      fieldDataInsert.set('task_id', 1);
      fieldDataInsert.set('item_description', 'Get Carrier Bag');
      fieldDataInsert.set('item_complete', 0);
      TrDto trDto = TrDto.sep(
          13, OperationType.INSERT, 5, 436567, 'Insert by User', 897503,
          TaskItemMixin.C_TABLE_ID);
      try {
        int? insertTs = await taskItemTrDao.insertTR(trDto, fieldDataInsert);
        expect(insertTs, 13);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test('max', () async {
      try {
        int maxId = await taskItemTrDao.getAutoIncrement("ts");
        expect(maxId, 14);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test('update row', () async {
      TrDto trDto = TrDto.sep(
          12, OperationType.INSERT, 5, 343256, 'Update by User', 345324,
          TaskItemMixin.C_TABLE_ID);
      try {
        await taskItemTrDao.updateTaskItemHC(
            null, 'Walk to shops', true, trDto);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test('select row', () async {
      try {
        RawTableData rawTableData = await taskItemTrDao.selectTR(WhereData());
        expect(rawTableData.rowCount, 2);
        expect(rawTableData.getRawField(0, 0), 1);
        expect(rawTableData.getRawField(0, 1), 1);
        expect(rawTableData.getRawField(0, 2), 'Walk to shops');
        expect(rawTableData.getRawField(0, 3), 1);
        expect(rawTableData.getRawField(0, 4), 12);
        expect(rawTableData.getRawFieldByFieldName(0, 'ts'), 12);
        expect(rawTableData.getRawFieldByFieldName(0, 'operation'), 1);
        expect(rawTableData.getRawFieldByFieldName(0, 'user_id'), 5);
        expect(rawTableData.getRawFieldByFieldName(0, 'user_ts'), 343256);
        expect(rawTableData.getRawFieldByFieldName(0, 'comment'),
            'Update by User');
        expect(rawTableData.getRawFieldByFieldName(0, 'crc'), 345324);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
    test('select count(*)', () async {
      try {
        int count = await taskItemTrDao.getTotalCount();
        expect(count, 1);
      } on SqlException catch (e) {
        fail("ERROR: $e");
      }
    });
  });
}
