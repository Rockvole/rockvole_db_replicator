import 'dart:io';
import 'package:test/test.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import '../../rockvole_test.dart';

enum IdentSpace { SERVER_SPACE, USER_SPACE }

class TestHelper_Check {
  static const String C_ENTRY_SHOULD_EXIST = "Entry should already exist";
  static const String C_ENTRY_SHOULD_NOT_EXIST = "Entry should not exist";

  static void _checkIdSpace(int id, IdentSpace? idSpace, int min_id_for_user) {
    if (idSpace == IdentSpace.USER_SPACE) {
      expect(id, greaterThanOrEqualTo(min_id_for_user),
          reason: "id should be greater than or equal to $min_id_for_user");
    } else {
      expect(id, lessThan(min_id_for_user),
          reason: "id should be less than $min_id_for_user");
    }
  }

  static void _checkTsSpace(int ts, IdentSpace tsSpace) {
    if (tsSpace == IdentSpace.USER_SPACE) {
      expect(ts, greaterThanOrEqualTo(WaterLineDto.min_id_for_user),
          reason: "WaterLine ts should be greater than or equal to " +
              WaterLineDto.min_id_for_user.toString());
    } else {
      expect(ts, lessThan(WaterLineDto.min_id_for_user),
          reason: "WaterLine ts should be less than " +
              WaterLineDto.min_id_for_user.toString());
    }
  }

  static Future<void> setCurrentUserId(SchemaMetaData smd, DbTransaction transaction,
      int cuId, ConfigurationNameDefaults defaults) async {
    ConfigurationDao configurationDao =
        ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    await configurationDao.insertDefaultValues();
    ConfigurationDto configurationDto = ConfigurationDto.sep(
        null,
        0,
        WardenType.USER,
        ConfigurationNameEnum.USER_ID,
        0,
        cuId,
        null,
        defaults);
    try {
      await configurationDao.setConfigurationDto(configurationDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail("$e");
      }
    }
  }

  // -------------------------------------------------------------------- TASK
  static TaskDto? checkTask(TaskDto? taskDto, TestTaskDataStruct struct) {
    checkDtoExistence(
        taskDto, struct.idSpace, struct.min_id_for_user, struct.ensureExists);
    if (struct.ensureExists) {
      if (struct.id != null)
        expect(taskDto!.id, struct.id, reason: "id does not match");
      if (struct.task_description != null)
        expect(taskDto!.task_description, struct.task_description,
            reason: "task_description does not match");
      if (struct.task_complete != null)
        expect(taskDto!.task_complete, struct.task_complete,
            reason: "task_complete does not match");
    }
    return taskDto;
  }

  static TaskTrDto? checkTaskTr(TaskTrDto? taskTrDto, TestTaskDataStruct struct) {
    checkDtoExistence(
        taskTrDto, struct.idSpace, struct.min_id_for_user, struct.ensureExists);
    if (struct.ensureExists) {
      if (struct.id != null)
        expect(taskTrDto!.id, struct.id, reason: "id does not match");
      if (struct.task_description != null)
        expect(taskTrDto!.task_description, struct.task_description,
            reason: "task_description does not match");
      if (struct.task_complete != null)
        expect(taskTrDto!.task_complete, struct.task_complete,
            reason: "task_complete does not match");
    }
    return taskTrDto;
  }

  // -------------------------------------------------------------------- TASK_ITEM
  static TaskItemDto? checkTaskItem(
      TaskItemDto? taskItemDto, TestTaskItemDataStruct struct) {
    checkDtoExistence(
        taskItemDto, struct.idSpace, struct.min_id_for_user, struct.ensureExists);
    if (struct.ensureExists) {
      if (struct.id != null)
        expect(taskItemDto!.id, struct.id, reason: "id does not match");
      if (struct.item_description != null)
        expect(taskItemDto!.item_description, struct.item_description,
            reason: "item_description does not match");
      if (struct.item_complete != null)
        expect(taskItemDto!.item_complete, struct.item_complete,
            reason: "item_complete does not match");
    }
    return taskItemDto;
  }

  static TaskItemTrDto checkTaskItemTr(
      TaskItemTrDto taskItemTrDto, TestTaskItemDataStruct struct) {
    checkDtoExistence(taskItemTrDto, struct.idSpace, struct.min_id_for_user,
        struct.ensureExists);
    if (struct.ensureExists) {
      if (struct.id != null)
        expect(taskItemTrDto.id, struct.id, reason: "id does not match");
      if (struct.item_description != null)
        expect(taskItemTrDto.item_description, struct.item_description,
            reason: "item_description does not match");
      if (struct.item_complete != null)
        expect(taskItemTrDto.item_complete, struct.item_complete,
            reason: "item_complete does not match");
    }
    return taskItemTrDto;
  }

// ------------------------------------------------------------------------------------------------------------------------------------- USER
  static UserDto checkUser(UserDto userDto, TestUserDataStruct struct,
      IdentSpace idSpace, bool ensureExists) {
    checkDtoExistence(userDto, idSpace, struct.min_id_for_user, ensureExists);
    if (ensureExists) {
      if (struct.pass_key != null)
        expect(userDto.pass_key, struct.pass_key,
            reason: "passkey does not match");
      expect(userDto.subset, struct.subset, reason: "subset does not match");
      expect(userDto.warden, struct.warden,
          reason: "wardentype does not match");
    }
    return userDto;
  }

