import 'package:rockvole_db_replicator/rockvole_data.dart';

class DataTools {
  static String convertUniqueKey(int table_id, String? fieldName) {
    if (table_id == null) return fieldName.toString().toUpperCase();
    return table_id.toString() + "." + fieldName.toString().toUpperCase();
  }

  // Use the list of unique keys in the table to append where data to TableData
  static WhereData appendWhereDataWithUniqueKeys(FieldData fieldData,
      WhereData whereData, SchemaMetaData smd) {
    Map<String, List<String>> uniqueKeyMap =
        smd.getTableByTableId(fieldData.table_id).uniqueKeyMap!;
    List<String> list = uniqueKeyMap.keys.toList();
    List<String> uniqueKeyList = uniqueKeyMap[list[0]]!;
    uniqueKeyList.forEach((fieldName) {
      whereData.set(fieldName, SqlOperator.EQUAL,
          fieldData.get(fieldName, field_table_id: fieldData.table_id),
          table_id: fieldData.table_id);
    });
    return whereData;
  }

  static String getCrcFromTable(
      int table_id, FieldData fieldData, SchemaMetaData smdSys) {
    String tableName=smdSys.getTableByTableId(table_id).table_name;
    String crc = "";
    TableMetaData tmd = smdSys.getTableByName(tableName)!;
    tmd.crcFieldNamesList?.forEach((String fieldName) {
      crc += fieldData.get(fieldName).toString();
    });
    return crc;
  }
}
