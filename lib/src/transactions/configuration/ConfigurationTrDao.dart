import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class ConfigurationTrDao extends AbstractTransactionTrDao {
  ConfigurationNameDefaults defaults;
  ConfigurationTrDao(
      SchemaMetaData smdSys, DbTransaction transaction, this.defaults)
      : super(smdSys, transaction);
  @override
  Future<void> init({int? table_id, bool initTable = true}) async {
    await super
        .init(table_id: ConfigurationMixin.C_TABLE_ID, initTable: initTable);
  }

  @override
  TrDto validateTrDto(TrDto trDto, OperationType operationType) {
    ConfigurationTrDto configurationTrDto =
        super.validateTrDto(trDto, operationType) as ConfigurationTrDto;
    if (operationType == OperationType.INSERT) {
      if (configurationTrDto.configuration_name == null)
        throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
            cause: "ConfigurationDao: ConfigurationName must be passed.");
      if (configurationTrDto.id != null) throw ArgumentError("id must be null");
    }
    return configurationTrDto;
  }

  Future<ConfigurationTrDto> updateConfigurationTrDto(
      ConfigurationTrDto configurationTrDto) async {
    validateTrDto(configurationTrDto, OperationType.UPDATE);

    bool identifyingFieldsPassed = false;
    bool setIdentifyingFields = false;
    if (configurationTrDto.subset != null &&
        configurationTrDto.warden != null &&
        configurationTrDto.configuration_name != null &&
        configurationTrDto.ordinal != null) identifyingFieldsPassed = true;

    if (smdSys.isSystem) {
      setIdentifyingFields = true;
    } else if (configurationTrDto.id != null) {
      setIdentifyingFields = true;
    } else if (!identifyingFieldsPassed) {
      throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
          cause:
              "must pass either id or SubSet, WardenType, ConfigurationName and Ordinal");
    }
    FieldData fieldData = FieldData.wee(ConfigurationMixin.C_TABLE_ID);
    fieldData.set("id", configurationTrDto.id);
    if (setIdentifyingFields) {
      if (configurationTrDto.subset != null)
        fieldData.set("subset", configurationTrDto.subset);

      if (configurationTrDto.warden != null)
        fieldData.set(
            "warden", Warden.getWardenValue(configurationTrDto.warden));

      if (configurationTrDto.configuration_name != null)
        fieldData.set(
            "configuration_name",
            defaults
                .getConfigurationNameStruct(
                    configurationTrDto.configuration_name!)
                .name);

      if (configurationTrDto.ordinal != null)
        fieldData.set("ordinal", configurationTrDto.ordinal);
    }
    fieldData.set("value_number", configurationTrDto.value_number);
    fieldData.set("value_string", configurationTrDto.value_string);

    fieldData = getTrSet(fieldData, configurationTrDto.getTrDto);
    WhereData whereData = WhereData();
    if (smdSys.isSystem) {
      if (configurationTrDto.ts == null)
        throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
            cause: "ts must not be null");
      whereData.set("ts", SqlOperator.EQUAL, configurationTrDto.ts);
    } else {
      whereData.set("id", SqlOperator.EQUAL, configurationTrDto.id);
      if (configurationTrDto.id == null) {
        whereData.set("subset", SqlOperator.EQUAL, configurationTrDto.subset);
        whereData.set("warden", SqlOperator.EQUAL,
            Warden.getWardenValue(configurationTrDto.warden));
        whereData.set(
            "configuration_name",
            SqlOperator.EQUAL,
            defaults
                .getConfigurationNameStruct(
                    configurationTrDto.configuration_name!)
                .name);
        whereData.set("ordinal", SqlOperator.EQUAL, configurationTrDto.ordinal);
      }
    }
    try {
      await super.updateTR(configurationTrDto, fieldData, whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND) rethrow;
    }
    return configurationTrDto;
  }

  Future<int?> insertDto(ConfigurationTrDto configurationTrDto) async {
    return insert(configurationTrDto);
  }

  Future<ConfigurationTrDto> insertConfigurationTrDto(
      ConfigurationTrDto configurationTrDto) async {
    int id = ConfigurationDao.getConfigurationId(
        configurationTrDto.subset,
        configurationTrDto.warden,
        configurationTrDto.configuration_name,
        configurationTrDto.ordinal,
        defaults);
    configurationTrDto.id = id;
    await insertDto(configurationTrDto);
    return configurationTrDto;
  }

  Future<ConfigurationTrDto> getConfigurationTrDtoByTs(ts) async {
    RawRowData rawRowData = await getRawRowDataByTs(ts);
    return ConfigurationTrDto.field(rawRowData.getFieldData(), defaults);
  }

  Future<List<ConfigurationTrDto>> getConfigurationTrList(
      int? id,
      int? subset,
      List<WardenType>? wardenList,
      ConfigurationNameEnum? configurationName,
      int? ordinal,
      int? ts,
      OperationType? operationType,
      int? userId,
      int? userTs,
      String? comment,
      bool? oldestTs) async {
    FieldData fieldData = ConfigurationTrDto.getSelectFieldData();
    TrDto trDto = TrDto.sep(ts, operationType, userId, userTs, comment, null,
        ConfigurationMixin.C_TABLE_ID,
        fieldData: fieldData);
    ConfigurationTrDto configurationTrDto = ConfigurationTrDto.sep(
        id, subset, null, configurationName, ordinal, null, null, trDto, defaults);
    WhereData whereData = configurationTrDto.getWhereData();

    RawTableData rawTableData = await selectTR(whereData, fieldData: trDto);
    List<ConfigurationTrDto> configurationTrDtoList = [];
    List<RawRowData> list = rawTableData.getRawRows();
    list.forEach((RawRowData rrd) {
      FieldData fieldData=FieldData.rawRowData(rrd, ConfigurationMixin.C_TABLE_ID);
      configurationTrDtoList.add(ConfigurationTrDto.field(fieldData, defaults));
    });
    return configurationTrDtoList;
  }

  Future<ConfigurationTrDto?> setConfigurationTrDto(
      ConfigurationTrDto configurationTrDto) async {
    int? id = configurationTrDto.id;
    if (!smdSys.isSystem) {
      if (id != null) throw ArgumentError("id must be null");
      ConfigurationDto configurationDto =
          ConfigurationDto.field(configurationTrDto, defaults);
      id = ConfigurationDao.getConfigurationId(
          configurationDto.subset,
          configurationDto.warden,
          configurationDto.configuration_name,
          configurationDto.ordinal,
          defaults);
      configurationTrDto.id = id;
    }
    ConfigurationTrDto? retConfigurationTrDto;
    try {
      await getConfigurationTrList(id, null, null, null, null,
          configurationTrDto.ts, null, null, null, null, null);
      retConfigurationTrDto =
          await updateConfigurationTrDto(configurationTrDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        configurationTrDto.id = null;
        retConfigurationTrDto =
            await insertConfigurationTrDto(configurationTrDto);
      }
    }
    return retConfigurationTrDto;
  }
}
