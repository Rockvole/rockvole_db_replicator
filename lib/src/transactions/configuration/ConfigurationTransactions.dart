import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class ConfigurationTransactions extends TableTransactions {
  late ConfigurationDao configurationDao;
  late ConfigurationTrDao configurationTrDao;

  ConfigurationTransactions.sep(TrDto trDto) : super.sep(trDto);
  Future<void> init(WardenType? localWardenType, WardenType? remoteWardenType,
      SchemaMetaData? smd, SchemaMetaData smdSys, DbTransaction transaction,
      {FieldData? fieldData, ConfigurationNameDefaults? defaults}) async {
    if (defaults == null)
      throw ArgumentError(AbstractTableTransactions.C_MUST_PASS_DEFAULTS);
    await super.init(
        localWardenType, remoteWardenType, smd, smdSys, transaction,
        fieldData: fieldData, defaults: defaults);
    configurationDao = ConfigurationDao(smd!, transaction, defaults);
    await configurationDao.init();
    configurationTrDao = ConfigurationTrDao(smdSys, transaction, defaults);
    await configurationTrDao.init();
  }

  @override
  Future<void> insert() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    await configurationDao.insert(trDto.getFieldDataNoTr);
  }

  @override
  Future<int?> add() {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    ConfigurationDto configurationDto = ConfigurationDto.field(trDto, defaults);
    return configurationDao.addConfiguration(
        configurationDto.subset,
        configurationDto.warden,
        configurationDto.configuration_name,
        configurationDto.ordinal,
        configurationDto.value_number,
        configurationDto.value_string);
  }

  @override
  Future<void> update() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    ConfigurationDto configurationDto = ConfigurationDto.field(trDto, defaults);
    await configurationDao.updateConfigurationDto(configurationDto);
    trDto.append(await find());
  }

  @override
  Future<DeletedRowsStruct> revert() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    DeletedRowsStruct struct = DeletedRowsStruct(trDto.ts!);
    switch (trDto.operation) {
      case OperationType.INSERT:
      case OperationType.UPDATE:
        await super.revert();
        break;
      case OperationType.DELETE:
        await configurationDao
            .setConfigurationDto(trDto.getFieldDataNoTr as ConfigurationDto);
        await deleteTrRowByTs(struct.ts!);
        break;
      case OperationType.SNAPSHOT:
        break;
    }
    return struct;
  }

  @override
  Future<void> forced_overwrite() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      ConfigurationDto configurationDto =
          ConfigurationDto.field(trDto, defaults);
      await configurationDao.deleteConfigurationByUnique(
          configurationDto.subset,
          configurationDto.warden,
          configurationDto.configuration_name,
          configurationDto.ordinal);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }
    trDto.set('id', null);
    trDto.append(await configurationDao.setConfigurationDto(
        ConfigurationDto.field(trDto.getFieldDataNoTr, defaults)));
  }

  @override
  Future<FieldData> find() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (trDto.get('id') == null) {
      ConfigurationDto configurationDto =
          ConfigurationDto.field(trDto, defaults);
      return configurationDao.getConfigurationDtoByUnique(
          configurationDto.subset,
          configurationDto.warden,
          configurationDto.configuration_name,
          configurationDto.ordinal);
    }
    return configurationDao.getConfigurationDtoById(trDto.get('id') as int);
  }

  @override
  Future<int?> findId() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    ConfigurationDto configurationDto = ConfigurationDto.field(trDto, defaults);
    return (await configurationDao.getConfigurationDtoByUnique(
            configurationDto.subset,
            configurationDto.warden,
            configurationDto.configuration_name,
            configurationDto.ordinal))
        .id;
  }

  @override
  Future<void> snapshot(FieldData fieldData, int ts, int user_ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    TrDto trDto = TrDto.sep(ts, OperationType.SNAPSHOT, 0, user_ts,
        "Configuration Snapshot", null, ConfigurationMixin.C_TABLE_ID,
        fieldData: fieldData);
    await configurationTrDao.setConfigurationTrDto(trDto as ConfigurationTrDto);
  }

  @override
  Future<ConfigurationTrDto?> writeHistoricalChanges(
      int ts, int? user_ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    trDto.ts = ts;
    trDto.user_ts = user_ts;
    return await configurationTrDao
        .setConfigurationTrDto(ConfigurationTrDto.field(trDto, defaults));
  }

  @override
  Future<void> modifyId(int originalId, int newId) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      ConfigurationDto configurationDto =
          await configurationDao.getConfigurationDtoById(newId);
      await delete(configurationDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
          e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT) rethrow;
    }
    await configurationDao.modifyId(originalId, newId);
    await configurationTrDao.modifyId(originalId, newId);
  }
}
