import 'package:meta/meta.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class DeletedRowsStruct {
  int? ts;
  late int snapshotTs;
  DeletedRowsStruct(this.ts);
}

abstract class AbstractTableTransactions {
  static final String C_MUST_PASS_DEFAULTS =
      "You must pass ConfigurationNameDefaults argument.";
  bool initialized = false;
  @protected
  late TrDto trDto;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late TableTransactionDao tableTransactionDao;
  late TableTransactionTrDao tableTransactionTrDao;
  SchemaMetaData? smd;
  late SchemaMetaData smdSys;
  late DbTransaction transaction;
  late AbstractFieldWarden abstractFieldWarden;
  ConfigurationNameDefaults? defaults;

  AbstractTableTransactions();
  AbstractTableTransactions.sep(this.trDto);
  AbstractTableTransactions.field(FieldData fieldData) {
    this.trDto = TrDto.field(fieldData);
  }
  void sep(TrDto trDto) {
    this.trDto = trDto;
  }

  Future<void> init(WardenType? localWardenType, WardenType? remoteWardenType,
      SchemaMetaData? smd, SchemaMetaData smdSys, DbTransaction transaction,
      {FieldData? fieldData, ConfigurationNameDefaults? defaults}) async {
    initialized = true;
    if (localWardenType == WardenType.ADMIN &&
        remoteWardenType == WardenType.ADMIN) {
      if (trDto.operation == OperationType.UPDATE) {
        if (trDto.id == null)
          throw IllegalStateException("id must not be null");
      }
    }
    this.localWardenType = localWardenType;
    this.remoteWardenType = remoteWardenType;
    this.smd = smd;
    this.smdSys = smdSys;
    if (smd != null) {
      tableTransactionDao = TableTransactionDao(smd, transaction);
      await tableTransactionDao.init(table_id: trDto.table_id, initTable: true);
    }
    tableTransactionTrDao = TableTransactionTrDao(smdSys, transaction);
    await tableTransactionTrDao.init(table_id: trDto.table_id, initTable: true);
    abstractFieldWarden = AbstractFieldWarden(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    this.defaults = defaults;
  }

  get table_id => trDto.table_id;

  void validateTrDto(TrDto trDto) {
    if (trDto.id == null && trDto.operation == OperationType.DELETE)
      throw ArgumentError("Id must not be null for Delete");
  }

  Future<void> updateWaterLineField(
      {int id, int table_field_id, int remote_ts});
  Future<int?> nextId();
  Future<void> getTrDtoByUserTs(int ts);
  OperationType? getOperationType();
  void setOperationType(OperationType? operation);
  int getMinIdForUser();
  Future<void> insert();
  Future<int?> add();
  Future<void> update();
  Future<void> delete(FieldData? fieldData);
  Future<void> deleteTrRowByTs(int ts);
  Future<void> deleteChildren();
  Future<DeletedRowsStruct> revert();
  Future<void> forced_overwrite();
  Future<FieldData> find();
  Future<int?> findId();
  Future<void> snapshot(FieldData fieldData, int ts, int user_ts);
  int? getTs();
  void setTs(int? ts);
  String? getJoinCrcString() {
    return null;
  }

  void setCrc(String? crc);
  void setId(int id);
  TrDto getTrDto();
  Future<void> getChangesFromDto() async { return null; }
  Future<TrDto?> writeHistoricalChanges(int ts, int? user_ts);
  Future<int?> getChangeTypeValue(ChangeType change_type);
  void setChangeTypeValue(ChangeType change_type, int value);
  void modifyChangeTypeValue(ChangeType change_type, int? value);
  Future<void> modifyId(int original_id, int new_id);
  Future<void> modifyJoinIds(int original_id, int new_id);
}
