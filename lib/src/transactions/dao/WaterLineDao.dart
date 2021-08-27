import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class WaterLineDao extends AbstractTransactionDao {
  WaterLineDao.sep(SchemaMetaData smdSys, DbTransaction transaction)
      : super.sep(smdSys, transaction, mustBeSystem: true);
  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super
        .init(table_id: WaterLineDto.C_TABLE_ID, initTable: initTable);
  }

  void validateWaterLineDto(
      WaterLineDto waterLineDto, OperationType operationType) {}

  Future<WaterLineDto> updateWaterLineDto(WaterLineDto waterLineDto) async {
    validateWaterLineDto(waterLineDto, OperationType.UPDATE);

    WhereData whereData = WhereData();
    whereData.set('water_ts', SqlOperator.EQUAL, waterLineDto.water_ts);
    try {
      await update(waterLineDto, whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND) rethrow;
    }
    return waterLineDto;
  }

  Future<WaterLineDto> updateWaterLine(int ts, int? table_id,
      WaterState waterState, WaterError? waterError) async {
    WaterLineDto waterLineDto =
        WaterLineDto.sep(ts, waterState, waterError, table_id, smd);
    return await updateWaterLineDto(waterLineDto);
  }

  Future<WaterLineDto> selectWaterLineDto(WhereData whereData) async {
    FieldData fieldData = WaterLineDto.getSelectFieldData();
    RawTableData rawTableData = await select(fieldData, whereData);
    return WaterLineDto.field(
        rawTableData.getRawRowData(0).getFieldData(), smd);
  }

  WhereData getWaterLineWhereData(
      int? ts,
      SqlOperator tsOperator,
      int? tableId,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorEnumSet) {
    // --------------------------------------------------------- WHERE
    WhereData whereData = WhereData();
    whereData.set('water_ts', tsOperator, ts);
    if (tableId != null)
      whereData.set('water_table_id', SqlOperator.EQUAL, tableId);
    if (excludeTableIdList != null) {
      if (excludeTableIdList.length > 0)
        whereData.set('water_table_id', SqlOperator.NOT_IN, excludeTableIdList);
    }
    if (stateList != null) {
      whereData.set('water_state', SqlOperator.IN,
          WaterStateAccess.getWaterStateList(stateList));
    }
    if (errorEnumSet != null) {
      whereData.set('water_error', SqlOperator.IN,
          WaterErrorAccess.getWaterErrorList(errorEnumSet));
    }
    return whereData;
  }

  Future<List<WaterLineDto>> getWaterLineList(
      int? ts,
      SqlOperator? tsOperator,
      int? table_id,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorEnumSet,
      SortOrderType? sortOrder,
      int? limit) async {
    String limitSql = "";
    if (tsOperator == null) tsOperator = SqlOperator.EQUAL;
    FieldData fieldData = WaterLineDto.getSelectFieldData();
    WhereData whereData = getWaterLineWhereData(
        ts, tsOperator, table_id, excludeTableIdList, stateList, errorEnumSet);
    if (limit != null) {
      limitSql = " LIMIT " + limit.toString();
    }
    String sql;
    if (tsOperator != SqlOperator.MAX) {
      sql = sqlCommands.select(fieldData, whereData) + " ORDER BY water_ts";
      if (sortOrder == SortOrderType.PRIMARY_KEY_DESC) sql += " DESC ";
      sql += limitSql;
    } else {
      WhereGenerator whereGenerator =
          WhereGenerator(transaction.getTools()!.dbType, smd);
      sql = sqlCommands.select(fieldData, null);
      whereData.set("water_ts", SqlOperator.LESS, WaterLineDto.min_id_for_user);
      sql += " FROM $tableName "
              "    WHERE water_ts=(" +
          "              SELECT MAX(water_ts) " +
          "                FROM " +
          tableName +
          whereGenerator.getWhereString(whereData) +
          "             )";
    }
    List<WaterLineDto> list = [];
    RawTableData rawTableData;
    print(sql);
    try {
      rawTableData = await transaction.getConnection().query(sql, fieldData);
      if (rawTableData.rowCount == 0)
        throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND,
            sql: sql, json: fieldData.toJson());
      rawTableData.getRawRows().forEach((RawRowData rawRowData) {
        list.add(WaterLineDto.field(rawRowData.getFieldData(), smd));
      });
    } on SqlException catch (e) {
      SqlExceptionEnum sen =
          (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND)
              ? SqlExceptionEnum.ENTRY_NOT_FOUND
              : e.sqlExceptionEnum;
      throw SqlException(sen,
          cause: e.cause, sql: sql, json: fieldData.toJson());
    }
    return list;
  }

  Future<List<WaterLineDto>> getWaterLineListAboveTs(
      int? ts,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorEnumSet,
      SortOrderType? sortOrderType,
      int? limit) async {
    return await getWaterLineList(ts, SqlOperator.GREATER, null,
        excludeTableIdList, stateList, errorEnumSet, sortOrderType, limit);
  }

  Future<WaterLineDto> getNextWaterLineDtoAboveTs(
      int? ts,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorEnumSet) async {
    List<WaterLineDto> list = await getWaterLineList(ts, SqlOperator.GREATER,
        null, excludeTableIdList, stateList, errorEnumSet, null, 1);
    return list[0];
  }

  Future<WaterLineDto> getLatestWaterLineDto(
      List<WaterState>? stateList) async {
    List<WaterLineDto> list = await getWaterLineList(
        null, SqlOperator.MAX, null, null, stateList, null, null, null);
    return list[0];
  }

  Future<int> getWaterLineCountAboveTs(
      int? ts,
      int? tableId,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorEnumSet) async {
    FieldData fieldData = FieldData.wee(WaterLineDto.C_TABLE_ID);
    fieldData.addFieldSql("count(*) as ts_count");
    WhereData whereData = getWaterLineWhereData(ts, SqlOperator.GREATER,
        tableId, excludeTableIdList, stateList, errorEnumSet);
    try {
      RawTableData rawTableData = await select(fieldData, whereData);
      return await rawTableData.getRawField(0, 0) as int;
    } on SqlException {
      rethrow;
    }
  }

  Future<WaterLineDto> getWaterLineDto(int ts, int? tableId,
      WaterState? waterState, WaterError? waterError) async {
    List<WaterState>? stateList;
    if (waterState != null) {
      stateList = [];
      stateList.add(waterState);
    }
    Set<WaterError>? errorEnumSet;
    if (waterError != null) {
      errorEnumSet = Set();
      errorEnumSet.add(waterError);
    }
    List<WaterLineDto> list = await getWaterLineList(ts, SqlOperator.EQUAL,
        tableId, null, stateList, errorEnumSet, null, null);
    return list[0];
  }

  Future<List<WaterLineDto>> getWaterLineByTableType(
      int table_id, WaterState? waterState, WaterError? waterError) async {
    List<WaterState>? stateList;
    if (waterState != null) {
      stateList = [];
      stateList.add(waterState);
    }
    Set<WaterError>? errorEnumSet;
    if (waterError != null) {
      errorEnumSet = {waterError};
    }
    return await getWaterLineList(
        null, null, table_id, null, stateList, errorEnumSet, null, null);
  }

  Future<WaterLineDto> getWaterLineDtoByTs(int ts) async {
    return await getWaterLineDto(ts, null, null, null);
  }

  Future<int> insertWaterLine(
      int table_id, WaterState? waterState, WaterError? waterError,
      {int? ts}) async {
    if (table_id == null) throw ArgumentError("table_id must not be null");
    if (ts == 0)
      throw ArgumentError("ts" + AbstractDao.C_MUST_ABOVE_ZERO + tableName);
    FieldData fieldData = FieldData.wee(WaterLineDto.C_TABLE_ID);
    if (ts == null) ts = await getAutoIncrement('water_ts');
    fieldData.set('water_ts', ts, field_table_id: table_id);
    fieldData.set('water_table_id', table_id, field_table_id: table_id);
    fieldData.set(
        'water_state', WaterStateAccess.getWaterStateValue(waterState),
        field_table_id: table_id);
    fieldData.set(
        'water_error', WaterErrorAccess.getWaterErrorValue(waterError),
        field_table_id: table_id);
    await insert(fieldData);
    return ts;
  }

  Future<void> setStates(
      int water_ts, WaterState? waterState, WaterError? waterError) async {
    FieldData fieldData =
        WaterLineDto.getSetFieldData(water_ts, waterState, waterError, null);
    // If it already exists by select, dont update
    WhereData selectWhere =
        WaterLineDto.getWhereData(water_ts, waterState, waterError, null);
    try {
      await select(fieldData, selectWhere);
    } on SqlException {
      WhereData whereData =
          WaterLineDto.getWhereData(water_ts, null, null, null);
      await update(fieldData, whereData);
    }
  }

  Future<void> setWaterLine(int ts, FieldData fieldData) async {
    WhereData whereData = WhereData();
    whereData.set('water_ts', SqlOperator.EQUAL, ts);
    try {
      await getWaterLineList(ts, null, null, null, null, null, null, null);
      await update(fieldData, whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        await insert(fieldData);
      } else
        rethrow;
    }
  }

  Future<int?> insertWaterLineDto(WaterLineDto waterLineDto) async {
    return await insert(waterLineDto);
  }

  Future<int> getNextUsedTs(int aboveTs) async {
    String sql = "   SELECT water_ts " + "     FROM " + tableName;
    if (aboveTs != null) {
      sql += "    WHERE water_ts > " + aboveTs.toString();
    }
    sql += "    LIMIT 1";

    RawTableData rawTableData;
    try {
      rawTableData =
          await transaction.getConnection().query(sql, FieldData.wee(table_id));
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause,
          sql: sql,
          json: "{ tableName:'$tableName', index:'$getIndex' }");
    }
    late int ts;
    try {
      ts = rawTableData.getRawField(0, 0) as int;
    } on RangeError catch (e) {
      print(e);
    }
    return ts;
  }

  Future<void> deleteWaterLine(
      int? ts,
      int? tableId,
      List<int>? excludeTableIdList,
      List<WaterState>? stateList,
      Set<WaterError>? errorSet) async {
    WhereData whereData = getWaterLineWhereData(ts, SqlOperator.EQUAL, tableId,
        excludeTableIdList, stateList, errorSet);
    await delete(whereData);
  }

  Future<void> deleteWaterLineByTs(int ts) async {
    WhereData whereData = WhereData();
    whereData.set('water_ts', SqlOperator.EQUAL, ts);
    await delete(whereData);
  }

  Future<void> deleteBelowLatestTs(WaterState waterState) async {
    WhereData whereData = WhereData();
    whereData.set("water_error", SqlOperator.EQUAL,
        WaterErrorAccess.getWaterErrorValue(WaterError.NONE));
    whereData.set("water_state", SqlOperator.EQUAL,
        WaterStateAccess.getWaterStateValue(waterState));
    WhereGenerator wg = WhereGenerator(transaction.getTools()!.dbType, smd);
    int maxTs = 0;
    String sql = "SELECT MAX(water_ts) " +
        "             FROM " +
        tableName +
        "            WHERE water_ts < " +
        WaterLineDto.min_id_for_user.toString() +
        "              AND " +
        wg.getWhereStringNoPrefix(whereData);
    print(sql);
    try {
      RawTableData rawTableData =
          await transaction.getConnection().query(sql, FieldData.wee(table_id));
      maxTs = rawTableData.getRawRowData(0).getField(0) as int;
    } on SqlException {
      rethrow;
    }
    if (maxTs != null) {
      sql = "   DELETE " +
          "     FROM " +
          tableName +
          "    WHERE water_ts < " +
          maxTs.toString() +
          "      AND " +
          wg.getWhereStringNoPrefix(whereData);
      print(sql);
      try {
        await transaction.getConnection().query(sql, FieldData.wee(table_id));
      } on SqlException {
        rethrow;
      }
    }
  }

  Future<TableTransactions> getTableTransactions(int ts) async {
    // Fetch water_line
    List<WaterLineDto> list = await getWaterLineList(
        ts, SqlOperator.EQUAL, null, null, null, null, null, null);
    WaterLineDto waterLineDto = list[0];
    // Fetch table
    TableTransactionTrDao trDao = TableTransactionTrDao(smd, transaction);
    await trDao.init(table_id: waterLineDto.water_table_id);
    RawRowData rawRowData = await trDao.getRawRowDataByTs(ts);
    FieldData fieldData = FieldData.rawRowData(rawRowData, table_id);
    TableTransactions tableTransactions =
        TableTransactions.field(fieldData);
    return tableTransactions;
  }
}
