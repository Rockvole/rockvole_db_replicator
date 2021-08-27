import 'package:rockvole_db/rockvole_db.dart';

// From AbstractDbTools
abstract class AbstractSqlStrings {
  DBType dbType;

  factory AbstractSqlStrings(String tableName, DBType dbType) {
    switch(dbType) {
      case DBType.Hsql: throw Exception("Not implemented yet");
      case DBType.Sqflite: return SqfliteStrings(dbType);
      case DBType.Sqlite: throw Exception("Not implemented yet");
      case DBType.Mysql: return MysqlStrings(dbType);
    }
  }

  AbstractSqlStrings.internal(this.dbType);

  String getDataTypeString(FieldDataType fieldDataType, int? fieldSize);
  String getCreateTableString(String tableName, [bool fts=false]) {
    if(fts) throw ArgumentError("Full table search not implemented for "+dbType.toString());
    return "CREATE TABLE "+tableName+" ";
  }
  String getAutoIncrementString() {
    return "AUTO_INCREMENT";
  }
  String? getImportDataString(String tableName, String fileName, String? fieldSeparator, String? fieldEnclose, String? lineTerminator);

  String doesTableExist(String tableName);

  @override
  String toString() => dbType.toString();
}