  // -------------------------------------------------------------------- USER_STORE
  static UserStoreDto? checkUserStore(UserStoreDto? userStoreDto,
      TestUserStoreDataStruct struct, IdentSpace idSpace, bool ensureExists) {
    checkDtoExistence(userStoreDto, idSpace, struct.min_id_for_user, ensureExists);
    if (ensureExists) {
      if (struct.id != null)
        expect(userStoreDto!.id, struct.id, reason: "id does not match");
      expect(userStoreDto!.name, struct.name, reason: "name does not match");
      expect(userStoreDto.surname, struct.surname,
          reason: "surname does not match");
      if (struct.records_downloaded != null)
        expect(userStoreDto.records_downloaded, struct.records_downloaded,
            reason: "records_downloaded does not match");
      if (struct.changes_approved_count != null)
        expect(
            userStoreDto.changes_approved_count, struct.changes_approved_count,
            reason: "changes_approved_count does not match");
      if (struct.changes_denied_count != null)
        expect(userStoreDto.changes_denied_count, struct.changes_denied_count,
            reason: "changes_denied_count does not match");
    }
    return userStoreDto;
  }

  // -------------------------------------------------------------------- WATER_LINE
  static WaterLineDto checkWaterLineDto(
      WaterLineDto waterLineDto, TestWaterLineDataStruct struct) {
    if (struct.water_ts != null)
      expect(waterLineDto.water_ts, struct.water_ts,
          reason: "water_line has incorrect ts");
    if (struct.water_table_id != null)
      expect(waterLineDto.water_table_id, struct.water_table_id,
          reason: "water_line has incorrect table_id");
    if (struct.water_state != null)
      expect(waterLineDto.water_state, struct.water_state,
          reason: "water_line incorrect state");
    if (struct.water_error != null)
      expect(waterLineDto.water_error, struct.water_error,
          reason: "water_line incorrect error");
    _checkTsSpace(waterLineDto.water_ts!, struct.tsSpace!);
    return waterLineDto;
  }

