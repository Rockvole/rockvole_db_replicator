import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class UserStoreDto extends Dto with UserStoreMixin {
  static const String TABLE_NAME = 'user_store';
  UserStoreDto();
  UserStoreDto.field(FieldData fieldData) : super.field(fieldData);
  UserStoreDto.list(List<dynamic> list) {
    super.field(listToFieldData(list));
  }
  UserStoreDto.map(Map<String, dynamic> map) {
    super.field(Dto.mapToFieldData(map, UserStoreMixin.fieldNames, UserStoreMixin.C_TABLE_ID));
  }
  UserStoreDto.sep(
      int? id,
      String? email,
      int? last_seen_ts,
      String? name,
      String? surname,
      int? records_downloaded,
      int? changes_approved_count,
      int? changes_denied_count) {
    super.wee(UserStoreMixin.C_TABLE_ID);
    this.id = id;
    this.email = email;
    this.last_seen_ts = last_seen_ts;
    this.name = name;
    this.surname = surname;
    this.records_downloaded = records_downloaded;
    this.changes_approved_count = changes_approved_count;
    this.changes_denied_count = changes_denied_count;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(UserStoreMixin.C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id"],
      'email': ["email"]
    }, crcFieldNamesList: [
      'email',
      'name',
      'surname'
    ], propertiesMap: {
      'min-id-for-user': DbConstants.C_MEDIUMINT_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(UserStoreMixin.C_TABLE_ID, 'id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(UserStoreMixin.C_TABLE_ID, 'email', FieldDataType.VARCHAR,
        notNull: false, fieldSize: 40);
    schemaMetaData.addField(UserStoreMixin.C_TABLE_ID, 'last_seen_ts', FieldDataType.INTEGER,
        notNull: false);
    schemaMetaData.addField(UserStoreMixin.C_TABLE_ID, 'name', FieldDataType.VARCHAR,
        fieldSize: 20, notNull: false);
    schemaMetaData.addField(UserStoreMixin.C_TABLE_ID, 'surname', FieldDataType.VARCHAR,
        fieldSize: 20, notNull: false);
    schemaMetaData.addField(
        UserStoreMixin.C_TABLE_ID, 'records_downloaded', FieldDataType.MEDIUMINT,
        notNull: false);
    schemaMetaData.addField(
        UserStoreMixin.C_TABLE_ID, 'changes_approved_count', FieldDataType.SMALLINT,
        notNull: false);
    schemaMetaData.addField(
        UserStoreMixin.C_TABLE_ID, 'changes_denied_count', FieldDataType.SMALLINT,
        notNull: false);
    return schemaMetaData;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(UserStoreMixin.fieldNames,
        UserStoreMixin.C_TABLE_ID);
  }

  @override
  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    map['id'] = id;
    map['email'] = email;
    map['last_seen_ts'] = last_seen_ts;
    map['name'] = name;
    map['surname'] = surname;
    map['records_downloaded'] = records_downloaded;
    map['changes_approved_count'] = changes_approved_count;
    map['changes_denied_count'] = changes_denied_count;
    return map;
  }
}
