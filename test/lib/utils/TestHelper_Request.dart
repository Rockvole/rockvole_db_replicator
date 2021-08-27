import 'dart:io';

import 'package:test/test.dart';
import 'package:csv/csv.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import '../../rockvole_test.dart';

class TestHelper_Request {
  static const bool C_INIT_TABLE = true;

  static Future<void> cloneByEnumSet(
      Set<int>? tableTypeEnumSet,
      String importDirectory,
      DbTransaction exportDatabase,
      SchemaMetaData smd,
      ConfigurationNameDefaults defaults,
      {bool ignoreDuplicates = false}) async {
    if (tableTypeEnumSet == null) return;
    Iterator<int> tableIter = tableTypeEnumSet.iterator;
    while (tableIter.moveNext()) {
      int tableId = tableIter.current;
      String tableName = smd.getTableByTableId(tableId).table_name;
      File file = File("$importDirectory/$tableName.csv");
      if (await file.exists()) {
        String content = file.readAsStringSync();
        List<List<dynamic>> rowList = const CsvToListConverter()
            .convert(content, fieldDelimiter: '|', eol: '\n');
        Iterator<dynamic> rowIter = rowList.iterator;
        switch (tableName) {
          case "configuration":
            ConfigurationDao configurationDao =
                ConfigurationDao(smd, exportDatabase, defaults);
            await configurationDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 7) {
                ConfigurationDto configurationDto =
                    ConfigurationDto.list(list, defaults);
                try {
                  await configurationDao.insertDto(configurationDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "configuration_TR":
            ConfigurationTrDao configurationTrDao =
                ConfigurationTrDao(smd, exportDatabase, defaults);
            await configurationTrDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 13) {
                ConfigurationTrDto configurationTrDto =
                    ConfigurationTrDto.list(list, defaults);
                await configurationTrDao.insertDto(configurationTrDto);
                WaterLineDto waterLineDto =
                    WaterLineDto.convert(configurationTrDto, smd);
                WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
                await waterLineDao.init(initTable: C_INIT_TABLE);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "task":
            TaskDao taskDao = TaskDao(smd, exportDatabase);
            await taskDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 3) {
                TaskDto taskDto = TaskDto.list(list);
                try {
                  await taskDao.insertTaskDto(taskDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "task_TR":
            TaskTrDao taskTrDao = TaskTrDao(smd, exportDatabase);
            await taskTrDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 9) {
                TaskTrDto taskTrDto = TaskTrDto.list(list);
                try {
                  await taskTrDao.insertDto(taskTrDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
                WaterLineDto waterLineDto =
                    WaterLineDto.convert(taskTrDto, smd);
                WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
                await waterLineDao.init(initTable: C_INIT_TABLE);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "task_item":
            TaskItemDao taskItemDao = TaskItemDao(smd, exportDatabase);
            await taskItemDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 4) {
                TaskItemDto taskItemDto = TaskItemDto.list(list);
                try {
                  await taskItemDao.insertDto(taskItemDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "task_item_TR":
            TaskItemTrDao taskItemTrDao = TaskItemTrDao(smd, exportDatabase);
            await taskItemTrDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 10) {
                TaskItemTrDto taskItemTrDto = TaskItemTrDto.list(list);
                try {
                  await taskItemTrDao.insertDto(taskItemTrDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
                WaterLineDto waterLineDto =
                    WaterLineDto.convert(taskItemTrDto, smd);
                WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
                await waterLineDao.init(initTable: C_INIT_TABLE);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "user":
            UserDao userDao = UserDao(smd, exportDatabase);
            await userDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 6) {
                UserDto userDto = UserDto.list(list);
                try {
                  await userDao.insertDto(userDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "user_TR":
            UserTrDao userTrDao = UserTrDao(smd, exportDatabase);
            await userTrDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 12) {
                UserTrDto userTrDto = UserTrDto.list(list);
                try {
                  await userTrDao.insertDto(userTrDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
                WaterLineDto waterLineDto =
                    WaterLineDto.convert(userTrDto, smd);
                WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
                await waterLineDao.init(initTable: C_INIT_TABLE);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "user_store":
            UserStoreDao userStoreDao = UserStoreDao(smd, exportDatabase);
            await userStoreDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 8) {
                UserStoreDto userStoreDto = UserStoreDto.list(list);
                try {
                  await userStoreDao.insertDto(userStoreDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "user_store_TR":
            UserStoreTrDao userStoreTrDao = UserStoreTrDao(smd, exportDatabase);
            await userStoreTrDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 14) {
                UserStoreTrDto userStoreTrDto = UserStoreTrDto.list(list);
                try {
                  await userStoreTrDao.insertDto(userStoreTrDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
                WaterLineDto waterLineDto =
                    WaterLineDto.convert(userStoreTrDto, smd);
                WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
                await waterLineDao.init(initTable: C_INIT_TABLE);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
          case "water_line":
            WaterLineDao waterLineDao = WaterLineDao.sep(smd, exportDatabase);
            await waterLineDao.init(initTable: C_INIT_TABLE);
            while (rowIter.moveNext()) {
              List<dynamic> list = rowIter.current;
              if (list.length == 4) {
                WaterLineDto waterLineDto = WaterLineDto.list(list, smd);
                try {
                  await waterLineDao.insertWaterLineDto(waterLineDto);
                } on SqlException catch (e) {
                  if (ignoreDuplicates &&
                      e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY)
                    ;
                  else
                    rethrow;
                }
              }
            }
            break;
        }
      }
    }
  }

  static void cloneCommonTables(
      String importDirectory,
      DbTransaction exportDatabase,
      SchemaMetaData smd,
      bool cloneMajority,
      ConfigurationNameDefaults defaults) {

    Set<int> set = Set();
    smd.getTableMetaDataList().forEach((TableMetaData tmd) {
      set.add(tmd.table_id);
    });
    cloneByEnumSet(set, importDirectory, exportDatabase, smd, defaults);
  }

  static Future<void> changeWardenType(String email, WardenType wardenType,
      SchemaMetaData smd, DbTransaction transaction) async {
    UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
    await userStoreDao.init();
    late UserStoreDto userStoreDto;
    try {
      userStoreDto = await userStoreDao.getUserStoreDtoByUnique(email);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }

    UserDao userDao = UserDao(smd, transaction);
    await userDao.init();
    UserDto userDto;
    try {
      userDto = await userDao.getUserDtoById(userStoreDto.id!);
      userDto.warden = wardenType;
      await userDao.setUserDto(userDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
  }

  static Future<void> approveByAdmin(int ts, bool forServer, SchemaMetaData smdSys,
      DbTransaction transaction) async {
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    WaterLine waterLine = WaterLine(waterLineDao, smdSys, transaction);
    try {
      WaterLineDto waterLineDto = await waterLine.retrieveByTs(ts);
      print("Approve " + waterLineDto.table_id.toString());
      waterLine.setWaterState(
          forServer ? WaterState.SERVER_APPROVED : WaterState.CLIENT_APPROVED);
      await waterLine.updateRow();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
  }

  static Future<void> rejectByAdmin(
      int ts, SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    WaterLine waterLine = WaterLine(waterLineDao, smd, transaction);
    CleanTables cleanTables = CleanTables(smd, smdSys, transaction);
    await cleanTables.init();
    WaterLineDto waterLineDto;
    try {
      waterLineDto = await waterLine.retrieveByTs(ts);
      print(
          "Reject " + smd.getTableByTableId(waterLineDto.water_table_id).toString());
      waterLine.setWaterState(WaterState.CLIENT_REJECTED);
      await waterLine.updateRow();
      await cleanTables.deleteRow(waterLineDto, true, false, false);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) fail(e.cause!);
    }
  }
}
