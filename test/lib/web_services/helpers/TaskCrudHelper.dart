import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class TaskCrudHelper {
  // ----------------------------------------------------------------------------------------------------------------- BRAND
  static Future<RemoteDto?> insertTask(
      String task_description,
      bool task_complete,
      DbTransaction transaction,
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    TrDto trDto = TrDto.sep(0, OperationType.INSERT, 33, null, "Insert Task", 0,
        TaskMixin.C_TABLE_ID);
    TaskTrDto taskTrDto =
    TaskTrDto.sep(null, task_description, task_complete, trDto);
    return await CrudHelper.writeTables(taskTrDto, localWardenType,
        remoteWardenType, transaction, smd, smdSys);
  }

// ----------------------------------------------------------------------------------------------------------------- PRODUCT
  static Future<RemoteDto?> insertTaskItem(
      int task_id,
      String item_description,
      bool item_complete,
      DbTransaction transaction,
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    TrDto trDto = TrDto.sep(0, OperationType.INSERT, 33, null,
        "Insert Task Item", 0, TaskItemMixin.C_TABLE_ID);
    TaskItemTrDto taskItemTrDto =
    TaskItemTrDto.sep(null, task_id, item_description, item_complete, trDto);
    return await CrudHelper.writeTables(taskItemTrDto, localWardenType,
        remoteWardenType, transaction, smd, smdSys);
  }

}