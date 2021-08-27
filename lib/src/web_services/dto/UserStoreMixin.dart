import 'package:rockvole_db/rockvole_db.dart';

mixin UserStoreMixin on FieldData {
  static const int C_TABLE_ID = 110;
  static const List<String> fieldNames=['id','email','last_seen_ts','name','surname','records_downloaded','changes_approved_count','changes_denied_count'];

  String? get email => get('email') as String;
  set email(String? email) => set('email', email);
  int? get last_seen_ts => get('last_seen_ts') as int;
  set last_seen_ts(int? lastSeenTs) => set('last_seen_ts', lastSeenTs);
  String? get name => get('name') as String;
  set name(String? name) => set('name', name);
  String? get surname => get('surname') as String;
  set surname(String? surname) => set('surname', surname);
  int? get records_downloaded => get('records_downloaded') as int;
  set records_downloaded(int? recordsDownloaded) =>
      set('records_downloaded', recordsDownloaded);
  int? get changes_approved_count => get('changes_approved_count') as int;
  set changes_approved_count(int? changesApprovedCount) =>
      set('changes_approved_count', changesApprovedCount);
  int? get changes_denied_count => get('changes_denied_count') as int;
  set changes_denied_count(int? changesDeniedCount) =>
      set('changes_denied_count', changesDeniedCount);

  static int get min_id_for_user => DbConstants.C_MEDIUMINT_USERSPACE_MIN;
  FieldData listToFieldData(List<dynamic> list) {
    FieldData fieldData=FieldData.wee(C_TABLE_ID);
    fieldData.set('id', list[0]);
    fieldData.set('email', list[1]);
    fieldData.set('last_seen_ts', list[2]);
    fieldData.set('name', list[3]);
    fieldData.set('surname', list[4]);
    fieldData.set('records_downloaded', list[5]);
    fieldData.set('changes_approved_count', list[6]);
    fieldData.set('changes_denied_count', list[7]);
    return fieldData;
  }
}