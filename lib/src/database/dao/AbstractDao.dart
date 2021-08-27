import 'package:rockvole_db_replicator/rockvole_db.dart';

abstract class AbstractDao {
  bool initialized = false;
  static final String C_MUST_INIT =
      "You must call init() before any other methods.";
  static final String C_MUST_ABOVE_ZERO = " must be above 0 for table ";
  static final String C_MUST_SYSTEM = "SchemaMetaData must be System";
  static final String C_OPERATION_NOT_SUPPORTED = "Operation not supported";
  late int table_id;
  late String tableName;
  late SchemaMetaData smd;
  late DbTransaction transaction;

  //TableMetaDataAccess tableMetaDataAccess;
  late SqlCommands sqlCommands;

  AbstractDao();
  AbstractDao.sep(this.smd, this.transaction, {bool mustBeSystem = false}) {
    if (mustBeSystem && !smd.isSystem) throw ArgumentError(C_MUST_SYSTEM);
    if (transaction.connection == null)
      throw ArgumentError("DbTransaction must have a connection");
    if(transaction.getTools()==null)
      throw ArgumentError("DbTransaction must have tools");
  }
  Future<bool> init({int? table_id, bool initTable = true}) async {
    if (table_id == null) throw ArgumentError("table_id must not be null");
    initialized = true;
    this.table_id = table_id;
    this.tableName = smd.getTableByTableId(table_id).table_name;
    sqlCommands =
        SqlCommands(this.tableName, this.smd, transaction.getTools()!.dbType);

    if (initTable) return await initializeTable();
    return false;
  }

