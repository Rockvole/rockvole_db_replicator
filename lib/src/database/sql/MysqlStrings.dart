import 'package:rockvole_db_replicator/rockvole_db.dart';

class MysqlStrings extends AbstractSqlStrings {
  MysqlStrings(DBType dbType) : super.internal(dbType);

  @override
  String getDataTypeString(FieldDataType fieldDataType, int? fieldSize) {
    switch(fieldDataType) {
      case FieldDataType.TINYINT : return "TINYINT(1) UNSIGNED ";
      case FieldDataType.SMALLINT : return "SMALLINT UNSIGNED ";
      case FieldDataType.MEDIUMINT : return "MEDIUMINT UNSIGNED ";
      case FieldDataType.INTEGER : return "INTEGER UNSIGNED ";
      case FieldDataType.BIGINT : return "BIGINT UNSIGNED ";
      case FieldDataType.VARCHAR : return "VARCHAR("+fieldSize.toString()+") CHARACTER SET ascii ";
    }
  }

  String? getImportDataString(String tableName, String fileName, String? fieldSeparator, String? fieldEnclose, String? lineTerminator) {
    StringBuffer sb= StringBuffer();
    sb.write("LOAD DATA INFILE '$fileName' ");
    sb.write("     INTO TABLE $tableName ");
    if(fieldSeparator==null) fieldSeparator='|';
    sb.write("     FIELDS TERMINATED BY '$fieldSeparator' ");
    if(fieldEnclose!=null) {
      sb.write("    ENCLOSED BY \"$fieldEnclose\" ");
    }
    if(lineTerminator==null) lineTerminator="\n";
    sb.write("     LINES TERMINATED BY '$lineTerminator' ");
    return sb.toString();
  }

  @override
  String doesTableExist(String tableName) {
    return "SHOW TABLES LIKE '$tableName'";
  }

}