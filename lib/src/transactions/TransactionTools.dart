import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class TransactionTools {
  static const int C_LAST_FIELD_RECEIVED_TABLE_ID = 20;
  static const int C_MAX_INT_TABLE_ID = DbConstants.C_MEDIUMINT_MAX;

  static List<String> trFields = [
    'ts',
    'operation',
    'user_id',
    'user_ts',
    'comment',
    'crc'
  ];
  static FieldData removeTrFieldData(FieldData fieldData, {int? table_id}) {
    fieldData.getFieldStructList
        .skipWhile((sd) => trFields.contains(sd.fieldName))
        .forEach((sd) {
      fieldData.set(sd.fieldName, sd.value, field_table_id: table_id);
    });
    return fieldData;
  }
  static const String C_TABLE_EXT = "_TR";

  static SchemaMetaData createTrSchemaMetaData(SchemaMetaData smd) {
    SchemaMetaData smdSys = SchemaMetaData(true);
    smd
        .getTableMetaDataList(includeComms: false)
        .forEach((TableMetaData usrTmd) {
      String tableNameTr = usrTmd.table_name + C_TABLE_EXT;
      Map<String, List<String>> uniqueKeysMap = {
        'ts': ["ts"],
        'user_id': ["user_id", "user_ts"]
      };
      smdSys.addTable(usrTmd.table_id, tableNameTr,
          uniqueKeysMap: uniqueKeysMap, propertiesMap: usrTmd.propertyMap);
      usrTmd.getFieldList().forEach((FieldMetaData usrFmd) {
        smdSys.addField(usrFmd.table_id, usrFmd.fieldName, usrFmd.fieldDataType,
            fieldSize: usrFmd.fieldSize,
            notNull: usrFmd.notNull,
            autoIncrement: false);
      });
      smdSys.addField(usrTmd.table_id, "ts", FieldDataType.INTEGER);
      smdSys.addField(usrTmd.table_id, "operation", FieldDataType.SMALLINT);
      smdSys.addField(usrTmd.table_id, "user_id", FieldDataType.MEDIUMINT,
          notNull: false);
      smdSys.addField(usrTmd.table_id, "user_ts", FieldDataType.INTEGER,
          notNull: false);
      smdSys.addField(usrTmd.table_id, "comment", FieldDataType.VARCHAR,
          fieldSize: 150, notNull: false);
      smdSys.addField(usrTmd.table_id, "crc", FieldDataType.BIGINT,
          notNull: false);
      smdSys.getTableByName(tableNameTr)!.setProperty('index', 'ts');
    });
    // Non _TR Tables
    smdSys = WaterLineDto.addSchemaMetaData(smdSys);
    smdSys = WaterLineFieldDto.addSchemaMetaData(smdSys);
    smdSys.addTable(AuthenticationDto.C_TABLE_ID, 'authentication');
    smdSys.addTable(EntryReceivedDto.C_TABLE_ID, 'entry_received');
    smdSys.addTable(C_LAST_FIELD_RECEIVED_TABLE_ID, 'last_field_received');
    smdSys.addTable(C_MAX_INT_TABLE_ID, 'max_int');
    smdSys.addTable(RemoteStatusDto.C_TABLE_ID, 'remote_state');
    return smdSys;
  }
}
