import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../rockvole_test.dart';

class TestHelper_Fetch {
  // -------------------------------------------------------------------- TASK
  static Future<TaskDto?> fetchTask(
      String task_description, SchemaMetaData smd, DbTransaction transaction) async {
    TaskDao taskDao = TaskDao(smd, transaction);
    await taskDao.init();
    TaskDto? taskDto;
    try {
      taskDto = await taskDao.getTaskDtoByUnique(task_description);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return taskDto;
  }

  static Future<TaskTrDto?> fetchTaskTr(
      int ts, SchemaMetaData smdSys, DbTransaction transaction) async {
    TaskTrDao taskTrDao = TaskTrDao(smdSys, transaction);
    await taskTrDao.init();
    TaskTrDto? taskTrDto;
    try {
      taskTrDto = await taskTrDao.getTaskTrDtoByTs(ts);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return taskTrDto;
  }
  // -------------------------------------------------------------------- TASK ITEM
  static Future<TaskItemDto?> fetchTaskItem(
      int task_id, String item_description, SchemaMetaData smd, DbTransaction transaction) async {
    TaskItemDao taskItemDao = TaskItemDao(smd, transaction);
    await taskItemDao.init();
    TaskItemDto? taskItemDto;
    try {
      taskItemDto = await taskItemDao.getTaskItemDtoByUnique(task_id, item_description);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return taskItemDto;
  }

  static Future<TaskItemTrDto?> fetchTaskItemTr(
      int ts, SchemaMetaData smdSys, DbTransaction transaction) async {
    TaskItemTrDao taskItemTrDao = TaskItemTrDao(smdSys, transaction);
    await taskItemTrDao.init();
    TaskItemTrDto? taskItemTrDto;
    try {
      taskItemTrDto = await taskItemTrDao.getTaskItemTrDtoByTs(ts);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return taskItemTrDto;
  }
  // ------------------------------------------------------------------------------------------------------------------------------------- USER
  static Future<UserDto?> fetchUserById(int id, SchemaMetaData smd, DbTransaction transaction) async {
    UserDao remoteUserDao = UserDao(smd, transaction);
    await remoteUserDao.init();
    UserDto? userDto;
    try {
      userDto = await remoteUserDao.getUserDtoById(id);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return userDto;
  }

  static Future<UserTrDto?> fetchUserTr(int ts, SchemaMetaData smdSys, DbTransaction transaction) async {
    UserTrDao remoteUserDao = UserTrDao(smdSys, transaction);
    UserTrDto? userTrDto;
    try {
      userTrDto = await remoteUserDao.getUserTrDtoByTs(ts);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return userTrDto;
  }
  // -------------------------------------------------------------------- USER_STORE
  static Future<UserStoreDto?> fetchUserStore(
      String email, SchemaMetaData smd, DbTransaction transaction) async {
    UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
    await userStoreDao.init();
    UserStoreDto? userStoreDto;
    try {
      userStoreDto = await userStoreDao.getUserStoreDtoByUnique(email);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return userStoreDto;
  }

  static Future<UserStoreTrDto?> fetchUserStoreTr(
      int ts, SchemaMetaData smdSys, DbTransaction transaction) async {
    UserStoreTrDao userStoreTrDao = UserStoreTrDao(smdSys, transaction);
    await userStoreTrDao.init();
    UserStoreTrDto? userStoreTrDto;
    try {
      userStoreTrDto = await userStoreTrDao.getUserStoreTrDtoByTs(ts);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    return userStoreTrDto;
  }

  // -------------------------------------------------------------------- WATER_LINE
  static Future<WaterLineDto> fetchWaterLineDtoByTs(
      int ts, SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    late WaterLineDto waterLineDto;
    try {
      waterLineDto = await waterLineDao.getWaterLineDto(ts, null, null, null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        fail(e.cause!);
      }
      rethrow;
    }
    return waterLineDto;
  }

  static Future<List<WaterLineDto>?> fetchWaterLineListByTableType(
      int tableType,
      WaterState? waterState,
      WaterError? waterError,
      bool ensureExists,
      SchemaMetaData smdSys,
      DbTransaction transaction) async {
    bool? found;
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    List<WaterLineDto>? waterLineDtoList;
    try {
      waterLineDtoList = await waterLineDao.getWaterLineByTableType(
          tableType, waterState, waterError);
      found = true;
      print("wldto list=$waterLineDtoList");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        found = false;
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
    }
    if (ensureExists) {
      if (found == false) fail(TestHelper_Check.C_ENTRY_SHOULD_EXIST);
    } else {
      if (found == true) fail(TestHelper_Check.C_ENTRY_SHOULD_NOT_EXIST);
      return null;
    }
    return waterLineDtoList;
  }

  static Future<WaterLineDto?> fetchWaterLineDtoByTableType(
      int tableType,
      WaterState? waterState,
      WaterError? waterError,
      bool ensureExists,
      SchemaMetaData smdSys,
      DbTransaction transaction) async {
    List<WaterLineDto>? waterLineDtoList = await fetchWaterLineListByTableType(
        tableType, waterState, waterError, ensureExists, smdSys, transaction);
    if (waterLineDtoList == null) return null;
    return waterLineDtoList[waterLineDtoList.length - 1];
  }
  // ------------------------------------------------------------------------------------------------------------------------------------- WATER LINE FIELD
  static Future<WaterLineFieldDto?> fetchWaterLineFieldDtoByUnique(int id, int table_field_id, ChangeType changeType, int userId,
      SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineFieldDao waterLineFieldDao = WaterLineFieldDao.sep(smdSys, transaction);
    await waterLineFieldDao.init();
    WaterLineFieldDto? waterLineFieldDto;
    try {
      waterLineFieldDto = await waterLineFieldDao.getWaterLineFieldDtoByUnique(id, table_field_id, changeType, userId);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        fail(e.cause!);
      }
    }
    return waterLineFieldDto;
  }

  static Future<WaterLineFieldDto?> fetchMaxWaterLineFieldDto(ChangeType changeType, SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineFieldDao waterLineFieldDao = WaterLineFieldDao.sep(smdSys, transaction);
    WaterLineFieldDto? waterLineFieldDto;
    try {
      waterLineFieldDto = await waterLineFieldDao.getMaxDto(changeType);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        fail(e.cause!);
      }
    }
    return waterLineFieldDto;
  }
}
