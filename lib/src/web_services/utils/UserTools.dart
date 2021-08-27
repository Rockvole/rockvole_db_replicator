import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class UserTools {
  static final int _C_SLACK_SECS = 30;
  int? _currentUserId;
  UserDto? _currentUserDto;
  UserStoreDto? _currentUserStoreDto;
  late Map<ConfigurationNameEnum, SimpleEntry> _configurationTable;
  late ConfigurationNameDefaults _defaults;

  UserTools() {
    _currentUserId = null;
    _currentUserDto = null;
    _currentUserStoreDto = null;
    _configurationTable = Map();
    _defaults = ConfigurationNameDefaults();
  }

  // --------------------------------------------------------------------------------------------- USER
  Future<int?> getCurrentUserId(
      SchemaMetaData smd, DbTransaction transaction) async {
    if (_currentUserId == null) {
      ConfigurationDao configurationDao =
          ConfigurationDao(smd, transaction, _defaults);
      await configurationDao.init(initTable: true);
      try {
        _currentUserId = await configurationDao.getInteger(
            0, WardenType.USER, ConfigurationNameEnum.USER_ID);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
          throw SqlException.renew(e,
              cause: "USER-ID is not set in configuration table");
        else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          print("WS $e");
        else
          rethrow;
      }
    }
    return _currentUserId;
  }

  Future<void> setCurrentUserId(
      SchemaMetaData smd, DbTransaction transaction, int cuId) async {
    _currentUserId = null;
    ConfigurationDao configurationDao =
        ConfigurationDao(smd, transaction, _defaults);
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
        _defaults);
    try {
      await configurationDao.setConfigurationDto(configurationDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      } else
        rethrow;
    }
    clearConfigurationCache();
  }

  Future<UserDto?> getCurrentUserDto(
      SchemaMetaData smd, DbTransaction transaction) async {
    if (_currentUserDto == null) {
      UserDao userDao = UserDao(smd, transaction);
      await userDao.init(initTable: true);
      try {
        int? cuid = await getCurrentUserId(smd, transaction);
        _currentUserDto = await userDao.getUserDtoById(cuid!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          print("WS $e");
        else
          rethrow;
      }
    }
    return _currentUserDto;
  }

  Future<UserStoreDto?> getCurrentUserStoreDto(
      SchemaMetaData smd, DbTransaction transaction) async {
    if (_currentUserStoreDto == null) {
      UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
      await userStoreDao.init(initTable: true);
      try {
        int? cuid = await getCurrentUserId(smd, transaction);
        _currentUserStoreDto = await userStoreDao.getUserStoreDtoById(cuid!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          print("WS $e");
        else
          rethrow;
      }
    }
    return _currentUserStoreDto;
  }

  Future<void> setCurrentUserDto(
      SchemaMetaData smd, DbTransaction transaction, UserDto userDto) async {
    _currentUserDto = null;
    _currentUserId = null;
    UserDao userDao = UserDao(smd, transaction);
    await userDao.init(initTable: true);
    int? cuId = null;
    try {
      cuId = await getCurrentUserId(smd, transaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        await setCurrentUserId(smd, transaction, userDto.id!);
    }
    if (cuId == null || cuId == userDto.id) {
      await userDao.setUserDto(userDto);
    } else {
      // User Id has been updated so remove old entry and rewrite
      try {
        await userDao.deleteUserById(cuId);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) print("$e");
      }
      await setCurrentUserId(smd, transaction, userDto.id!);
      await userDao.setUserDto(userDto);
    }
  }

  Future<void> setCurrentUserStoreDto(SchemaMetaData smd,
      DbTransaction transaction, UserStoreDto userStoreDto) async {
    _currentUserStoreDto = null;
    int? cuId;
    UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
    await userStoreDao.init(initTable: true);
    try {
      UserStoreDto existingUserStoreDto =
          await userStoreDao.getUserStoreDtoByUnique(userStoreDto.email!);
      cuId = existingUserStoreDto.id;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }

    if (cuId == null || cuId == userStoreDto.id) {
      await userStoreDao.setUserStoreDto(userStoreDto);
    } else {
      // User Id has been updated so remove old entry and rewrite
      await userStoreDao.deleteUserStoreById(cuId);
      await userStoreDao.setUserStoreDto(userStoreDto);
    }
  }

  Future<bool> isUserRegistered(
      SchemaMetaData smd, DbTransaction transaction) async {
    try {
      int? cuid = await getCurrentUserId(smd, transaction);
      if (cuid! > 1) return true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }
    return false;
  }

  Future<UserDto> getUserDto(
      SchemaMetaData smd, DbTransaction transaction, int id) async {
    UserDao userDao = UserDao(smd, transaction);
    await userDao.init(initTable: true);
    return await userDao.getUserDtoById(id);
  }

  Future<UserStoreDto?> getUserStoreDto(
      SchemaMetaData smd, DbTransaction transaction, int id) async {
    UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
    await userStoreDao.init(initTable: true);
    UserStoreDto? userStoreDto;
    try {
      userStoreDto = await userStoreDao.getUserStoreDtoById(id);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        print("WS $e");
      else
        rethrow;
    }
    return userStoreDto;
  }

  void clearUserCache() {
    _currentUserId = null;
    _currentUserDto = null;
    _currentUserStoreDto = null;
  }

// --------------------------------------------------------------------------------------------- WARDEN

  Future<WardenType?> getWardenType(
      SchemaMetaData smd, DbTransaction transaction) async {
    WardenType? wardenType;
    try {
      UserDto? userDto = await getCurrentUserDto(smd, transaction);
      wardenType = userDto!.warden;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        wardenType = WardenType.USER;
      ;
    }
    return wardenType;
  }

  Future<bool> isUser(SchemaMetaData smd, DbTransaction transaction) async {
    return (await getWardenType(smd, transaction)) == WardenType.USER;
  }

  Future<bool> isAdmin(SchemaMetaData smd, DbTransaction transaction) async {
    return (await getWardenType(smd, transaction)) == WardenType.ADMIN;
  }

// --------------------------------------------------------------------------------------------- CONFIGURATION

  void clearConfigurationCache() {
    _configurationTable = Map();
  }

  Future<SimpleEntry?> _cacheConfigurationTable(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum) async {
    SimpleEntry? simpleEntry;
    if (!_configurationTable.containsKey(configurationNameEnum)) {
      ConfigurationDao configurationDao =
          ConfigurationDao(smd, transaction, _defaults);
      await configurationDao.init(initTable: true);
      try {
        UserDto? userDto = await getCurrentUserDto(smd, transaction);
        int? subset = userDto!.subset;
        WardenType? warden = await getWardenType(smd, transaction);
        simpleEntry = await configurationDao.getEntry(
            subset, warden, configurationNameEnum);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("WS $e");
        } else if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
          try {
            simpleEntry = await configurationDao.getEntry(0,
                await getWardenType(smd, transaction), configurationNameEnum);
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
              print("WS $e");
            } else if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
              simpleEntry = _defaults
                  .getConfigurationNameStruct(configurationNameEnum)
                  .defaultValues;
            }
          } finally {
            _configurationTable[configurationNameEnum] = simpleEntry!;
          }
        }
      }
    } else {
      simpleEntry = _configurationTable[configurationNameEnum];
    }
    return simpleEntry;
  }

  Future<SimpleEntry?> getConfigurationEntry(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum) async {
    SimpleEntry? simpleEntry;
    try {
      simpleEntry = await _cacheConfigurationTable(
          smd, transaction, configurationNameEnum);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
    }
    return simpleEntry;
  }

  Future<int?> getConfigurationInteger(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum) async {
    SimpleEntry? simpleEntry =
        await getConfigurationEntry(smd, transaction, configurationNameEnum);
    return simpleEntry!.intValue;
  }

  Future<bool?> getConfigurationBoolean(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum) async {
    bool? valueBoolean;

    SimpleEntry? simpleEntry =
        await getConfigurationEntry(smd, transaction, configurationNameEnum);
    int? valueInteger = simpleEntry!.intValue;
    if (valueInteger != null) {
      valueBoolean = false;
      if (valueInteger == 1) valueBoolean = true;
    }
    return valueBoolean;
  }

  Future<String?> getConfigurationString(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum) async {
    SimpleEntry? simpleEntry =
        await getConfigurationEntry(smd, transaction, configurationNameEnum);
    return simpleEntry!.stringValue;
  }

  Future<void> setConfigurationInteger(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum,
      int valueInteger) async {
    ConfigurationDao configurationDao =
        ConfigurationDao(smd, transaction, _defaults);
    await configurationDao.init(initTable: true);
    try {
      WardenType? wardenType = await getWardenType(smd, transaction);
      await configurationDao.setInteger(
          0, wardenType!, configurationNameEnum, valueInteger);
      _configurationTable.remove(configurationNameEnum);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("WS $e");
    }
  }

  Future<void> setConfigurationBoolean(
      SchemaMetaData smd,
      DbTransaction transaction,
      ConfigurationNameEnum configurationNameEnum,
      bool valueBoolean) async {
    await setConfigurationInteger(
        smd, transaction, configurationNameEnum, valueBoolean == true ? 1 : 0);
  }

