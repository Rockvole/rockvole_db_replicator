import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class WaterLineFieldDto extends Dto {
  static const int C_TABLE_ID = 5;
  static const String TABLE_NAME = 'water_line_field';
  static const List<String> fieldNames = [
    'id',
    'table_field_id',
    'change_type',
    'user_id',
    'notify_state',
    'value_number',
    'ui_type',
    'local_ts',
    'remote_ts'
  ];
  late SchemaMetaData smdSys;
  static final int C_USER_ID_NONE = 0;

  WaterLineFieldDto();
  WaterLineFieldDto.field(FieldData fieldData, this.smdSys)
      : super.field(fieldData);
  WaterLineFieldDto.sep(
      int? id,
      int? table_field_id,
      ChangeType? change_type,
      int? user_id,
      NotifyState? notify_state,
      int? value_number,
      UiType? ui_type,
      int? local_ts,
      int? remote_ts,
      this.smdSys) {
    super.wee(C_TABLE_ID);
    this.id = id;
    this.table_field_id = table_field_id;
    this.change_type_enum = change_type;
    this.user_id = user_id;

    this.notify_state_enum = notify_state;
    this.value_number = value_number;
    this.ui_type = ui_type;
    this.local_ts = local_ts;
    this.remote_ts = remote_ts;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id", "table_field_id", "change_type", "user_id"]
    }, crcFieldNamesList: [], propertiesMap: {
      'min-id-for-user': DbConstants.C_MEDIUMINT_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(C_TABLE_ID, 'id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(
        C_TABLE_ID, 'table_field_id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(C_TABLE_ID, 'change_type', FieldDataType.SMALLINT);
    schemaMetaData.addField(C_TABLE_ID, 'user_id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(C_TABLE_ID, 'notify_state', FieldDataType.SMALLINT,
        notNull: false);
    schemaMetaData.addField(C_TABLE_ID, 'value_number', FieldDataType.INTEGER,
        notNull: false);
    schemaMetaData.addField(C_TABLE_ID, 'ui_type', FieldDataType.SMALLINT,
        notNull: false);
    schemaMetaData.addField(C_TABLE_ID, 'local_ts', FieldDataType.INTEGER,
        notNull: false);
    schemaMetaData.addField(C_TABLE_ID, 'remote_ts', FieldDataType.INTEGER,
        notNull: false);
    return schemaMetaData;
  }

  static int get min_id_for_user => DbConstants.C_INTEGER_USERSPACE_MIN;
  int? get table_field_id => get('table_field_id') as int;
  set table_field_id(int? table_field_id) =>
      set('table_field_id', table_field_id);
  int? get change_type => get('change_type') as int;
  set change_type(int? changeType) => set('change_type', changeType);
  ChangeType? get change_type_enum =>
      WaterLineField.getChangeType(get('change_type') as int);
  set change_type_enum(ChangeType? changeType) =>
      set('change_type', WaterLineField.getChangeTypeValue(changeType));
  int? get user_id => get('user_id') as int;
  set user_id(int? userId) => set('user_id', userId);

  int? get notify_state => get('notify_state') as int;
  set notify_state(int? notify_state) => set('notify_state',notify_state);
  NotifyState? get notify_state_enum =>
      WaterLineField.getNotifyState(get('notify_state') as int);
  set notify_state_enum(NotifyState? notify_state) =>
      set('notify_state', WaterLineField.getNotifyStateValue(notify_state));
  int? get value_number => get('value_number') as int;
  set value_number(int? valueNumber) => set('value_number', valueNumber);
  UiType? get ui_type => WaterLineField.getUiType(get('ui_type') as int);
  set ui_type(UiType? uiType) =>
      set('ui_type', WaterLineField.getUiTypeValue(uiType));
  int? get local_ts => get('local_ts') as int;
  set local_ts(int? localTs) => set('local_ts', localTs);
  int? get remote_ts => get('remote_ts') as int;
  set remote_ts(int? remoteTs) => set('remote_ts', remoteTs);

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(fieldNames, C_TABLE_ID);
  }

  @override
  String toString() {
    return "WaterLineFieldDto [" +
        "id=$id" +
        ", table_field_id=$table_field_id" +
        ", change_type=$change_type_enum" +
        ", user_id=$user_id" +
        ", notify_state=$notify_state_enum" +
        ", value_number=$value_number" +
        ", ui_type=$ui_type" +
        ", local_ts=$local_ts" +
        ", remote_ts=$remote_ts" +
        "]";
  }
}
