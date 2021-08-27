import 'package:test/test.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import '../rockvole_test.dart';

Future<void> test_db_basics(DbTransaction db) async {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  await db.getConnection().connect();
  TaskItemDao taskItemDao = TaskItemDao(smd, db);
  await taskItemDao.init();
  group("database basics", () {
    test('drop table', () async {
      try {
        bool success = await taskItemDao.dropTable();
        expect(success, true);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('table exists no', () async {
      try {
        bool exists = await taskItemDao.doesTableExist();
        expect(exists, false);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('create table', () async {
      try {
        bool success = await taskItemDao.createTable();
        expect(success, true);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('table exists yes', () async {
      try {
        bool exists = await taskItemDao.doesTableExist();
        expect(exists, true);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('insert row 1', () async {
      FieldData fieldDataInsert=FieldData.wee(TaskItemMixin.C_TABLE_ID);
      fieldDataInsert.set('id', 1);
      fieldDataInsert.set('task_id', 1);
      fieldDataInsert.set('item_description', "Walk zo shops");
      fieldDataInsert.set('item_complete', 0);
      try {
        int? insertId = await taskItemDao.insert(fieldDataInsert);
        expect(insertId, 1);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('add row 2', () async {
      FieldData fieldDataInsert=FieldData.wee(TaskItemMixin.C_TABLE_ID);
      fieldDataInsert.set('task_id', 1);
      fieldDataInsert.set('item_description', 'Get Carrier Bag');
      fieldDataInsert.set('item_complete', 0);
      try {
        int? insertId = await taskItemDao.add(fieldDataInsert, WardenType.WRITE_SERVER);
        expect(insertId, 2);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('max', () async {
      try {
        int maxId = await taskItemDao.getAutoIncrement("id");
        expect(maxId, 3);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('update row', () async {
      FieldData fieldDataUpdate=FieldData.wee(TaskItemMixin.C_TABLE_ID);
      fieldDataUpdate.set('item_description', 'Walk to shops');
      fieldDataUpdate.set('item_complete', 1);
      WhereData whereDataUpdate=WhereData();
      whereDataUpdate.set('id', SqlOperator.EQUAL, 1);
      try {
        await taskItemDao.update(fieldDataUpdate,whereDataUpdate);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('select row', () async {
      WhereData whereDataSelect=WhereData();
      whereDataSelect.set('task_id', SqlOperator.EQUAL, 1);
      whereDataSelect.addOrder('id', OrderType.ASC);
      try {
        RawTableData rawTableData = await taskItemDao.select(TaskItemDto.getSelectFieldData(),whereDataSelect);
        expect(rawTableData.rowCount, 2);
        expect(rawTableData.getRawField(0, 2),'Walk to shops');
        expect(rawTableData.getRawField(0, 3),1);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('select count(*)', () async {
      try {
        int count=await taskItemDao.getTotalCount();
        expect(count,1);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('close', () async {
      await db.getConnection().close();
    });
  });
}
