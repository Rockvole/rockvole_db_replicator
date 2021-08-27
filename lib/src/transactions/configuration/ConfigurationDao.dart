import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class ConfigurationDao extends AbstractTransactionDao {
  ConfigurationNameDefaults defaults;
  ConfigurationDao(SchemaMetaData smd, DbTransaction transaction, this.defaults)
      : super.sep(smd, transaction);

  @override
  Future<bool> init(
      {int? table_id,
      bool initTable = true}) async {
    bool wasInitialized = await super
        .init(table_id: ConfigurationMixin.C_TABLE_ID, initTable: initTable);
    return wasInitialized;
  }

  Future<bool> insertDefaultValues() async {
    ConfigurationDto configurationDto;
    bool updateConfigTable=!(await doesTableExist());
    if(updateConfigTable) {
      await initializeTable();
      print(sqlCommands.dbType.toString() +
          " Inserting Default Values for Configuration Table");
      try {
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.HOME_COUNTRY_ONLY,
            0,
            0,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.FIELDS_NEXT_SYNC_CHANGES_TS,
            0,
            null,
            null,
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.FIELDS_SYNC_INTERVAL_MINS,
            0,
            6,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.READ_SERVER_URL,
            0,
            UrlTools.C_SERVER_PORT,
            UrlTools.C_SERVER_ADDRESS,
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.READ_SERVER_URL,
            1,
            UrlTools.C_SERVER_PORT,
            UrlTools.C_SERVER_ADDRESS,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_LIMIT,
            0,
            100,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_NEXT_SYNC_CHANGES_TS,
            0,
            null,
            null,
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_SYNC_INTERVAL,
            0,
            0,
            "Manual",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_SYNC_INTERVAL,
            1,
            720,
            "12 Hours",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_SYNC_INTERVAL,
            2,
            1440,
            "1 Day",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.ROWS_SYNC_INTERVAL_MINS,
            0,
            1440,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SEND_CHANGES_DELAY,
            0,
            120,
            "2 Hours",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SEND_CHANGES_DELAY,
            1,
            360,
            "6 Hours",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SEND_CHANGES_DELAY,
            2,
            1440,
            "1 Day",
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SEND_CHANGES_DELAY_MINS,
            0,
            120,
            null,
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SEND_CHANGES_DELAY_OPTS,
            0,
            0,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SERVER_TIME_OFFSET,
            0,
            0,
            null,
            defaults);
        await insertDto(configurationDto);
        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.SYNC_WIFI_ONLY,
            0,
            1,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.USER_ID,
            0,
            1,
            null,
            defaults);
        await insertDto(configurationDto);

        configurationDto = ConfigurationDto.sep(
            null,
            0,
            WardenType.USER,
            ConfigurationNameEnum.WRITE_SERVER_URL,
            0,
            UrlTools.C_SERVER_PORT,
            UrlTools.C_SERVER_ADDRESS,
            defaults);
        await insertDto(configurationDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print(
            "DB $e");
      }
    }
    return updateConfigTable;
  }

  Future<int?> addConfiguration(
      int? subset,
      WardenType? wardenType,
      ConfigurationNameEnum? configurationName,
      int? ordinal,
      int? valueNumber,
      String? valueString) async {
    ConfigurationDto configurationDto = ConfigurationDto.sep(
        null,
        subset,
        wardenType,
        configurationName,
        ordinal,
        valueNumber,
        valueString,
        defaults);
    int? id = await this.insertDto(configurationDto);
    return id;
  }

  List<WardenType>? getWardenList(WardenType? wardenType) {
    List<WardenType>? wardenList;
    if (wardenType != null) {
      wardenList = [];
      switch (wardenType) {
        // If a configuration is not found, fall back to another acceptable type
        case WardenType.WRITE_SERVER:
          wardenList.add(WardenType.WRITE_SERVER);
          wardenList.add(WardenType.READ_SERVER);
          wardenList.add(WardenType.ADMIN);
          wardenList.add(WardenType.USER);
          break;
        case WardenType.READ_SERVER:
          wardenList.add(WardenType.READ_SERVER);
          wardenList.add(WardenType.ADMIN);
          wardenList.add(WardenType.USER);
          break;
        case WardenType.ADMIN:
          wardenList.add(WardenType.ADMIN);
          wardenList.add(WardenType.USER);
          break;
        case WardenType.USER:
          wardenList.add(WardenType.USER);
          break;
      }
    }
    return wardenList;
  }

  @override
  Future<RawTableData> select(FieldData fieldData, WhereData whereData) async {
    //fieldData ??= ConfigurationDto.getSelectFieldData();
    return await super.select(fieldData, whereData);
  }

  Future<List<ConfigurationDto>> _getConfigurationList(
      int? id,
      int? subset,
      List<WardenType>? wardenList,
      ConfigurationNameEnum? configurationName,
      int? ordinal,
      SortOrderType? sortOrderType,
      bool? oldestTs) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (oldestTs == null) oldestTs = false;
    FieldData fieldData = ConfigurationDto.getSelectFieldData();
    WhereData whereData = WhereData();
    if (id == null) {
      whereData.set('subset', SqlOperator.EQUAL, subset);
      if (wardenList != null) {
        List<int> wardenIntList = [];
        wardenList.forEach((wt) {
          wardenIntList.add(Warden.getWardenValue(wt)!);
        });
        whereData.set('warden', SqlOperator.IN, wardenIntList);
      }
      if (configurationName != null)
        whereData.set('configuration_name', SqlOperator.EQUAL,
            defaults.getConfigurationNameStruct(configurationName).name);
      whereData.set('ordinal', SqlOperator.EQUAL, ordinal);
    } else {
      whereData.set('id', SqlOperator.EQUAL, id);
    }
    if (oldestTs) whereData.limit = 1;
    String sql = sqlCommands.select(fieldData, whereData);

    if (sortOrderType == null)
      sql += " ORDER BY ordinal, warden";
    else
      sql += getSortOrderString(sortOrderType, null);
    print(sql);
    RawTableData rawTableData = await bareSelect(sql, fieldData);
    List<ConfigurationDto> list = [];
    rawTableData.getRawRows().forEach((rrd) {
      list.add(ConfigurationDto.field(rrd.getFieldData(), defaults));
    });
    return list;
  }

  Future<ConfigurationDto> _getConfigurationDto(
      int? subset,
      WardenType? wardenType,
      ConfigurationNameEnum? configurationName,
      int? ordinal,
      {int? id}) async {
    List<WardenType>? wardenList = getWardenList(wardenType);
    List<ConfigurationDto> list = await _getConfigurationList(
        id, subset, wardenList, configurationName, ordinal, null, null);
    return list[0];
  }

  Future<ConfigurationDto> getConfigurationDtoById(int id) async {
    return await _getConfigurationDto(null, null, null, null, id: id);
  }

  Future<ConfigurationDto> getConfigurationDtoByUnique(
      int? subset,
      WardenType? wardenType,
      ConfigurationNameEnum? configurationName,
      int? ordinal) async {
    return await this
        ._getConfigurationDto(subset, wardenType, configurationName, ordinal);
  }

  Future<ConfigurationDto> updateConfigurationDto(
      ConfigurationDto configurationDto) async {
    ConfigurationTrDto configurationTrDto = ConfigurationTrDto.wee(configurationDto, null, defaults);
    ConfigurationTrDao configurationTrDao =
        ConfigurationTrDao(smd, transaction, defaults);
    configurationTrDto =
        await configurationTrDao.updateConfigurationTrDto(configurationTrDto);
    return configurationTrDto.getFieldDataNoTr as ConfigurationDto;
  }

  Future<ConfigurationDto> setString(
      int subset,
      WardenType wardenType,
      ConfigurationNameEnum configurationNameEnum,
      String valueString,
      ConfigurationNameDefaults defaults) async {
    ConfigurationDto configurationDto = ConfigurationDto.sep(null, subset,
        wardenType, configurationNameEnum, 0, null, valueString, defaults);
    return setConfigurationDto(configurationDto);
  }

  Future<String?> getString(int subset, WardenType wardenType,
      ConfigurationNameEnum configurationName) async {
    ConfigurationDto configurationDto;
    String? value = null;
    configurationDto =
        await _getConfigurationDto(subset, wardenType, configurationName, 0);
    value = configurationDto.value_string;
    return value;
  }

  Future<int?> getInteger(int subset, WardenType? wardenType,
      ConfigurationNameEnum configurationName) async {
    ConfigurationDto configurationDto = await this
        ._getConfigurationDto(subset, wardenType, configurationName, 0);
    return configurationDto.value_number;
  }

  Future<SimpleEntry> getEntry(int? subset, WardenType? wardenType,
      ConfigurationNameEnum configurationName) async {
    ConfigurationDto configurationDto;
    SimpleEntry simpleEntry;
    configurationDto =
        await _getConfigurationDto(subset, wardenType, configurationName, 0);
    simpleEntry = SimpleEntry(
        configurationDto.value_number, configurationDto.value_string);
    return simpleEntry;
  }

  Future<ConfigurationDto> setConfigurationDto(
      ConfigurationDto configurationDto) async {
    int? id = configurationDto.id;
    id = getConfigurationId(configurationDto.subset, configurationDto.warden,
        configurationDto.configuration_name, configurationDto.ordinal, defaults);
    configurationDto.id = id;
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    RawRowData rawRowData = await upsert(configurationDto, whereData);
    return ConfigurationDto.field(rawRowData.getFieldData(), defaults);
  }

  Future<ConfigurationDto> setInteger(int subset, WardenType wardenType,
      ConfigurationNameEnum configurationName, int valueNumber) async {
    ConfigurationDto configurationDto = ConfigurationDto.sep(null, subset,
        wardenType, configurationName, 0, valueNumber, null, defaults);
    return await setConfigurationDto(configurationDto);
  }

  static int getConfigurationId(int? subset, WardenType? wardenType,
      ConfigurationNameEnum? configurationNameEnum, int? ordinal, ConfigurationNameDefaults defaults) {
    ConfigurationNameStruct struct =
        defaults.getConfigurationNameStruct(configurationNameEnum!);
    // configuration_name
    if (configurationNameEnum == null)
      throw ArgumentError("configuration_name must not be null");
    if (struct.id <= 0)
      throw ArgumentError("configuration_name must be above 0");
    if (struct.id > 999)
      throw ArgumentError("configuration_name must be below 1000");
    // warden
    int? wardenTypeInt = Warden.getWardenValue(wardenType);
    if (wardenType == null) throw ArgumentError("warden_type must not be null");
    if (wardenTypeInt! < 0)
      throw ArgumentError("warden_type must not be negative");
    if (wardenTypeInt > 9) throw ArgumentError("warden_type must be below 10");
    // subset
    if (subset == null) throw ArgumentError("subset must not be null");
    if (subset < 0) throw ArgumentError("subset must not be negative");
    if (subset > 99) throw ArgumentError("subset must be below 100");
    // ordinal
    if (ordinal == null) throw ArgumentError("ordinal must not be null");
    if (ordinal < 0) throw ArgumentError("ordinal must not be negative");
    if (ordinal > 99) throw ArgumentError("ordinal must be below 100");
    // calculate id
    int id = struct.id * 100000;
    if (wardenTypeInt > 0) id = id + (wardenTypeInt * 10000);
    if (subset > 0) id = id + (subset * 100);
    id = id + ordinal;
    return id;
  }

  Future<ConfigurationDto> deleteConfigurationByUnique(
      int? subset,
      WardenType? wardenType,
      ConfigurationNameEnum? configurationName,
      int? ordinal) async {
    int id = getConfigurationId(subset, wardenType, configurationName, ordinal, defaults);
    ConfigurationDto configurationDto = ConfigurationDto.sep(id, subset,
        wardenType, configurationName, ordinal, null, null, defaults);

    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await super.delete(whereData);
    return configurationDto;
  }

  Future<int?> insertDto(ConfigurationDto configurationDto) async {
    int? id = configurationDto.id;
    id = getConfigurationId(configurationDto.subset, configurationDto.warden,
        configurationDto.configuration_name, configurationDto.ordinal, defaults);
    configurationDto.id = id;
    return insert(configurationDto);
  }
}
