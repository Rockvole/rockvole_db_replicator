import 'package:rockvole_db_replicator/rockvole_db.dart';

abstract class Dto extends FieldData {
  Dto();
  Dto.wee(int table_id) : super.wee(table_id);
  Dto.field(FieldData fieldData, {int? field_table_id}) {
    field(fieldData, field_table_id: field_table_id);
  }
  void field(FieldData fieldData, {int? field_table_id}) {
    super.wee(fieldData.table_id,
        fieldData: fieldData, field_table_id: field_table_id);
  }

  int? get id => get("id") as int;
  set id(int? id) => set("id", id);

  static TableData getSelectFieldData() =>
      throw ArgumentError("Must be overridden");

  static FieldData generateSelectFieldData(
      List<String> fields, int field_table_id,
      {FieldData? fieldData}) {
    FieldData returnFieldData = FieldData.wee(field_table_id);
    fields.forEach((fieldName) {
      Object? fieldValue = fieldData?.get(fieldName);
      returnFieldData.set(fieldName, fieldValue,
          field_table_id: field_table_id);
    });
    return returnFieldData;
  }

  static FieldData mapToFieldData(
      Map<String, dynamic> map, List<String> fields, int table_id) {
    FieldData fieldData = FieldData.wee(table_id);
    fields.forEach((name) {
      fieldData.set(name, map[name]);
    });
    return fieldData;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    List<FieldStruct> list = getFieldStructList;
    if (list.length > 0) {
      list.forEach((fs) {
        sb.write(fs.fieldName.toString() + "=" + fs.value.toString() + "||");
      });
    }
    return sb.toString();
  }
}
