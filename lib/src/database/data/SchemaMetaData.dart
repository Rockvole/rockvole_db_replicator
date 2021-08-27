import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:yaml/yaml.dart';

enum DBType { Hsql, Mysql, Sqflite, Sqlite }
const int C_TABLE_ID_MULTIPLIER = 500;

class SchemaMetaData {
  bool isSystem=false;
  late TableMetaDataAccess _tableMetaDataAccess;
  late Map<String, String> _uniqueKeyTableMap;
  int maxTableId = 0;

  SchemaMetaData(this.isSystem) {
    _tableMetaDataAccess = TableMetaDataAccess();
    _uniqueKeyTableMap = Map();
  }

  SchemaMetaData.yaml(YamlMap yaml) {
    _tableMetaDataAccess = TableMetaDataAccess();
    _uniqueKeyTableMap = Map();
    YamlMap tables = yaml['tables'];
    tables.forEach((tableName, keys) {
      YamlMap tableYamlMap = keys;
      int table_id = tableYamlMap['id'];
      _addTableFromYamlMap(table_id, tableName,
          uniqueKeysMap: tableYamlMap['unique-keys'],
          crcFieldNamesList: tableYamlMap['crc-field-names'],
          propertiesMap: tableYamlMap['properties-map']);
      // ------------------------------------------ Fields
      YamlMap fields = tableYamlMap['fields'];
      fields.forEach((fieldName, keys) {
        _addFieldFromYamlMap(table_id, fieldName, keys);
      });
    });
  }

  void _addTableFromYamlMap(int table_id, String tableName,
      {YamlMap? uniqueKeysMap = null,
      YamlList? crcFieldNamesList,
      YamlMap? propertiesMap}) {
    Map<String, List<String>> uniqueKeysMap2 = Map();
    uniqueKeysMap?.forEach((key, value) {
      List<String> list = [];
      (value as YamlList).forEach((element) {
        list.add(element);
      });
      uniqueKeysMap2[key] = list;
    });
    List<String> crcFieldNamesList2 = [];
    crcFieldNamesList?.forEach((element) {
      crcFieldNamesList2.add(element);
    });
    Map<String, Object> propertiesMap2 = Map();
    propertiesMap?.forEach((key, value) {
      propertiesMap2[key] = value;
    });
    addTable(table_id, tableName,
        uniqueKeysMap: uniqueKeysMap2,
        crcFieldNamesList: crcFieldNamesList2,
        propertiesMap: propertiesMap2);
  }

  void addTable(int table_id, String tableName,
      {Map<String, List<String>>? uniqueKeysMap = null,
      List<String>? crcFieldNamesList,
      Map<String, Object>? propertiesMap}) {
    if (table_id > maxTableId) maxTableId = table_id;
    _tableMetaDataAccess.addTable(
        table_id, tableName, uniqueKeysMap, crcFieldNamesList,
        propertyMap: propertiesMap);
  }

  void _addFieldFromYamlMap(int table_id, String fieldName, YamlMap fieldDataType) {
    int fieldSize=fieldDataType['field-size']??10;
    bool notNull=fieldDataType['not-null']??true;
    bool autoIncrement=fieldDataType['auto-increment']??false;
    addField(table_id, fieldName, FieldMetaDataAccess.getFieldDataTypeFromString(fieldDataType['type'])!, fieldSize: fieldSize, notNull: notNull, autoIncrement: autoIncrement);
  }

  void addField(int table_id, String fieldName, FieldDataType fieldDataType,
      {int fieldSize = 10, bool notNull = true, bool autoIncrement = false}) {
    int maxTableFieldId =
        getTableByTableId(table_id).fieldMetaDataAccess.maxTableFieldId;
    if (maxTableFieldId == 0)
      maxTableFieldId =
          getTableByTableId(table_id).table_id * C_TABLE_ID_MULTIPLIER;
    maxTableFieldId++;
    FieldMetaData fmd = getTableByTableId(table_id)
        .fieldMetaDataAccess
        .addField(maxTableFieldId, table_id, fieldName, fieldDataType,
            fieldSize, notNull, autoIncrement);
    if (_uniqueKeyTableMap.containsKey(fmd.uniqueKey))
      throw ArgumentError("uniqueKey '${fmd.uniqueKey}' must be unique");
    _uniqueKeyTableMap[fmd.uniqueKey] = table_id.toString();
  }

  TableMetaData getTableByTableId(int table_id) =>
      _tableMetaDataAccess.getTableMetaDataByTableId(table_id);

  TableMetaData? getTableByName(String tableName) {
    if (!_tableMetaDataAccess.doesTableExist(tableName))
      throw ArgumentError("SchemaMetaData does not contain $tableName table.");
    return _tableMetaDataAccess.getTableMetaDataByTableName(tableName);
  }

  FieldMetaData? getFieldByTableFieldId(int table_field_id) {
    FieldMetaData? returnFmd = null;
    getTableMetaDataList().forEach((tmd) {
      tmd.getFieldList().forEach((fmd) {
        if (fmd.table_field_id == table_field_id) returnFmd = fmd;
      });
    });
    return returnFmd;
  }

  bool doesTableExist(String tableName) =>
      _tableMetaDataAccess.doesTableExist(tableName);

  List<TableMetaData> getTableMetaDataList({bool includeComms = true}) =>
      _tableMetaDataAccess.getTableMetaDataList(includeComms: includeComms);

  FieldMetaData getField(int table_id, String fieldName) =>
      getTableByTableId(table_id).getFieldByFieldName(fieldName);

  String toJson() {
    StringBuffer sb = StringBuffer();
    getTableMetaDataList().forEach((tmd) {
      sb.write(tmd.toJson() + ",\n");
    });
    return sb.toString();
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    getTableMetaDataList().forEach((tmd) {
      sb.write(tmd.toString());
    });
    return sb.toString();
  }
}