// --------------------------------------------------------------------------------------------- TIME
  Future<int> getServerCurrentTs(
      SchemaMetaData smd, DbTransaction transaction) async {
    int? serverTimeOffset = await getConfigurationInteger(
        smd, transaction, ConfigurationNameEnum.SERVER_TIME_OFFSET);
    int currentTs = TimeUtils.getNowCustomTs();
    return currentTs + serverTimeOffset!;
  }

  Future<void> storeServerTimeOffset(SchemaMetaData smd,
      DbTransaction transaction, int currentTs, int serverTs) async {
    bool inRange = false;
    int timeDifference = serverTs - currentTs;
    int serverTimeOffset = await getConfigurationInteger(
        smd, transaction, ConfigurationNameEnum.SERVER_TIME_OFFSET) as int;
    if ((timeDifference > (serverTimeOffset - _C_SLACK_SECS)) &&
        (timeDifference < (serverTimeOffset + _C_SLACK_SECS))) inRange = true;
    if (!inRange) {
      await setConfigurationInteger(smd, transaction,
          ConfigurationNameEnum.SERVER_TIME_OFFSET, timeDifference);
    }
    print(
        "currentTs=$currentTs||serverTs=$serverTs||diff=$timeDifference||stored offset=$serverTimeOffset");
  }

  Future<int?> getTargetOffsetSecs(
      SchemaMetaData smd, DbTransaction transaction) async {
    int? targetOffsetSecs;
    try {
      UserDto? userDto = await getCurrentUserDto(smd, transaction);
      targetOffsetSecs = userDto!.request_offset_secs;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        targetOffsetSecs = NumberUtils.randInt(0, TimeUtils.C_SECS_IN_DAY);
      }
    }
    return targetOffsetSecs;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("_currentUserId=$_currentUserId||");
    sb.write("_currentUserStoreDto=$_currentUserStoreDto||");
    sb.write("_configurationTable=$_configurationTable||");
    sb.write("_defaults=$_defaults");
    return sb.toString();
  }
}
