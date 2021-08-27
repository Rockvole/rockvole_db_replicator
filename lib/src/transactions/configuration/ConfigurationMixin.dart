import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

mixin ConfigurationMixin on FieldData {
  static const int C_TABLE_ID = 100;
  static const List<String> fieldNames = [
    'id',
    'subset',
    'warden',
    'configuration_name',
    'ordinal',
    'value_number',
    'value_string'
  ];
  ConfigurationNameDefaults? defaults;
  int? get id => get('id') as int;
  set id(int? id) => set('id', id);
  int? get subset => get('subset') as int;
  set subset(int? subset) => set('subset', subset);
  WardenType? get warden {
    int wardenInt = get('warden') as int;
    if (wardenInt == null) return null;
    return Warden.getWardenType(wardenInt);
  }

  set warden(WardenType? wardenType) =>
      set('warden', Warden.getWardenValue(wardenType));
  ConfigurationNameEnum? get configuration_name {
    String? configurationNameString = get('configuration_name') as String?;
    if (configurationNameString == null) return null;
    return defaults!
        .getConfigurationNameStructFromName(configurationNameString)!
        .configurationNameEnum;
  }

  set configuration_name(ConfigurationNameEnum? configurationName) {
    String? configurationNameString;
    if (configurationName != null)
      configurationNameString =
          defaults!.getConfigurationNameStruct(configurationName).name;
    set('configuration_name', configurationNameString);
  }

  int? get ordinal => get('ordinal') as int;
  set ordinal(int? ordinal) => set('ordinal', ordinal);
  int? get value_number => get('value_number') as int;
  set value_number(int? valueNumber) => set('value_number', valueNumber);
  String? get value_string => get('value_string') as String;
  set value_string(String? valueString) => set('value_string', valueString);

  static int get min_id_for_user => DbConstants.C_MEDIUMINT_USERSPACE_MIN;
  FieldData listToFieldData(List<dynamic> list) {
    FieldData fieldData = FieldData.wee(C_TABLE_ID);
    fieldData.set('id', list[0]);
    fieldData.set('subset', list[1]);
    fieldData.set('warden', list[2]);
    fieldData.set('configuration_name', list[3]);
    fieldData.set('ordinal', list[4]);
    fieldData.set('value_number', list[5], targetType: int);
    fieldData.set('value_string', list[6]);
    return fieldData;
  }
}