  Future<bool> initializeTable() async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    if (!await doesTableExist()) {
      try {
        await createTable();
      } on SqlException {
        rethrow;
      }
      return true;
    }
    return false;
  }

  Future<bool> createTable() async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.createTable();
    print(sql);
    try {
      await transaction.getConnection().query(sql, FieldData.wee(table_id));
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause,
          sql: sql,
          json: smd.getTableByName(tableName)!.toJson());
    }
    return true;
  }

  Future<RawTableData> select(FieldData fieldData, WhereData whereData) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.select(fieldData, whereData);
    print(sql);
    return await bareSelect(sql, fieldData);
  }

  Future<RawTableData> bareSelect(String sql, FieldData fieldData) async {
    try {
      RawTableData rawTableData =
          await transaction.getConnection().query(sql, fieldData);
      if (rawTableData.rowCount == 0)
        throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND,
            cause: "No rows returned", sql: sql, json: fieldData.toJson());
      print(rawTableData.toJson());
      return rawTableData;
    } on SqlException catch (e) {
      SqlExceptionEnum sen =
          (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND)
              ? SqlExceptionEnum.ENTRY_NOT_FOUND
              : e.sqlExceptionEnum;
      throw SqlException(sen,
          cause: e.cause, sql: sql, json: fieldData.toJson());
    }
  }

  Future<int?> insert(FieldData fieldData) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.insert(fieldData);
    print(sql);
    print(fieldData.toJson());
    try {
      await transaction.getConnection().insertQuery(sql, fieldData);
      TableMetaData tmd = smd.getTableByTableId(table_id);
      String index=tmd.getProperty('index').toString();
      return fieldData.get(index) as int;
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause, sql: sql, json: fieldData.toJson());
    }
  }

  Future<void> update(FieldData fieldData, WhereData whereData) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.update(fieldData, whereData);
    print(sql);
    if (whereData.whereStructList.length == 0)
      throw IllegalStateException(
          "TableData must contain WhereData for update");

    try {
      var affectedRows = await transaction.getConnection().updateQuery(sql);
      if (affectedRows == 0)
        throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
            sql: sql, json: fieldData.toJson());
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause, sql: sql, json: fieldData.toJson());
    }
  }

  Future<RawRowData> upsert(FieldData fieldData, WhereData whereData) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    try {
      await select(fieldData, whereData);
      await update(fieldData, whereData);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        await insert(fieldData);
      }
    }
    return fieldData.getRawRowData();
  }

  Future<int?> delete(WhereData whereData) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    if (whereData != null && whereData.whereStructList.length == 0)
      throw IllegalStateException(
          "TableData must contain WhereData for delete");
    String sql = sqlCommands.delete(whereData);
    print(sql);
    int? rowCount;
    try {
      rowCount = await transaction.getConnection().updateQuery(sql);
      if(rowCount==0) throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND);
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum, cause: e.cause, sql: sql);
    }
    return rowCount;
  }

  Future<void> deleteById(int id) async {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await delete(whereData);
  }

  Future<bool> dropTable() async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.dropTable();
    print(sql);
    try {
      await transaction.getConnection().query(sql, FieldData.wee(table_id));
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause,
          sql: sql,
          json: smd.getTableByName(tableName)?.toJson());
    }
    return true;
  }

  Future<bool> doesTableExist() async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.doesTableExist();
    print(sql);
    try {
      RawTableData rawTableData =
          await transaction.getConnection().query(sql, FieldData.wee(table_id));
      return rawTableData.rowCount > 0;
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause,
          sql: sql,
          json: smd.getTableByName(tableName)!.toJson());
    }
  }

  Future<int> getAutoIncrement(String fieldName) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    FieldData fieldDataSelect = FieldData.wee(table_id);
    fieldDataSelect.addFieldSql("max($fieldName) as max_id");
    RawTableData rawTableData = await select(fieldDataSelect, WhereData());
    int? maxId = rawTableData.getRawField(0, 0) as int;
    if (maxId == null) return 1;
    return maxId + 1;
  }

  Future<void> importData(String fileName,
      {String? fieldSeparator,
      String? fieldEnclose,
      String? lineTerminator}) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    String sql = sqlCommands.importDataString(
        fileName, fieldSeparator, fieldEnclose, lineTerminator);
    print(sql);
    try {
      await transaction.getConnection().query(sql, FieldData.wee(table_id));
    } on SqlException catch (e) {
      throw SqlException(e.sqlExceptionEnum,
          cause: e.cause,
          sql: sql,
          json: smd.getTableByName(tableName)!.toJson());
    }
  }

  String get getIndex {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    return smd.getTableByName(tableName)!.getProperty('index') as String;
  }

  Future<void> modifyField(Object obj, Object newObj, String fieldName) async {
    if (!initialized) throw ArgumentError(C_MUST_INIT);
    FieldData fieldData = FieldData.wee(table_id);
    fieldData.set(fieldName, newObj);
    WhereData whereData = WhereData();
    whereData.set(fieldName, SqlOperator.EQUAL, obj);
    String sql = sqlCommands.update(fieldData, whereData);
    print(sql);
    try {
      var affectedRows = await transaction.getConnection().updateQuery(sql);
      if (affectedRows == 0)
        throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND,
            sql: sql, json: fieldData.toJson());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND) {
        throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND,
            cause:
                SqlExceptionTools.getMessage(SqlExceptionEnum.TABLE_NOT_FOUND),
            sql: sql,
            json: fieldData.toJson());
      } else
        rethrow;
    }
  }

  String getSortOrderString(SortOrderType? sortOrder, String? columnName) {
    String sortOrderString = "";
    if (sortOrder == null) sortOrder = SortOrderType.COLUMN_ASC;
    if (columnName == null) columnName = "name";
    switch (sortOrder) {
      case SortOrderType.PRIMARY_KEY_ASC:
        sortOrderString = " ORDER BY id";
        break;
      case SortOrderType.PRIMARY_KEY_DESC:
        sortOrderString = " ORDER BY id desc";
        break;
      case SortOrderType.COLUMN_ASC:
        sortOrderString = " ORDER BY " + columnName;

        break;
      case SortOrderType.COLUMN_DESC:
        sortOrderString = " ORDER BY " + columnName + " desc";
        break;
    }
    return sortOrderString;
  }

  @override
  String toString() {
    return "tableName:$tableName||transaction:$transaction";
  }
}
