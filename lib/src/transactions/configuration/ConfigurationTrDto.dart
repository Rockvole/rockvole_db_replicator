import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class ConfigurationTrDto extends TrDto with ConfigurationMixin {
  static const String TABLE_NAME =
      'configuration' + TransactionTools.C_TABLE_EXT;

  ConfigurationTrDto.field(
      FieldData fieldData, ConfigurationNameDefaults? defaults) {
    if (defaults == null)
      throw ArgumentError(AbstractTableTransactions.C_MUST_PASS_DEFAULTS);
    table_id = ConfigurationMixin.C_TABLE_ID;
    this.defaults = defaults;
    super.wee(ConfigurationMixin.C_TABLE_ID,
        fieldData: fieldData, field_table_id: ConfigurationMixin.C_TABLE_ID);
  }
  ConfigurationTrDto.wee(ConfigurationDto configurationDto, TrDto? trDto, ConfigurationNameDefaults defaults) {
    super.clone(trDto, table_id: ConfigurationMixin.C_TABLE_ID);
    this.defaults = defaults;
    this.id = configurationDto.id;
    this.subset = configurationDto.subset;
    this.warden = configurationDto.warden;
    this.configuration_name = configurationDto.configuration_name;
    this.ordinal = configurationDto.ordinal;
    this.value_number = configurationDto.value_number;
    this.value_string = configurationDto.value_string;
  }
  ConfigurationTrDto.list(
      List<dynamic> list, ConfigurationNameDefaults defaults) {
    this.defaults = defaults;
    super.list(list, 7, ConfigurationMixin.C_TABLE_ID,
        fieldData: listToFieldData(list));
  }
  ConfigurationTrDto.sep(
      int? id,
      int? subset,
      WardenType? warden,
      ConfigurationNameEnum? configuration_name,
      int? ordinal,
      int? value_number,
      String? value_string,
      TrDto? trDto,
      ConfigurationNameDefaults defaults) {
      super.clone(trDto, table_id: ConfigurationMixin.C_TABLE_ID);
    this.defaults = defaults;
    this.id = id;
    this.subset = subset;
    this.warden = warden;
    this.configuration_name = configuration_name;
    this.ordinal = ordinal;
    this.value_number = value_number;
    this.value_string = value_string;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(
        ConfigurationMixin.fieldNames, ConfigurationMixin.C_TABLE_ID);
  }

  WhereData getWhereData() {
    WhereData whereData = super.getWhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    whereData.set('subset', SqlOperator.EQUAL, subset);
    whereData.set('warden', SqlOperator.EQUAL, warden);
    whereData.set('configuration_name', SqlOperator.EQUAL, configuration_name);
    whereData.set('value_number', SqlOperator.EQUAL, value_number);
    whereData.set('value_string', SqlOperator.EQUAL, value_string);
    return whereData;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("ConfigurationTrDto [");
    sb.write("id:$id, subset:$subset, warden:$warden, ");
    sb.write("configuration_name:$configuration_name, ordinal:$ordinal, ");
    sb.write("value_number: $value_number, value_string: $value_string ]");
    sb.write(super.toString());
    return sb.toString();
  }
}
