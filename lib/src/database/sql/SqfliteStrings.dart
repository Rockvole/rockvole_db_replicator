import 'package:rockvole_db/rockvole_db.dart';

class SqfliteStrings extends AbstractSqlStrings {

  SqfliteStrings(DBType dbType) : super.internal(dbType);

  @override
  String getDataTypeString(FieldDataType fieldDataType, int? fieldSize) {
    switch(fieldDataType) {
      case FieldDataType.TINYINT : return "TINYINT UNSIGNED ";
      case FieldDataType.SMALLINT : return "SMALLINT UNSIGNED ";
      case FieldDataType.MEDIUMINT : return "MEDIUMINT UNSIGNED ";
      case FieldDataType.INTEGER : return "INTEGER UNSIGNED ";
      case FieldDataType.BIGINT : return "BIGINT UNSIGNED ";
      case FieldDataType.VARCHAR : return "VARCHAR("+fieldSize.toString()+") ";
    }
  }

  @override
  String getCreateTableString(String tableName, [bool fts=false]) {
    if(fts) {
      return "CREATE VIRTUAL TABLE "+tableName+" USING fts4 ";
    }
    return "CREATE TABLE "+tableName+" ";
  }

  @override
  String getAutoIncrementString() {
    return "PRIMARY KEY AUTOINCREMENT";
  }

  @override
  String? getImportDataString(String tableName, String fileName, String? fieldSeparator, String? fieldEnclose, String? lineTerminator) {
    return null;
  }

  @override
  String doesTableExist(String tableName) {
    return "   SELECT * " +
        "     FROM sqlite_master " +
        "    WHERE type='table' " +
        "      AND name= '$tableName'";
  }
}
