import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

mixin UserMixin on FieldData {
  static const int C_TABLE_ID = 105;
  static const List<String> fieldNames=['id','pass_key','subset','warden','request_offset_secs','registered_ts'];

  String? get pass_key => get('pass_key') as String;
  set pass_key(String? passKey) => set('pass_key', passKey);
  int? get subset => get('subset') as int;
  set subset(int? subset) => set('subset', subset);
  WardenType? get warden => Warden.getWardenType(get('warden') as int);
  set warden(WardenType? wardenType) =>
      set('warden', Warden.getWardenValue(wardenType));
  int? get request_offset_secs => get('request_offset_secs') as int;
  set request_offset_secs(int? requestOffsetSecs) =>
      set('request_offset_secs', requestOffsetSecs);
  int? get registered_ts => get('registered_ts') as int;
  set registered_ts(int? registeredTs) =>
      set('registered_ts', registeredTs);

  static int get min_id_for_user => DbConstants.C_MEDIUMINT_USERSPACE_MIN;
  FieldData listToFieldData(List<dynamic> list) {
    FieldData fieldData=FieldData.wee(C_TABLE_ID);
    fieldData.set('id', list[0]);
    fieldData.set('pass_key', list[1]);
    fieldData.set('subset', list[2]);
    fieldData.set('warden', list[3]);
    fieldData.set('request_offset_secs', list[4]);
    fieldData.set('registered_ts', list[5]);
    return fieldData;
  }
}