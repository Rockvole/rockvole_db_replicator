import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class TableTransactions extends AbstractTableTransactions {
  TableTransactions();
  TableTransactions.sep(TrDto trDto) : super.sep(trDto);
  TableTransactions.field(FieldData fieldData)
      : super.field(fieldData);

  @override
  Future<void> updateWaterLineField(
      {int? id, int? table_field_id, int? remote_ts}) async {}

  @override
  Future<int?> nextId() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      return await tableTransactionDao.getNextId(localWardenType!);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) return 1;
    }
    return null;
  }

  @override
  Future<void> getTrDtoByUserTs(int ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    RawTableData rawTableData = await tableTransactionTrDao.getTrList(
        ts, null, null, null, null, null, null, null, null);
    trDto = TrDto.field(rawTableData.getRawRowData(0).getFieldData());
  }

  @override
  OperationType? getOperationType() => trDto.operation;

  @override
  void setOperationType(OperationType? operation) => trDto.operation = operation;

  @override
  int getMinIdForUser() {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return tableTransactionDao.getMinIdForUser;
  }

  @override
  Future<void> insert() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    await tableTransactionDao.insert(trDto.getFieldDataNoTr);
  }

  @override
  Future<int?> add() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? id;
    // If lwt=WRITE && rwt=WRITE then we allow forcing an id (there may be gaps in user_store)
    if (trDto.table_id == UserStoreMixin.C_TABLE_ID &&
        localWardenType == WardenType.WRITE_SERVER &&
        remoteWardenType == WardenType.WRITE_SERVER) {
      id = trDto.id;
      await insert();
    } else {
      id = await tableTransactionDao.add(
          trDto.getFieldDataNoTr, localWardenType!);
    }
    return id;
  }

  @override
  Future<void> update() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    FieldData fieldData = trDto.getFieldDataNoTr;
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, fieldData.get('id'));
    await tableTransactionDao.update(fieldData, whereData);
    trDto.append(await find());
  }

  @override
  Future<void> delete(FieldData? fieldData) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (fieldData != null) trDto.append(fieldData);
    await tableTransactionDao.deleteById(trDto.id!);
  }

  @override
  Future<void> deleteTrRowByTs(int ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    await tableTransactionTrDao.deleteByTs(ts);
  }

  @override
  Future<void> deleteChildren() async {
    // Delete children of this table
    return await null;
  }

  @override
  Future<DeletedRowsStruct> revert() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    DeletedRowsStruct struct = DeletedRowsStruct(trDto.ts);
    switch (trDto.operation) {
      case OperationType.INSERT:
        await delete(null);
        await deleteTrRowByTs(struct.ts!);
        break;
      case OperationType.UPDATE:
        await delete(null);
        await deleteTrRowByTs(struct.ts!);
        RawTableData snapShotRtd = await tableTransactionTrDao.getTrList(
            null,
            OperationType.SNAPSHOT,
            0,
            trDto.user_ts,
            null,
            null,
            null,
            null,
            null);
        RawRowData snapShotRd = snapShotRtd.getRawRowData(0);
        FieldData snapShotFd =
            TransactionTools.removeTrFieldData(snapShotRd.getFieldData());
        await tableTransactionDao.upsert(snapShotFd, WhereData());
        struct.snapshotTs = snapShotRd.get("ts", null) as int;
        await tableTransactionTrDao.deleteByTs(struct.snapshotTs);
        break;
      case OperationType.DELETE:
        await tableTransactionDao.upsert(trDto, WhereData());
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
    FieldData fieldData = trDto.getFieldDataNoTr;
    WhereData whereData = WhereData();
    try {
      whereData = DataTools.appendWhereDataWithUniqueKeys(
          fieldData, WhereData(), smd!);
      await tableTransactionDao.delete(whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }
    await tableTransactionDao.upsert(fieldData, whereData);
  }

  @override
  Future<FieldData> find() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return (await tableTransactionDao.getById(trDto.id!)).getFieldData();
  }

  @override
  Future<int?> findId() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return await tableTransactionDao.getByUnique(trDto.getFieldDataNoTr);
  }

  @override
  Future<void> snapshot(FieldData fieldData, int ts, int user_ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    TrDto lTrDto = TrDto.field(fieldData);
    lTrDto.ts = ts;
    lTrDto.operation = OperationType.SNAPSHOT;
    lTrDto.user_id = 0;
    lTrDto.user_ts = user_ts;
    lTrDto.comment = "${tableTransactionDao.tableName} table Snapshot";
    lTrDto.crc = null;
    await tableTransactionTrDao.upsertTR(
        lTrDto, lTrDto.getFieldDataNoTr, WhereData());
  }

  @override
  int? getTs() => trDto.ts;

  @override
  void setTs(int? ts) => trDto.ts = ts;

  @override
  void setCrc(String? crc) {
    trDto.crc = CrcUtils.getCrcFromString(crc);
  }

  @override
  void setId(int id) {
    trDto.id = id;
    trDto.operation = OperationType.INSERT;
  }

  @override
  TrDto getTrDto() => trDto;

  @override
  Future<TrDto?> writeHistoricalChanges(int ts, int? user_ts) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    TrDto lTrDto = TrDto.wee(trDto.table_id);
    lTrDto.ts = ts;
    lTrDto.user_ts = user_ts;
    RawRowData rawRowData =
        await tableTransactionTrDao.upsertTR(lTrDto, trDto, WhereData());
    return TrDto.field(rawRowData.getFieldData());
  }

  @override
  Future<int?> getChangeTypeValue(ChangeType change_type) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? changeTypeValue = null;
    if (change_type == ChangeType.LIKE) {
      RawRowData rawRowData = await tableTransactionDao.getById(trDto.id!);
      changeTypeValue = rawRowData.get('like', null) as int;
    }
    return changeTypeValue;
  }

  @override
  Future<void> setChangeTypeValue(ChangeType change_type, int value) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (change_type == ChangeType.LIKE) {
      FieldData fieldData = FieldData.wee(trDto.table_id);
      fieldData.set('like', value);
      await tableTransactionDao.upsert(fieldData, WhereData());
    }
  }

  @override
  void modifyChangeTypeValue(ChangeType change_type, int? value) {
    if (change_type == ChangeType.LIKE) {
      //tableTransactionDao.incrementLike(trDto.id);
    }
  }

  @override
  Future<void> modifyId(int original_id, int new_id) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      RawRowData rawRowData = await tableTransactionDao.getById(new_id);
      await delete(rawRowData.getFieldData());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
          e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT) {
        rethrow;
      }
    }
    await tableTransactionDao.modifyId(original_id, new_id);
    await tableTransactionTrDao.modifyId(original_id, new_id);
  }

  @override
  Future<void> modifyJoinIds(int original_id, int new_id) async { return await null; }

  @override
  String toString() {
    return "table_id:${trDto.table_id}, " + trDto.toString();
  }
}
