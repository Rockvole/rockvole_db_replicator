import 'package:rockvole_db/rockvole_db.dart';

enum SqlType {
  SELECT,
  INSERT,
  UPDATE,
  DELETE,
  CREATE_TABLE,
  DROP_TABLE,
  TABLE_EXISTS,
  IMPORT
}

class TableData {
  late FieldData fieldData;
  late WhereData whereData;
  SqlType sqlType;

  TableData(this.sqlType) {
    fieldData = FieldData();
    whereData = WhereData();
  }
  TableData.sep(this.fieldData, this.whereData, this.sqlType);

  String toJson({bool includeTableName = false}) {
    return fieldData.toJson(includeTableName: includeTableName) +
        whereData.toJson(includeTableName: includeTableName);
  }

  @override
  String toString() {
    return fieldData.toString() + whereData.toString();
  }
}
