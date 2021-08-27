import 'package:rockvole_db/rockvole_db.dart';

enum FieldDataType { BIGINT, INTEGER, MEDIUMINT, SMALLINT, TINYINT, VARCHAR }

class NotFoundException implements Exception {
  String cause;
  NotFoundException(this.cause);
}

class FieldMetaData {
  int table_field_id; // Unique int to reference each field
  int table_id; // Name of table this field is in
  String fieldName; // Name of this field in the table
  FieldDataType fieldDataType;
  int fieldSize;
  bool notNull;
  bool autoIncrement;

  String get uniqueKey => DataTools.convertUniqueKey(table_id, fieldName);

  FieldMetaData(
      this.table_field_id,
      this.table_id,
      this.fieldName,
      this.fieldDataType,
      this.fieldSize,
      this.notNull,
      this.autoIncrement) {
    switch (fieldDataType) {
      case FieldDataType.TINYINT:
        this.fieldSize = 1;
        break;
      case FieldDataType.SMALLINT:
        this.fieldSize = 2;
        break;
      case FieldDataType.MEDIUMINT:
        this.fieldSize = 3;
        break;
      case FieldDataType.INTEGER:
        this.fieldSize = 4;
        break;
      case FieldDataType.BIGINT:
        this.fieldSize = 5;
        break;
      case FieldDataType.VARCHAR:
    }
  }

  String toJson() {
    String SEP = ", ";
    StringBuffer sb = StringBuffer();
    sb.write("table_field_id:$table_field_id" + SEP);
    sb.write("table_id:$table_id" + SEP);
    sb.write("fieldName:$fieldName" + SEP);
    sb.write("fieldDataType:$fieldDataType" + SEP);
    sb.write("fieldSize:$fieldSize" + SEP);
    sb.write("notNull:$notNull" + SEP);
    sb.write("autoIncrement:$autoIncrement");
    return sb.toString();
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("table_field_id : $table_field_id" + SEP);
    sb.write("table_id       : $table_id" + SEP);
    sb.write("fieldName      : $fieldName" + SEP);
    sb.write("fieldDataType  : $fieldDataType" + SEP);
    sb.write("fieldSize      : $fieldSize" + SEP);
    sb.write("notNull        : $notNull" + SEP);
    sb.write("autoIncrement  : $autoIncrement" + SEP);
    sb.write("---------------------------------" + SEP);
    return sb.toString();
  }
}

class FieldMetaDataAccess {
  late List<FieldMetaData> fieldMetaDataList;
  int maxTableFieldId=0;

  // All the FieldMetaData classes indexed by table_field_id
  late Map<int, FieldMetaData> _tableFieldIdMap;
  // All the FieldMetaData classes indexed by fieldName
  late Map<String, FieldMetaData> _fieldNameMap;

  FieldMetaDataAccess() {
    fieldMetaDataList = [];
    _tableFieldIdMap = Map();
    _fieldNameMap = Map();
  }

  FieldMetaData addField(
      int table_field_id,
      int table_id,
      String fieldName,
      FieldDataType fieldDataType,
      int fieldSize,
      bool notNull,
      bool autoIncrement) {
    FieldMetaData fmd = FieldMetaData(table_field_id, table_id,
        fieldName, fieldDataType, fieldSize, notNull, autoIncrement);
    maxTableFieldId=table_field_id;
    fieldMetaDataList.add(fmd);
    _tableFieldIdMap[table_field_id] = fmd;
    _fieldNameMap[fieldName] = fmd;
    return fmd;
  }

  FieldMetaData getFieldByIndex(int index) {
    int offset=0;
    FieldMetaData? returnFmd;
    _tableFieldIdMap.forEach((int key, FieldMetaData fmd) {
      if(offset==index) returnFmd=fmd;
      offset++;
    });
    if(returnFmd==null) throw NotFoundException("Invalid index $index");
    return returnFmd!;
  }

  FieldMetaData getFieldByTableFieldId(int table_field_id) {
    return _tableFieldIdMap[table_field_id]!;
  }

  FieldMetaData getFieldByFieldName(String fieldName) => _fieldNameMap[fieldName]!;

  String getFieldNameByTableFieldId(int table_field_id) {
    String fieldName;
    try {
      fieldName = getFieldByTableFieldId(table_field_id).fieldName;
    } on NoSuchMethodError {
      throw NotFoundException("table_field_id not found");
    }
    return fieldName;
  }

  Map<String, Object> getFieldNameMapByTableFieldIdMap(
      Map<int, Object> tableFieldIdMap) {
    Map<String, Object> fieldNameMap = Map();
    try {
      tableFieldIdMap.forEach((k, v) {
        fieldNameMap[getFieldNameByTableFieldId(k)] = v;
      });
    } on NotFoundException {
      rethrow;
    }
    return fieldNameMap;
  }

  static FieldDataType? getFieldDataTypeFromString(String fieldDataType) {
    switch(fieldDataType.toLowerCase()) {
      case 'bigint':return FieldDataType.BIGINT;
      case 'integer':return FieldDataType.INTEGER;
      case 'mediumint':return FieldDataType.MEDIUMINT;
      case 'smallint':return FieldDataType.SMALLINT;
      case 'tinyint': return FieldDataType.TINYINT;
      case 'varchar':return FieldDataType.VARCHAR;
    }
    return null;
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("----- FieldMetaDataAccess"+SEP);
    if(fieldMetaDataList.length>0) {
      fieldMetaDataList.forEach((fmd) {
        sb.write(fmd.uniqueKey + SEP);
      });
    } else {
      sb.write("(No Fields found)"+SEP);
    }
    return sb.toString();
  }
}
