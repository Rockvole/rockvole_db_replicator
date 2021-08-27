import 'package:rockvole_db_replicator/rockvole_db.dart';

class SqlCommands {
  String tableName;
  SchemaMetaData smd;
  DBType dbType;
  late AbstractSqlStrings sqlStrings;


  SqlCommands(this.tableName, this.smd, this.dbType) {
    if(smd==null) throw ArgumentError("SchemaMetaData must not be null");
    sqlStrings = AbstractSqlStrings(this.tableName, this.dbType);
  }

  String createTable() {
    StringBuffer sql = StringBuffer();
    sql.write(sqlStrings.getCreateTableString(tableName, false)+"( ");
    bool isFirst=true;
    smd.getTableByName(tableName)!.getFieldList().forEach((fmd) {
      if(!isFirst) sql.write(", ");
      sql.write("             " +
          fmd.fieldName +
          " " +
          sqlStrings.getDataTypeString(fmd.fieldDataType, fmd.fieldSize));
      if (fmd.notNull)
        sql.write("NOT NULL ");
      else
        sql.write(" ");
      if(fmd.autoIncrement)
        sql.write(sqlStrings.getAutoIncrementString());
      isFirst=false;
    });
    TableMetaData tmd=smd.getTableByName(tableName)!;
    if(tmd.uniqueKeyMap!=null) {
      tmd.uniqueKeyMap!.forEach((k,v) {
        sql.write(" ,");
        sql.write("CONSTRAINT $k UNIQUE (");
        bool isFirstField=true;
        v.forEach((fieldName) {
          if(!isFirstField) sql.write(",");
          sql.write("$fieldName");
          isFirstField=false;
        });
        sql.write(")");
      });
    }
    sql.write(") ");
    return StringUtils.formatSql(sql.toString());
  }

  String select(FieldData fieldData,WhereData? whereData) {
    StringBuffer sql = StringBuffer();
    sql.write(" SELECT ");
    bool isFirst=true;
    fieldData.getFieldStructList.forEach((sd) {
      if(!isFirst) {
        sql.write(",");
      }
      if(sd.fieldName!=null) {
        sql.write("             " + sd.fieldName!);
      } else {
        if(sd.value is SqlKeyword) {
          sql.write(
              "             " + (sd.value as SqlKeyword).getKeywordString);
        }
      }
      isFirst=false;
    });
    if(whereData!=null) {
      sql.write("     FROM $tableName");
      WhereGenerator wg = WhereGenerator(dbType, smd);
      sql.write(wg.getWhereString(whereData));
      sql.write(wg.getOrderString(whereData));
      if(whereData.limit!=null) sql.write(" LIMIT "+whereData.limit.toString());
    }
    return StringUtils.formatSql(sql.toString());
  }

  String insert(FieldData fieldData) {
    StringBuffer sql = StringBuffer();
    StringBuffer bindMarker = StringBuffer();
    sql.write(" INSERT INTO $tableName ( ");
    bool isFirst=true;
    fieldData.getFieldStructList.forEach((sd) {
      if(!isFirst) {
        sql.write(",");
        bindMarker.write(",");
      }
      sql.write("             "+sd.fieldName!);
      bindMarker.write(" ?");
      isFirst=false;
    });
    sql.write("             ) ");
    sql.write("      VALUES ( ");
    sql.write(bindMarker.toString());
    sql.write(" )");
    return StringUtils.formatSql(sql.toString());
  }

  String update(FieldData fieldData, WhereData whereData) {
    StringBuffer sql = StringBuffer();
    sql.write(" UPDATE $tableName ");
    WhereGenerator wg = WhereGenerator(dbType,smd);
    sql.write(wg.getSetString(fieldData));
    sql.write(wg.getWhereString(whereData));
    return StringUtils.formatSql(sql.toString());
  }

  String delete(WhereData whereData) {
    StringBuffer sql = StringBuffer();
    sql.write(" DELETE FROM $tableName ");
    WhereGenerator wg = WhereGenerator(dbType,smd);
    sql.write(wg.getWhereString(whereData));
    return StringUtils.formatSql(sql.toString());
  }

  String dropTable() {
    StringBuffer sql = StringBuffer();
    sql.write(" DROP TABLE $tableName ");
    return StringUtils.formatSql(sql.toString());
  }

  String doesTableExist() {
    String sql=sqlStrings.doesTableExist(tableName);
    return StringUtils.formatSql(sql);
  }

  String importDataString(String fileName, String? fieldSeparator, String? fieldEnclose, String? lineTerminator) {
    return StringUtils.formatSql(sqlStrings.getImportDataString(tableName, fileName, fieldSeparator, fieldEnclose, lineTerminator)!);
  }
}