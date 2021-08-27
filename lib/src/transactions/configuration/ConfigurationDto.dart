import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class ConfigurationDto extends Dto with ConfigurationMixin {
  static const String TABLE_NAME = 'configuration';

  ConfigurationDto() : super.wee(ConfigurationMixin.C_TABLE_ID);
  ConfigurationDto.list(
      List<dynamic> list, ConfigurationNameDefaults defaults) {
    this.defaults = defaults;
    super.field(listToFieldData(list));
  }
  ConfigurationDto.sep(
      int? id,
      int? subset,
      WardenType? warden,
      ConfigurationNameEnum? configuration_name,
      int? ordinal,
      int? value_number,
      String? value_string,
      ConfigurationNameDefaults defaults) {
    super.wee(ConfigurationMixin.C_TABLE_ID);
    this.defaults = defaults;
    this.id = id;
    this.subset = subset;
    this.warden = warden;
    this.configuration_name = configuration_name;
    this.ordinal = ordinal;
    this.value_number = value_number;
    this.value_string = value_string;
  }
  ConfigurationDto.field(
      FieldData fieldData, ConfigurationNameDefaults? defaults) {
    this.defaults = defaults;
    super.field(fieldData);
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData
        .addTable(ConfigurationMixin.C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id"],
      'conf': ["subset", "warden", "configuration_name", "ordinal"]
    }, crcFieldNamesList: [
      'subset',
      'warden',
      'ordinal',
      'configuration_name',
      'value_number',
      'value_string'
    ], propertiesMap: {
      'min-id-for-user': DbConstants.C_MEDIUMINT_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'id', FieldDataType.MEDIUMINT);
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'subset', FieldDataType.TINYINT);
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'warden', FieldDataType.SMALLINT);
    schemaMetaData.addField(ConfigurationMixin.C_TABLE_ID, 'configuration_name',
        FieldDataType.VARCHAR,
        fieldSize: 30);
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'ordinal', FieldDataType.SMALLINT);
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'value_number', FieldDataType.INTEGER,
        notNull: false);
    schemaMetaData.addField(
        ConfigurationMixin.C_TABLE_ID, 'value_string', FieldDataType.VARCHAR,
        notNull: false, fieldSize: 50);
    return schemaMetaData;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(ConfigurationMixin.fieldNames,
        ConfigurationMixin.C_TABLE_ID);
  }

  WhereData getWhereData() {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    whereData.set('subset', SqlOperator.EQUAL, subset);
    whereData.set('warden', SqlOperator.EQUAL, warden);
    whereData.set('configuration_name', SqlOperator.EQUAL, configuration_name);
    whereData.set('value_number', SqlOperator.EQUAL, value_number);
    whereData.set('value_string', SqlOperator.EQUAL, value_string);
    return whereData;
  }

  @override
  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    map['id'] = id;
    map['subset'] = subset;
    map['warden'] = warden;
    map['configuration_name'] = configuration_name;
    map['ordinal'] = ordinal;
    map['value_number'] = value_number;
    map['value_string'] = value_string;
    return map;
  }
}
