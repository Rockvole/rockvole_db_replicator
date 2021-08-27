import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

abstract class AbstractTransactionTrDao {
  late GenericDao dao;
  AbstractTransactionTrDao(SchemaMetaData smdSys, DbTransaction transaction) {
    if (!smdSys.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);
    dao = GenericDao(smdSys, transaction);
  }
  Future<void> init({int? table_id, bool initTable = true}) async {
    if (table_id == null) throw ArgumentError("table_id must not be null");

    await dao.init(table_id: table_id, initTable: initTable);
  }

  SchemaMetaData get smdSys => dao.smd;

  Future<bool> createTable() async {
    return dao.createTable();
  }

  TrDto validateTrDto(TrDto trDto, OperationType operationType) {
    if (trDto.id != null && trDto.id! <= 0) {
      throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
          cause: "AbstractTransactionTrDao: Id must not be 0");
    }
    return trDto;
  }

  FieldData getTrSet(FieldData fieldData, TrDto trDto) {
    if (smdSys.isSystem && trDto != null) {
      if (trDto.operation != null)
        fieldData.set("operation",
            OperationTypeAccess.getOperationValue(trDto.operation));

      fieldData.set("user_id", trDto.user_id);
      fieldData.set("user_ts", trDto.user_ts);
      fieldData.set("comment", trDto.comment);
      fieldData.set("crc", trDto.crc);
    }
    return fieldData;
  }

  Future<RawRowData> getRawRowDataByTs(int ts, {FieldData? fieldData}) async {
    WhereData whereData = WhereData();
    whereData.set('ts', SqlOperator.EQUAL, ts);
    RawTableData rawTableData = await selectTR(whereData, fieldData: fieldData);
    return rawTableData.getRawRowData(0);
  }

  Future<RawTableData> selectTR(WhereData whereData,
      {FieldData? fieldData}) async {
    if (fieldData == null)
      fieldData = dao.smd
          .getTableByTableId(dao.table_id)
          .getSelectFieldData(dao.table_id);
    ValidateData.validateFieldData(fieldData, dao.smd, table_id: dao.table_id);
    fieldData = _appendTRFieldValues(null, fieldData);
    return await dao.select(fieldData, whereData);
  }

  Future<int?> insert(FieldData fieldData) async {
    return await dao.insert(fieldData);
  }

  Future<int?> insertTR(TrDto trDto, FieldData fieldData) async {
    ValidateData.validateFieldData(fieldData, dao.smd, table_id: dao.table_id);
    if (trDto.ts == null) trDto.ts = await dao.getAutoIncrement('ts');
    fieldData = _appendTRFieldValues(trDto, fieldData);
    await dao.insert(fieldData);
    return trDto.ts;
  }

  Future<void> updateTR(
      TrDto trDto, FieldData fieldData, WhereData whereData) async {
    if (!whereData.contains('ts'))
      throw SqlException(SqlExceptionEnum.FAILED_SELECT,
          cause: "ts must not be null");
    ValidateData.validateFieldData(fieldData, dao.smd, table_id: dao.table_id);
    fieldData = _appendTRFieldValues(trDto, fieldData);
    await dao.update(fieldData, whereData);
  }

  Future<RawRowData> upsertTR(
      TrDto trDto, FieldData? fieldData, WhereData whereData) async {
    fieldData = _appendTRFieldValues(trDto, fieldData);
    try {
      await selectTR(whereData, fieldData: fieldData);
      await updateTR(trDto, fieldData, whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        await insertTR(trDto, fieldData);
      }
    }
    return fieldData.getRawRowData();
  }

  Future<void> deleteTR(WhereData whereData) async {
    await dao.delete(whereData);
  }

  Future<void> deleteTrRowByTs(int ts) async {
    WhereData whereData = WhereData();
    whereData.set('ts', SqlOperator.EQUAL, ts);
    await deleteTR(whereData);
  }

  Future<bool> dropTable() async {
    return dao.dropTable();
  }

  Future<bool> doesTableExist() async {
    return dao.doesTableExist();
  }

  Future<int> getAutoIncrement(String fieldName) async {
    return dao.getAutoIncrement(fieldName);
  }

  Future<void> modifyField(Object obj, Object newObj, String fieldName) async {
    await dao.modifyField(obj, newObj, fieldName);
  }

  Future<void> modifyId(int id, int newId) async {
    try {
      await modifyField(id, newId, "id");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE &&
          e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT) {
        print("DB $e");
      }
    }
  }

  // --------------------------------------------------------------------------- TOOLS
  WhereData setWhereValues(int? ts, OperationType? operationType, int? userId,
      int? userTs, String? comment, int? crc, WhereData? whereData) {
    if (whereData == null) whereData = WhereData();
    whereData.set('ts', SqlOperator.EQUAL, ts);
    whereData.set('operation', SqlOperator.EQUAL,
        OperationTypeAccess.getOperationValue(operationType));
    whereData.set('user_id', SqlOperator.EQUAL, userId);
    whereData.set('user_ts', SqlOperator.EQUAL, userTs);
    whereData.set('comment', SqlOperator.EQUAL, comment);
    whereData.set('crc', SqlOperator.EQUAL, crc);
    return whereData;
  }

  FieldData _appendTRFieldValues(TrDto? trDto, FieldData? fieldData) {
    if (fieldData == null) fieldData = FieldData.wee(trDto!.table_id);
    if (trDto != null && trDto.ts != null)
      fieldData.set('ts', trDto.ts);
    else if (!fieldData.contains('ts')) {
      fieldData.set('ts', null);
    }
    if (trDto != null && trDto.operation != null)
      fieldData.set(
          'operation', OperationTypeAccess.getOperationValue(trDto.operation));
    else if (!fieldData.contains('operation')) {
      fieldData.set('operation', null);
    }
    if (trDto != null && trDto.user_id != null)
      fieldData.set('user_id', trDto.user_id);
    else if (!fieldData.contains('user_id')) {
      fieldData.set('user_id', null);
    }
    if (trDto != null && trDto.user_ts != null)
      fieldData.set('user_ts', trDto.user_ts);
    else if (!fieldData.contains('user_ts')) {
      fieldData.set('user_ts', null);
    }
    if (trDto != null && trDto.comment != null)
      fieldData.set('comment', trDto.comment);
    else if (!fieldData.contains('comment')) {
      fieldData.set('comment', null);
    }
    if (trDto != null && trDto.crc != null)
      fieldData.set('crc', trDto.crc);
    else if (!fieldData.contains('crc')) {
      fieldData.set('crc', null);
    }
    return fieldData;
  }
}
