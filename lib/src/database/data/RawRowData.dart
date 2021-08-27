import 'package:rockvole_db/rockvole_db.dart';

class RawRowData {
  int table_id;
  late List<Object?> _row;
  late Map<String, int> _fieldNamesMap;

  RawRowData(this.table_id) {
    _row = [];
    _fieldNamesMap = Map();
  }
  RawRowData.sep(this.table_id, this._row, this._fieldNamesMap);

  bool contains(String fieldName) => _fieldNamesMap.containsKey(fieldName);
  List<String> get fieldNames => _fieldNamesMap.keys.toList();

  Object? getField(int colNum) => _row[colNum];

  Object? get(String fieldName, Object? notFoundValue) {
    if (!_fieldNamesMap.containsKey(fieldName)) return notFoundValue;
    return _row[_fieldNamesMap[fieldName]!];
  }

  void set(String fieldName, Object? fieldValue) {
    if (_fieldNamesMap.containsKey(fieldName)) {
      _row[_fieldNamesMap[fieldName]!] = fieldValue;
    } else {
      addField(fieldName, fieldValue);
    }
  }

  void append(RawRowData rawRowData) {
    if (rawRowData != null) {
      Map<String, Object?> map = rawRowData.getRawRowDataMap();
      map.forEach((fieldName, fieldValue) {
        set(fieldName, fieldValue);
      });
    }
  }

  Map<String, Object?> getRawRowDataMap() {
    Map<String, Object?> map = Map();
    _fieldNamesMap.forEach((fieldName, colNum) {
      map[fieldName] = _row[colNum];
    });
    return map;
  }

  FieldData getFieldData({int? field_table_id}) {
    FieldData fieldData = FieldData.wee(table_id);
    _fieldNamesMap.forEach((fieldName, colNum) {
      fieldData.set(fieldName, _row[colNum], field_table_id: field_table_id);
    });
    return fieldData;
  }

  void addField(String? fieldName, Object? value) {
    if (_fieldNamesMap.containsKey(fieldName))
      throw ArgumentError("Field already exists");
    int length = _row.length;
    _row.add(value);
    _fieldNamesMap[fieldName!] = length;
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("=== RowData ===" + SEP);
    bool isFirst = true;
    _fieldNamesMap.forEach((k, v) {
      if (!isFirst) sb.write(", ");
      sb.write("$k=");
      sb.write(getField(v).toString());
      isFirst = false;
    });
    sb.write(SEP);
    return sb.toString();
  }

  String toJson() {
    StringBuffer sb = StringBuffer();
    bool isFirst = true;
    sb.write("{");
    _fieldNamesMap.forEach((String fieldName, v) {
      if (!isFirst) sb.write(", ");
      sb.write("$fieldName:");
      sb.write(getField(v).toString());
      isFirst = false;
    });
    sb.write("}");
    return sb.toString();
  }
}
