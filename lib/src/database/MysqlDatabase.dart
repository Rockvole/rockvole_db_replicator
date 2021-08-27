import 'package:rockvole_db/rockvole_db.dart';
import 'package:mysql1/mysql1.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class MysqlDatabase extends AbstractDatabase {
  String hostName;
  int port;
  String userName;
  String password;
  String schemaName;

  MySqlConnection? _conn;

  MysqlDatabase.settings(
      {this.hostName: 'localhost',
      this.port: 3306,
      this.userName = 'aversions',
      this.password = 'aversions',
      this.schemaName = DataBaseHelper.C_DEFAULT_DATABASE})
      : super(DBType.Mysql);

  @override
  Future<bool> connect() async {
    var settings = ConnectionSettings(
        host: hostName,
        port: port,
        user: userName,
        password: password,
        db: schemaName);
    _conn = await MySqlConnection.connect(settings);
    return true;
  }

  @override
  Future<RawTableData> query(String sql, FieldData fieldData) async {
    if (_conn == null)
      throw ArgumentError("connect() must be called before query");
    Results results;
    List<List<Object>> rowList = [];
    try {
      results = await _conn!.query(sql);
    } catch (e) {
      if (getErrorCode(e.toString()) == 1050) {
        throw SqlException(SqlExceptionEnum.TABLE_ALREADY_EXISTS,
            cause: e.toString());
      } else if (getErrorCode(e.toString()) == 1051) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND,
            cause: e.toString());
      } else if (getErrorCode(e.toString()) == 1146) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND,
            cause: e.toString());
      } else if (e
          .toString()
          .startsWith("Bad state: Cannot write to socket, it is closed")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED,
            cause: e.toString());
      } else {
        print(e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR,
            cause: e.toString());
      }
    }
    if (results != null) {
      for (ResultRow row in results) {
        List<Object> fieldList = [];
        row.forEach((e) {
          fieldList.add(e);
        });
        rowList.add(fieldList);
      }
    }
    return RawTableData(fieldData.table_id, rowList, fieldData.getFieldNameList);
  }

  @override
  Future<int?> updateQuery(String sql) async {
    if (_conn == null)
      throw ArgumentError("connect() must be called before updateQuery");
    try {
      Results results = await _conn!.query(sql);
      return results.affectedRows;
    } catch (e) {
      if (getErrorCode(e.toString()) == 1050) {
        throw SqlException(SqlExceptionEnum.TABLE_ALREADY_EXISTS,
            cause: e.toString());
      } else if (getErrorCode(e.toString()) == 1051) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND,
            cause: e.toString());
      } else if (getErrorCode(e.toString()) == 1146) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND,
            cause: e.toString());
      } else if (e
          .toString()
          .startsWith("Bad state: Cannot write to socket, it is closed")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED,
            cause: e.toString());
      } else {
        print(e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR,
            cause: e.toString());
      }
    }
  }

  @override
  Future<int?> insertQuery(String sql, FieldData fieldData) async {
    if (_conn == null)
      throw ArgumentError("connect() must be called before insertQuery");
    try {
      var result = await _conn!.query(sql, fieldData.getFieldDataValuesList);
      return result.insertId;
    } catch (e) {
      if (getErrorCode(e.toString()) == 1062) {
        throw SqlException(SqlExceptionEnum.DUPLICATE_ENTRY,
            cause: e.toString());
      } else if (getErrorCode(e.toString()) == 1146) {
        throw SqlException(SqlExceptionEnum.TABLE_NOT_FOUND,
            cause: e.toString());
      } else if (e
          .toString()
          .startsWith("Bad state: Cannot write to socket, it is closed")) {
        throw SqlException(SqlExceptionEnum.SOCKET_CLOSED,
            cause: e.toString());
      } else {
        print("insertQuery:" + e.toString());
        throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR,
            cause: e.toString());
      }
    }
  }

  @override
  Future<bool> close() async {
    if (_conn != null) await _conn!.close();
    return true;
  }

  @override
  String toString() {
    return "MySqlDatabase [hostName=$hostName, " +
        "port=$port, " +
        "userName=$userName, " +
        "password=$password, " +
        "schemaName=$schemaName" +
        "]";
  }
}
