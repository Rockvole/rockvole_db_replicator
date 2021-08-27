import 'package:test/test.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import '../rockvole_test.dart';

Future<void> test_db_exceptions(DbTransaction db) async {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  TaskDao taskDao = TaskDao(smd, db);
  await taskDao.init(initTable: false);
  group("database exceptions", () {
    test('connect', () async {
      await db.getConnection().connect();
    });
    test('drop table', () async {
      try {
        await taskDao.dropTable();
        fail(C_TASK_SHOULD_NOT_EXIST);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.TABLE_NOT_FOUND);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('insert row 1', () async {
      FieldData fieldDataInsert=FieldData.wee(TaskMixin.C_TABLE_ID);
      fieldDataInsert.set('id', 1);
      fieldDataInsert.set('task_description', 'Get shopzing');
      fieldDataInsert.set('task_complete', 0);
      try {
        await taskDao.insert(fieldDataInsert);
        fail(C_TASK_SHOULD_NOT_EXIST);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.TABLE_NOT_FOUND);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('update row', () async {
      FieldData fieldDataUpdate=FieldData.wee(TaskMixin.C_TABLE_ID);
      fieldDataUpdate.set('task_description', 'Get shopping');
      fieldDataUpdate.set('task_complete', 1);
      WhereData whereDataUpdate=WhereData();
      whereDataUpdate.set('id', SqlOperator.EQUAL, 1);
      try {
        await taskDao.update(fieldDataUpdate,whereDataUpdate);
        fail(C_TASK_SHOULD_NOT_EXIST);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.TABLE_NOT_FOUND);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('select row', () async {
      WhereData whereDataSelect=WhereData();
      whereDataSelect.set('id', SqlOperator.EQUAL, 1);
      try {
        await taskDao.select(TaskDto.getSelectFieldData(),whereDataSelect);
        fail(C_TASK_SHOULD_NOT_EXIST);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.ENTRY_NOT_FOUND);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('create table 1', () async {
      try {
        bool success = await taskDao.createTable();
        expect(success, true);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('create table 2', () async {
      try {
        await taskDao.createTable();
        fail(C_TASK_SHOULD_ALREADY_EXIST);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.TABLE_ALREADY_EXISTS);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('drop table', () async {
      try {
        bool success = await taskDao.dropTable();
        expect(success, true);
      } on SqlException catch (e) {
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('close', () async {
      await db.getConnection().close();
    });
  });
  group('Socket closed tests', () {
    test('create table 3', () async {
      try {
        await taskDao.createTable();
        fail(C_TASK_SHOULD_NO_SOCKET);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.SOCKET_CLOSED);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('insert row 1', () async {
      FieldData fieldDataInsert=FieldData.wee(TaskMixin.C_TABLE_ID);
      fieldDataInsert.set('id', 1);
      fieldDataInsert.set('task_description', 'Get shopzing');
      fieldDataInsert.set('task_complete', 0);
      try {
        await taskDao.insert(fieldDataInsert);
        fail(C_TASK_SHOULD_NO_SOCKET);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.SOCKET_CLOSED);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('update row', () async {
      FieldData fieldDataUpdate=FieldData.wee(TaskMixin.C_TABLE_ID);
      fieldDataUpdate.set('task_description', 'Get shopping');
      fieldDataUpdate.set('task_complete', 1);
      WhereData whereDataUpdate=WhereData();
      whereDataUpdate.set('id', SqlOperator.EQUAL, 1);
      try {
        await taskDao.update(fieldDataUpdate,whereDataUpdate);
        fail(C_TASK_SHOULD_NO_SOCKET);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.SOCKET_CLOSED);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('select row', () async {
      WhereData whereDataSelect=WhereData();
      whereDataSelect.set('id', SqlOperator.EQUAL, 1);
      try {
        await taskDao.select(TaskDto.getSelectFieldData(),whereDataSelect);
        fail(C_TASK_SHOULD_NO_SOCKET);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.SOCKET_CLOSED);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
    test('drop table', () async {
      try {
        await taskDao.dropTable();
        fail(C_TASK_SHOULD_NO_SOCKET);
      } on SqlException catch (e) {
        expect(e.sqlExceptionEnum,SqlExceptionEnum.SOCKET_CLOSED);
        print("ERROR:" + SqlExceptionTools.getMessage(e.sqlExceptionEnum));
      }
    });
  });
}