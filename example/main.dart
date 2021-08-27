import 'package:rockvole_db_replicator/rockvole_db.dart';

import '../test/lib/dao/TaskDao.dart';
import '../test/lib/dao/TaskItemDao.dart';

main() async {
  SchemaMetaData smd=SchemaMetaData(false);
  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);
  TableMetaData tmdTask = smd.getTableByName("task")!;
  FieldMetaData fmdTask = tmdTask.getFieldByFieldName("task_id");
  print("FieldMetaData");
  print(fmdTask);

  fmdTask = tmdTask.getFieldByTableFieldId(2);
  print(fmdTask);

  print("TableMetaData");
  TableMetaData tmdList = smd.getTableByName("task_item")!;
  print(tmdList);
  tmdList = smd.getTableByTableId(2);
  print(tmdList);

  print("TableMetaData list table");
  print(smd.getTableByName("task_item")!.getFieldList());

}


