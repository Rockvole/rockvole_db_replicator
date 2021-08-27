import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:sqlite3/sqlite3.dart';

class Sqlite3Database extends AbstractDatabase {
  late Database _db;
  String fileName;

  Sqlite3Database.filename(this.fileName) : super(DBType.Sqlite);

  @override
  Future<bool> connect() async {
    _db = sqlite3.open(fileName);
    return true;
  }

  @override
  Future<RawTableData> query(String sql, FieldData fieldData) async {
    List<List<Object?>> rowList = [];
    try {
      ResultSet rs = _db.select(sql);
      List<List<Object?>> rawQueryList = rs.rows;
      rawQueryList.forEach((List<Object?> list) {
        List<Object?> fieldList = [];
        list.forEach((value) {
          fieldList.add(value);
        });
        rowList.add(fieldList);
      });
      return RawTableData(
          fieldData.table_id, rowList, fieldData.getFieldNameList);
    } catch (e) {
      print(e);
      throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR,
          cause: e.toString());
    }
  }

  @override
  Future<int> updateQuery(String sql) async {
    try {
      _db.execute(sql);
    } catch (e) {
      print(e);
    }
    return _db.getUpdatedRows();
  }

  @override
  Future<int> insertQuery(String sql, FieldData fieldData) async {
    try {
      PreparedStatement ps = _db.prepare(sql);
      ps.execute(fieldData.getFieldDataValuesList);
    } catch (e) {
      print(e);
    }
    return _db.getUpdatedRows();
  }

  @override
  Future<bool> close() async {
    _db.dispose();
    return true;
  }
}
