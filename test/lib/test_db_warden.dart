import 'dart:io';

import 'package:test/test.dart';
import 'package:csv/csv.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import '../rockvole_test.dart';

const String C_FILE_TASK_ITEM_CSV = "/work/projects/dart/rockvole_db/ancillary/import/task_item.csv";

Future<void> test_db_warden(DbTransaction db) async {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  TaskItemDao taskItemDao = TaskItemDao(smd, db);
  await taskItemDao.init();

  SchemaMetaData smdSys = TransactionTools.createTrSchemaMetaData(smd);
  print("$smdSys");
  TaskItemTrDao taskItemTrDao = TaskItemTrDao(smdSys, db);
  await taskItemTrDao.init();

  group("warden tests", () {
    test('connect', () async {
      await db.getConnection().connect();
    });
    test('drop table', () async {
      try {
        bool success = await taskItemDao.dropTable();
        expect(success, true);
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
    test('convert csv', () async {
      var file=File(C_FILE_TASK_ITEM_CSV);
      if(await file.exists()) {
        String content = file.readAsStringSync();
        List<List<dynamic>> csvList = const CsvToListConverter().convert(content,fieldDelimiter: '|',eol: '\n');
        print("csvList=$csvList");
      }
    });
  });
}