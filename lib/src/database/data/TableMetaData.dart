import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

enum SortOrderType {
  PRIMARY_KEY_ASC,
  PRIMARY_KEY_DESC,
  COLUMN_ASC,
  COLUMN_DESC
}

class TableMetaData {
  static final int C_COMMS_TABLE_MAX_ID = 99;
  int table_id;
  String table_name;
  Map<String, List<String>>? uniqueKeyMap;
  List<String>? crcFieldNamesList;

  Map<String, Object>? _propertiesMap;
  late FieldMetaDataAccess fieldMetaDataAccess;

  TableMetaData(this.table_id, this.table_name, this.uniqueKeyMap,
      this.crcFieldNamesList) {
    fieldMetaDataAccess = FieldMetaDataAccess();
    _propertiesMap = Map();
  }

  FieldMetaData getFieldByIndex(int index) => fieldMetaDataAccess.getFieldByIndex(index);

  FieldMetaData getFieldByTableFieldId(int table_field_id) =>
      fieldMetaDataAccess.getFieldByTableFieldId(table_field_id);

  FieldMetaData getFieldByFieldName(String fieldName) =>
      fieldMetaDataAccess.getFieldByFieldName(fieldName);

  List<FieldMetaData> getFieldList() => fieldMetaDataAccess.fieldMetaDataList;

  Map<String, Object> getFieldNameMapByTableFieldIdMap(
          Map<int, Object> tableFieldIdMap) =>
      fieldMetaDataAccess.getFieldNameMapByTableFieldIdMap(tableFieldIdMap);

  Object getProperty(String propertyName) {
    if (_propertiesMap!.containsKey(propertyName))
      return _propertiesMap![propertyName]!;
    throw ArgumentError(
        "Property '$propertyName' not found in table: '$table_name'");
  }

  void setPropertyMap(Map<String, Object>? pm) => _propertiesMap = pm;
  void setProperty(String propertyName, Object value) =>
      _propertiesMap![propertyName] = value;
  Map<String, Object> get propertyMap => Map.from(_propertiesMap!);

  FieldData getSelectFieldData(int table_id) {
    FieldData fieldData = FieldData.wee(table_id);
    getFieldList().forEach((FieldMetaData fmd) {
      fieldData.set(fmd.fieldName, null, field_table_id: table_id);
    });
    return fieldData;
  }

  String toJson() {
    StringBuffer sb = StringBuffer();
    bool isFirst = true;
    getFieldList().forEach((fmd) {
      if (!isFirst) sb.write(",\n");
      sb.write("{" + fmd.toJson() + "}");
      isFirst = false;
    });
    return sb.toString();
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("---------------- TABLE" + SEP);
    sb.write("table_id   : $table_id" + SEP);
    sb.write("table_name : $table_name" + SEP);
    sb.write("---------------- FIELDS" + SEP);
    List<FieldMetaData> list = getFieldList();
    if (list == null || list.length == 0)
      sb.write("<No Fields>" + SEP);
    else {
      getFieldList().forEach((fmd) {
        sb.write(fmd);
      });
    }
    sb.write("---------------- PROPERTIES" + SEP);
    if (_propertiesMap == null)
      sb.write("<No Properties>" + SEP);
    else {
      _propertiesMap!.forEach((k, v) {
        sb.write("$k:$v,");
      });
      sb.write(SEP);
    }
    return sb.toString();
  }
}

class TableMetaDataAccess {
  late List<TableMetaData> _tableMetaDataList;
  late int maxTableId;

  late Map<int, TableMetaData> _tableIdMap;
  late Map<String, TableMetaData> _tableNameMap;

  TableMetaDataAccess() {
    _tableMetaDataList = [];
    _tableIdMap = Map();
    _tableNameMap = Map();
  }

  void addTable(int table_id, String tableName,
      Map<String, List<String>>? uniqueKeysMap, List<String>? crcFieldNamesList,
      {Map<String, Object>? propertyMap}) {
    TableMetaData tmd =
        TableMetaData(table_id, tableName, uniqueKeysMap, crcFieldNamesList);
    tmd.setPropertyMap(propertyMap);
    maxTableId = table_id;
    _tableMetaDataList.add(tmd);
    if (_tableIdMap.containsKey(tmd.table_id))
      throw ArgumentError("table_id ${tmd.table_id} already exists.");
    _tableIdMap[tmd.table_id] = tmd;
    _tableNameMap[tmd.table_name] = tmd;
  }

  List<TableMetaData> getTableMetaDataList({bool includeComms = true}) {
    if (includeComms) return _tableMetaDataList;
    List<TableMetaData> list = [];
    _tableMetaDataList.forEach((TableMetaData tmd) {
      if (tmd.table_id > TableMetaData.C_COMMS_TABLE_MAX_ID &&
          tmd.table_id != TransactionTools.C_MAX_INT_TABLE_ID) list.add(tmd);
    });
    return list;
  }

  TableMetaData getTableMetaDataByTableId(int table_id) {
    if (!_tableIdMap.containsKey(table_id))
      throw ArgumentError("table_id ${table_id} doesn't exist.");
    return _tableIdMap[table_id]!;
  }

  TableMetaData getTableMetaDataByTableName(String tableName) {
    return _tableNameMap[tableName]!;
  }

  List<FieldMetaData> getFieldMetaDataListByTableName(
      int table_id, List<FieldMetaData> fieldMetaDataList) {
    List<FieldMetaData> fmdList = [];
    fieldMetaDataList.forEach((fmd) {
      if (fmd.table_id == table_id) fmdList.add(fmd);
    });
    return fmdList;
  }

  bool doesTableExist(String tableName) => _tableNameMap.containsKey(tableName);
}
