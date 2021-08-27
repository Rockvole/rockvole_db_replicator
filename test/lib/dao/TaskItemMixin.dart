import 'package:rockvole_db_replicator/rockvole_db.dart';

mixin TaskItemMixin on FieldData {
  static const int C_TABLE_ID = 1001;
  static const List<String> fieldNames = [
    'id',
    'task_id',
    'item_description',
    'item_complete'
  ];

  int get task_id => get('task_id') as int;
  set task_id(int task_id) => set('task_id', task_id);
  String get item_description => get('item_description') as String;
  set item_description(String item_description) =>
      set('item_description', item_description);
  bool get item_complete => get('item_complete') == 1 ? true : false;
  set item_complete(bool item_complete) =>
      set('item_complete', item_complete ? 1 : 0);

  static int get min_id_for_user => DbConstants.C_INTEGER_USERSPACE_MIN;
  FieldData listToFieldData(List<dynamic> list) {
    FieldData fieldData=FieldData.wee(C_TABLE_ID);
    String l3=list[3].toString();
    fieldData.set('id', list[0]);
    fieldData.set('task_id', list[1]);
    fieldData.set('item_description', list[2]);
    fieldData.set('item_complete', l3);
    return fieldData;
  }
}