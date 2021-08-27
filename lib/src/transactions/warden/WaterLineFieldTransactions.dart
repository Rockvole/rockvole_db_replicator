import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class WaterLineFieldTransactions extends TableTransactions {
  late WaterLineFieldDao waterLineFieldDao;
  late WaterLineFieldDto waterLineFieldDto;
  late TrDto trWaterLineFieldDto;

  WaterLineFieldTransactions.sep(
      RemoteWaterLineFieldDto remoteWaterLineFieldDto) {
    super.sep(remoteWaterLineFieldDto.trDto);
    this.waterLineFieldDto = remoteWaterLineFieldDto.waterLineFieldDto;
    this.trWaterLineFieldDto = remoteWaterLineFieldDto.trDto;
  }

  Future<void> init(WardenType? localWardenType, WardenType? remoteWardenType,
      SchemaMetaData? smd, SchemaMetaData smdSys, DbTransaction transaction,
      {FieldData? fieldData, ConfigurationNameDefaults? defaults}) async {
    await super.init(
        localWardenType, remoteWardenType, null, smdSys, transaction,
        fieldData: fieldData);
    this.waterLineFieldDao = WaterLineFieldDao.sep(smdSys, transaction);
    await waterLineFieldDao.init(initTable: false);
  }

  @override
  Future<void> getTrDtoByUserTs(int ts) async {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> updateWaterLineField(
      {int? id, int? table_field_id, int? remote_ts}) async {
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        ChangeType.NOTIFY,
        WaterLineFieldDto.C_USER_ID_NONE,
        null,
        null,
        null,
        null,
        remote_ts,
        smdSys);
    await abstractFieldWarden.init(waterLineFieldDto);
    await abstractFieldWarden.write();
  }

  @override
  Future<int> nextId() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> insert() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<int> add() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> update() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> delete(FieldData? fieldData) {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> deleteTrRowByTs(int ts) {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<DeletedRowsStruct> revert() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> forced_overwrite() async {
    try {
      await updateWaterLineField(
          id: waterLineFieldDto.id,
          table_field_id: waterLineFieldDto.table_field_id,
          remote_ts: waterLineFieldDto.remote_ts);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
    }
  }

  @override
  Future<FieldData> find() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<int> findId() {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  Future<void> snapshot(FieldData fieldData, int ts, int userTs) {
    throw ArgumentError(AbstractDao.C_OPERATION_NOT_SUPPORTED);
  }

  @override
  int? getTs() => trWaterLineFieldDto.ts;

  @override
  void setTs(int? ts) => trWaterLineFieldDto.ts = ts;

  @override
  void setCrc(String? crc) {
    trWaterLineFieldDto.crc = CrcUtils.getCrcFromString(crc);
  }

  @override
  void setId(int id) {
    waterLineFieldDto.id = id;
    trWaterLineFieldDto.operation = OperationType.INSERT;
  }

  @override
  TrDto getTrDto() {
    return trWaterLineFieldDto;
  }

  @override
  Future<TrDto> writeHistoricalChanges(int ts, int? user_ts) async {
    trWaterLineFieldDto.ts = ts;
    trWaterLineFieldDto.user_ts = user_ts;
    return await trWaterLineFieldDto;
  }

  @override
  String toString() {
    return waterLineFieldDto.toString();
  }
}
