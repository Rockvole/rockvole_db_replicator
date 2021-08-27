import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class WaterLineDto extends Dto {
  static const int C_TABLE_ID = 0;
  static const String TABLE_NAME = 'water_line';
  static const List<String> fieldNames = [
    'water_ts',
    'water_table_id',
    'water_state',
    'water_error'
  ];
  late SchemaMetaData smdSys;

  WaterLineDto();
  WaterLineDto.field(FieldData fieldData, this.smdSys) {
    super.field(fieldData);
  }
  WaterLineDto.convert(FieldData fieldData, this.smdSys) {
    super.wee(C_TABLE_ID);
    this.water_ts = fieldData.get('ts') as int; // Put TrDto.ts into water_ts
    this.water_table_id = fieldData.table_id;
    this.water_state = WaterState.SERVER_APPROVED;
    this.water_error = WaterError.NONE;
  }
  WaterLineDto.dto(WaterLineDto waterLineDto, this.smdSys) {
    super.field(waterLineDto);
  }
  WaterLineDto.list(List<dynamic> list, this.smdSys) {
    FieldData fieldData = FieldData.wee(C_TABLE_ID);
    fieldData.set('water_ts', list[0]);
    fieldData.set('water_table_id', list[1]);
    fieldData.set('water_state', list[2]);
    fieldData.set('water_error', list[3]);
    super.field(fieldData);
  }
  WaterLineDto.sep(int? water_ts, WaterState? waterState, WaterError? waterError,
      int? water_table_id, this.smdSys) {
    if (water_table_id == null)
      throw ArgumentError("water_table_id must not be null");
    super.wee(C_TABLE_ID);
    this.water_ts = water_ts;
    this.water_table_id = water_table_id;
    this.water_state = waterState;
    this.water_error = waterError;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'water_ts': ["water_ts"]
    }, crcFieldNamesList: [], propertiesMap: {
      'min-id-for-user': DbConstants.C_INTEGER_USERSPACE_MIN,
      'index': 'water_ts',
      'is-partition': false
    });
    schemaMetaData.addField(C_TABLE_ID, 'water_ts', FieldDataType.INTEGER);
    schemaMetaData.addField(
        C_TABLE_ID, 'water_table_id', FieldDataType.SMALLINT);
    schemaMetaData.addField(C_TABLE_ID, 'water_state', FieldDataType.SMALLINT);
    schemaMetaData.addField(C_TABLE_ID, 'water_error', FieldDataType.SMALLINT);
    return schemaMetaData;
  }

  int? get id => throw ArgumentError("No id for water_line");
  set id(int? id) => throw ArgumentError("No id for water_line");
  int? get water_ts => get('water_ts') as int;
  set water_ts(int? water_ts) => set('water_ts', water_ts);
  String get water_table_name =>
      smdSys.getTableByTableId(get('water_table_id') as int).table_name;
  set water_table_name(String tableIdName) =>
      set('water_table_id', smdSys.getTableByName(tableIdName)!.table_id);
  int get water_table_id => get('water_table_id') as int;
  set water_table_id(int tableId) => set('water_table_id', tableId);
  WaterState? get water_state => WaterStateAccess.getWaterState(get('water_state') as int,
      returnNullIfNotFound: true);
  set water_state(WaterState? waterState) =>
      set('water_state', WaterStateAccess.getWaterStateValue(waterState));
  WaterError? get water_error =>
      WaterErrorAccess.getWaterError(get('water_error') as int,
          returnNullIfNotFound: true);

  set water_error(WaterError? waterError) =>
      set('water_error', WaterErrorAccess.getWaterErrorValue(waterError));

  static int get min_id_for_user => DbConstants.C_INTEGER_USERSPACE_MIN;

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(fieldNames, C_TABLE_ID);
  }

  static FieldData getSetFieldData(int? water_ts, WaterState? waterState,
      WaterError? waterError, int? water_table_id) {
    FieldData fieldData = FieldData.wee(C_TABLE_ID);
    if (water_ts != null)
      fieldData.set('water_ts', water_ts, field_table_id: C_TABLE_ID);
    if (water_table_id != null)
      fieldData.set('water_table_id', water_table_id,
          field_table_id: C_TABLE_ID);
    if (waterState != null)
      fieldData.set('water_state', WaterStateAccess.getWaterStateValue(waterState),
          field_table_id: C_TABLE_ID);
    if (waterError != null)
      fieldData.set(
          'water_error', WaterErrorAccess.getWaterErrorValue(waterError),
          field_table_id: C_TABLE_ID);
    return Dto.generateSelectFieldData(fieldNames, C_TABLE_ID,
        fieldData: fieldData);
  }

  static WhereData getWhereData(int water_ts, WaterState? waterState,
      WaterError? waterError, int? water_table_id) {
    WhereData whereData = WhereData();
    whereData.set('water_ts', SqlOperator.EQUAL, water_ts);
    whereData.set('water_state', SqlOperator.EQUAL,
        WaterStateAccess.getWaterStateValue(waterState));
    whereData.set('water_error', SqlOperator.EQUAL,
        WaterErrorAccess.getWaterErrorValue(waterError));
    whereData.set('water_table_id', SqlOperator.EQUAL, water_table_id);
    return whereData;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("WaterLineDto [");
    sb.write(
        "water_ts:$water_ts, water_table_id:$water_table_id, water_state:$water_state, water_error:$water_error");
    sb.write(" ]\n");
    return sb.toString();
  }

  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    map["water_ts"] = water_ts;
    map["water_table_id"] = water_table_id;
    map["water_state"] =
        fullEnum ? water_state : WaterStateAccess.getWaterStateValue(water_state);
    map["water_error"] = fullEnum
        ? water_error
        : WaterErrorAccess.getWaterErrorValue(water_error);
    return map;
  }
}