  // ------------------------------------------------------------------------------------------------------------------------------------- WATER LINE FIELD
  static Future<void> ensureWaterLineFieldNotAdded(
      int id,
      int tableType,
      ChangeType change_type,
      int user_id,
      SchemaMetaData smdSys,
      DbTransaction transaction) async {
    WaterLineFieldDao lWaterLineFieldDao =
        WaterLineFieldDao.sep(smdSys, transaction);
    await lWaterLineFieldDao.init();
    try {
      await lWaterLineFieldDao.getWaterLineFieldDtoByUnique(
          id, tableType, change_type, user_id);
      fail("Entry should not exist");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) ;
    }
  }

  static WaterLineFieldDto checkWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto,
      NotifyState? notify_state,
      int? value_number,
      UiType? ui_type,
      int? local_ts,
      bool localTsMustBeNull,
      int? remote_ts,
      bool remoteTsMustBeNull) {
    expect(waterLineFieldDto.notify_state_enum, notify_state,
        reason: "water_line_field incorrect notify_state");
    expect(waterLineFieldDto.value_number, value_number,
        reason: "water_line_field incorrect value_number");
    expect(waterLineFieldDto.ui_type, ui_type,
        reason: "water_line_field incorrect ui_type");
    if (localTsMustBeNull)
      expect(waterLineFieldDto.local_ts, null, reason: "local_ts must be null");
    else {
      expect(waterLineFieldDto.local_ts, isNot(null),
          reason: "local_ts must not be null");
      if (local_ts != null)
        expect(
          waterLineFieldDto.local_ts,
          local_ts,
          reason: "water_line_field incorrect local_ts",
        );
    }
    if (remoteTsMustBeNull)
      expect(
        waterLineFieldDto.remote_ts,
        null,
        reason: "remote_ts must be null",
      );
    else {
      expect(waterLineFieldDto.remote_ts, isNot(null),
          reason: "remote_ts must not be null");
      if (remote_ts != null)
        expect(
          waterLineFieldDto.remote_ts,
          remote_ts,
          reason: "water_line_field incorrect remote_ts",
        );
    }
    return waterLineFieldDto;
  }

  static Future<void> ensureWaterLineFieldMaxNotAdded(ChangeType change_type,
      SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineFieldDao lWaterLineFieldDao =
        WaterLineFieldDao.sep(smdSys, transaction);
    await lWaterLineFieldDao.init();
    try {
      await lWaterLineFieldDao.getWaterLineFieldDtoByUnique(
          DbConstants.C_MEDIUMINT_MAX,
          TransactionTools.C_MAX_INT_TABLE_ID,
          change_type,
          WaterLineFieldDto.C_USER_ID_NONE);
      fail("Entry should not exist");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) ;
    }
  }

  static Future<WaterLineFieldDto> checkWaterLineFieldMaxAdded(
      ChangeType change_type,
      int? local_ts,
      bool localTsMustBeNull,
      int? remote_ts,
      bool remoteTsMustBeNull,
      SchemaMetaData smdSys,
      DbTransaction transaction) async {
    WaterLineFieldDto? waterLineFieldDto =
        await TestHelper_Fetch.fetchWaterLineFieldDtoByUnique(
            DbConstants.C_MEDIUMINT_MAX,
            TransactionTools.C_MAX_INT_TABLE_ID,
            change_type,
            WaterLineFieldDto.C_USER_ID_NONE,
            smdSys,
            transaction);
    return checkWaterLineFieldDto(waterLineFieldDto!, null, null, null, local_ts,
        localTsMustBeNull, remote_ts, remoteTsMustBeNull);
  }

  // -------------------------------------------------------------------- HCDTO
  static void checkTrDto(
      TrDto? trDto, TestTrDataStruct struct) {
    if (struct.ensureExists) {
      if (trDto == null) fail(C_ENTRY_SHOULD_EXIST);
      _checkIdSpace(trDto.id!, struct.idSpace, struct.min_id_for_user);
      _checkTsSpace(trDto.ts!, struct.tsSpace!);
      if (struct.ts != null)
        expect(trDto.ts, struct.ts, reason: "ts is incorrect");
      if (struct.operation != null)
        expect(trDto.operation, struct.operation,
            reason: "operation type is incorrect");
      if (struct.user_id != null)
        expect(trDto.user_id, struct.user_id, reason: "user_id is incorrect");
      if (struct.user_ts != null)
        expect(trDto.user_ts, struct.user_ts, reason: "user_ts is incorrect");
      if (struct.comment != null)
        expect(trDto.comment, struct.comment, reason: "comment is incorrect");
      if (struct.crc != null)
        expect(trDto.crc, struct.crc, reason: "crc is incorrect");
    } else {
      if (trDto != null) fail(C_ENTRY_SHOULD_NOT_EXIST);
    }
  }

  static void checkDtoExistence(
      FieldData? dto, IdentSpace? idSpace, int minIdForUser, bool ensureExists) {
    if (ensureExists) {
      if (dto == null) fail(C_ENTRY_SHOULD_EXIST);
      _checkIdSpace(dto.get('id') as int, idSpace, minIdForUser);
    } else {
      if (dto != null) fail(C_ENTRY_SHOULD_NOT_EXIST);
    }
  }

  // ------------------------------------------------------------------------------------------------------------------------------------- TOOLS
  static Future<void> waitASec() async {
    sleep(const Duration(seconds: 1));
  }

  static Future<void> setupWriteServer(UserDto userDto, UserStoreDto userStoreDto,
      SchemaMetaData smd, DbTransaction remoteTransaction) async {
    if (remoteTransaction != null) {
      // Store UserDto in remote database to ensure it exists
      UserDao remoteUserDao = UserDao(smd, remoteTransaction);
      await remoteUserDao.init(initTable: true);
      try {
        await remoteUserDao.setUserDto(userDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
      // Force remote server to be write server
      UserDto serverUserDto =
          UserDto.sep(1, null, 0, WardenType.WRITE_SERVER, 0, 0);
      UserTools remoteUserTools = UserTools();
      try {
        await remoteUserTools.setCurrentUserDto(
            smd, remoteTransaction, serverUserDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
      // ---------------------------------------------------------- User Store
      // Store UserDto in remote database to ensure it exists
      UserStoreDao remoteUserStoreDao =
          UserStoreDao(smd, remoteTransaction);
      await remoteUserStoreDao.init(initTable: true);
      try {
        await remoteUserStoreDao.setUserStoreDto(userStoreDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
      // Force remote server to be write server
      UserStoreDto serverUserStoreDto = UserStoreDto.sep(
          1,
          "writeserver@foodaversions.com",
          TimeUtils.getNowCustomTs(),
          "Write",
          "Server",
          0,
          0,
          0);
      try {
        await remoteUserTools.setCurrentUserStoreDto(
            smd, remoteTransaction, serverUserStoreDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
    }
  }

  static Future<void> setCurrentUserDetails(
      UserDto userDto,
      UserStoreDto userStoreDto,
      UserTools localUserTools,
      SchemaMetaData smd,
      DbTransaction localTransaction) async {
    if (userDto != null) {
      try {
        await localUserTools.setCurrentUserDto(smd, localTransaction, userDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
    }
    if (userStoreDto != null) {
      try {
        await localUserTools.setCurrentUserStoreDto(
            smd, localTransaction, userStoreDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
      }
    }
  }
}
