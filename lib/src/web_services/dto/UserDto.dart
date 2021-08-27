import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class UserDto extends Dto with UserMixin {
  static const String TABLE_NAME = 'user';
  UserDto();
  UserDto.field(FieldData fieldData) : super.field(fieldData);
  UserDto.list(List<dynamic> list) {
    super.field(listToFieldData(list));
  }
  UserDto.map(Map<String, dynamic> map) {
    super.field(Dto.mapToFieldData(map, UserMixin.fieldNames, UserMixin.C_TABLE_ID));
  }
  UserDto.sep(int? id, String? pass_key, int? subset, WardenType? warden, int? request_offset_secs,
      int? registered_ts) {
    super.wee(UserMixin.C_TABLE_ID);
    this.id = id;
    this.pass_key = pass_key;
    this.subset = subset;
    this.warden = warden;
    this.request_offset_secs = request_offset_secs;
    this.registered_ts = registered_ts;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(UserMixin.C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id"],
      'pass_key': ["pass_key"]
    }, crcFieldNamesList: [
      'pass_key',
      'subset',
      'warden_type',
      'request_offset_secs',
      'registered_ts'
    ], propertiesMap: {
      'min-id-for-user': DbConstants.C_MEDIUMINT_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(UserMixin.C_TABLE_ID, 'id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(UserMixin.C_TABLE_ID, 'pass_key', FieldDataType.VARCHAR,
        notNull: false, fieldSize: 20);
    schemaMetaData.addField(UserMixin.C_TABLE_ID, 'subset', FieldDataType.TINYINT);
    schemaMetaData.addField(UserMixin.C_TABLE_ID, 'warden', FieldDataType.SMALLINT);
    schemaMetaData.addField(
        UserMixin.C_TABLE_ID, 'request_offset_secs', FieldDataType.MEDIUMINT,
        notNull: false);
    schemaMetaData.addField(UserMixin.C_TABLE_ID, 'registered_ts', FieldDataType.INTEGER);
    return schemaMetaData;
  }

  String getCrcString() {
    return subset.toString()+Warden.getWardenName(warden,toUpper: true)+request_offset_secs.toString()+registered_ts.toString();
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(UserMixin.fieldNames,
        UserMixin.C_TABLE_ID);
  }

  @override
  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    map['id'] = id;
    map['pass_key'] = pass_key;
    map['subset'] = subset;
    map['warden'] = warden;
    map['request_offset_secs'] = request_offset_secs;
    map['registered_ts'] = registered_ts;
    return map;
  }
}
