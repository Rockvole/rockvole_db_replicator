import 'package:rockvole_db_replicator/rockvole_db.dart';

mixin TaskMixin on FieldData {
  static const int C_TABLE_ID = 1000;
  static const List<String> fieldNames = [
    'id',
    'task_description',
    'task_complete'
  ];

  String? get task_description => get('task_description') as String;
  set task_description(String? task_description) =>
      set('task_description', task_description);
  bool? get task_complete => get('task_complete') == 1 ? true : false;
  set task_complete(bool? task_complete) =>
      set('task_complete', task_complete! ? 1 : 0);

  static int get min_id_for_user => DbConstants.C_INTEGER_USERSPACE_MIN;
  FieldData listToFieldData(List<dynamic> list) {
    FieldData fieldData=FieldData.wee(C_TABLE_ID);
    String l2=list[2].toString();
    fieldData.set('id', list[0]);
    fieldData.set('task_description', list[1]);
    fieldData.set('task_complete', l2);
    return fieldData;
  }
}