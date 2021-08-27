import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

abstract class AbstractTransactionDao extends AbstractDao {
  AbstractTransactionDao();
  AbstractTransactionDao.sep(SchemaMetaData smd, DbTransaction transaction,
      {bool mustBeSystem = false})
      : super.sep(smd, transaction, mustBeSystem: mustBeSystem);
  int get getMinIdForUser {
    int mifu =
        smd.getTableByName(tableName)!.getProperty('min-id-for-user') as int;
    return mifu;
  }

  Future<int> _getNextIdForUser() async {
    int minIdForUser = getMinIdForUser;
    int maxId = await getAutoIncrement(getIndex);
    if (maxId < minIdForUser) maxId = minIdForUser;
    return maxId;
  }

  Future<int> getNextId(WardenType wardenType) async {
    if (Warden.isClient(wardenType)) {
      return await _getNextIdForUser();
    } else {
      int? nextId = null;
      nextId = await _getHoleFreeMaxIndex();
      if (nextId == null) {
        String sql = "   SELECT " +
            getIndex +
            "-1 AS NEXT_ID " +
            "     FROM " +
            tableName +
            " t1 " +
            " WHERE NOT EXISTS " +
            "          (SELECT * " +
            "             FROM " +
            tableName +
            " t2 " +
            "            WHERE t1." +
            getIndex +
            " -1 = t2." +
            getIndex +
            "          ) " +
            "      AND " +
            getIndex +
            ">1 " +
            " ORDER BY " +
            getIndex +
            " DESC";

        RawTableData rawTableData;
        try {
          rawTableData = await transaction
              .getConnection()
              .query(sql, FieldData.wee(table_id));
        } on SqlException catch (e) {
          throw SqlException(e.sqlExceptionEnum,
              cause: e.cause,
              sql: sql,
              json: "{ tableName:'$tableName', index:'$getIndex' }");
        }
        try {
          nextId = rawTableData.getRawField(0, 0) as int;
        } on RangeError {}
        if (nextId == null) nextId = 1;
      }
      return nextId;
    }
  }

  Future<int> getRowCount() async {
    String sql = "   SELECT COUNT(*) AS CNT " + "          FROM " + tableName;
    RawTableData rawTableData = await bareSelect(sql, FieldData.wee(table_id));
    RawRowData rawRowData = rawTableData.getRawRowData(0);

    return rawRowData.getField(0) as int;
  }

  // Check for the Maximum Index value, if there are holes return null
  Future<int?> _getHoleFreeMaxIndex() async {
    bool holesFound = true;
    String sql = "   SELECT COUNT(*) AS ROW_COUNT, " +
        "          MAX(" +
        getIndex +
        ") AS ROW_MAX " +
        "     FROM " +
        tableName;
    RawTableData rawTableData;
    try {
      rawTableData =
          await transaction.getConnection().query(sql, FieldData.wee(table_id));
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum, cause: e.cause, sql: sql);
    }
    late int rowMax;
    if (rawTableData.rowCount > 0) {
      RawRowData rawRowData = rawTableData.getRawRowData(0);
      int rowCount = rawRowData.getField(0) as int;
      rowMax = rawRowData.getField(1) as int;
      if (rowCount == rowMax) holesFound = false;
    }
    if (holesFound) return null;
    return rowMax + 1;
  }

  Future<int> add(FieldData fieldData, WardenType wardenType) async {
    int nextId = await getNextId(wardenType);
    fieldData.set('id', nextId);
    await insert(fieldData);
    return nextId;
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

  Future<RawRowData> getById(int id) async {
    FieldData fieldData =
        smd.getTableByTableId(table_id).getSelectFieldData(table_id);
    WhereData whereData = WhereData();
    whereData.set("id", SqlOperator.EQUAL, id);
    RawTableData rawTableData = await select(fieldData, whereData);
    return rawTableData.getRawRowData(0);
  }
}
