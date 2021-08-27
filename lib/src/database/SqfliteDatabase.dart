import 'package:rockvole_db/rockvole_db.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteDatabase extends AbstractDatabase {
  late Database _db;
  String fileName;

  SqfliteDatabase.filename(this.fileName) : super(DBType.Sqflite);

  @override
  Future<bool> connect() async {
    _db = await openDatabase(fileName);
    return true;
  }

  @override
  Future<RawTableData> query(String sql, FieldData fieldData) async {
    List<List<Object>> rowList = [];
    try {
      List<Map<String, dynamic>> rawQueryList = await _db.rawQuery(sql);
      rawQueryList.forEach((Map<String, dynamic> map) {
        List<Object> fieldList = [];
        map.forEach((key, value) {
          fieldList.add(value);
        });
        rowList.add(fieldList);
      });
      return RawTableData(fieldData.table_id, rowList, fieldData.getFieldNameList);
    } catch (e) {
      if (e.toString().startsWith("DatabaseException(no such table")) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND, cause: e.toString());
      } else if (e.toString().startsWith("DatabaseException(table")) {
        throw SqlException(SqlExceptionEnum.TABLE_ALREADY_EXISTS,cause: e.toString());
      } else if (e.toString().startsWith("DatabaseException(database_closed 1)")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED, cause: e.toString());
      } else {
        print(e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR, cause: e.toString());
      }
    }
  }

  @override
  Future<int> updateQuery(String sql) async {
    List<List<Object>> rowList = [];
    try {
      List<Map<String, dynamic>> rawQueryList = await _db.rawQuery(sql);
      rawQueryList.forEach((Map<String, dynamic> map) {
        List<Object> fieldList = [];
        map.forEach((key, value) {
          fieldList.add(value);
        });
        rowList.add(fieldList);
      });
      return 1;
    } catch (e) {
      if (e.toString().startsWith("DatabaseException(no such table")) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND, cause: e.toString());
      } else if (e.toString().startsWith("DatabaseException(table")) {
        throw SqlException(SqlExceptionEnum.TABLE_ALREADY_EXISTS,cause: e.toString());
      } else if (e.toString().startsWith("DatabaseException(database_closed 1)")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED, cause: e.toString());
      } else {
        print(e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR, cause: e.toString());
      }
    }
  }

  @override
  Future<int> insertQuery(String sql, FieldData fieldData) async {
    int returnValue;
    try {
      returnValue = await _db.rawInsert(sql, fieldData.getFieldDataValuesList);
      return returnValue;
    } catch (e) {
      if (e.toString().startsWith("DatabaseException(no such table")) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND, cause: e.toString());
      } else if (e.toString().startsWith("DatabaseException(database_closed 1)")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED, cause: e.toString());
      } else {
        print(e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR, cause: e.toString());
      }
    }
  }

  @override
  Future<bool> close() async {
    _db.close();
    return true;
  }
}
