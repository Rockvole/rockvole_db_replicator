import 'package:rockvole_db/rockvole_db.dart';

class FieldStruct {
  int field_table_id;
  String? fieldName;
  Object? value;

  FieldStruct(this.field_table_id, this.fieldName, this.value) {
    //if (field_table_id == null)
    //  throw ArgumentError("field_table_id must not be null");
  }

  String toJson({bool includeTableName = false}) {
    StringBuffer sb = StringBuffer();
    sb.write("{ '");
    if (includeTableName) sb.write("tableName.");
    sb.write("$fieldName':$value }");
    return sb.toString();
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("=== FieldStruct ===" + SEP);
    sb.write("field_table_id : $field_table_id" + SEP);
    sb.write("fieldName      : $fieldName" + SEP);
    sb.write("value          : $value" + SEP);
    return sb.toString();
  }
}

class FieldData {
  late int table_id;
  late List<FieldStruct> _fieldStructList;
  late Map<String, int> _fieldDataMap;

  FieldData();
  FieldData.wee(this.table_id) {
    wee(table_id);
  }
  FieldData.field(FieldData fieldData) {
    wee(fieldData.table_id, fieldData: fieldData);
  }
  FieldData.rawRowData(RawRowData rawRowData, this.table_id) {
    Map<String, Object?> map = rawRowData.getRawRowDataMap();
    FieldData fieldData=FieldData.wee(table_id);
    map.forEach((fieldName, value) {
      fieldData.set(fieldName, value);
    });
    wee(table_id, fieldData: fieldData);
  }

  void wee(int table_id, {FieldData? fieldData, int? field_table_id}) {
    //if (table_id == null) throw ArgumentError("table_id must be passed");
    this.table_id = table_id;
    _fieldStructList = [];
    _fieldDataMap = Map();
    if (fieldData != null) append(fieldData, field_table_id: field_table_id);
  }

  bool contains(String fieldName, {int? field_table_id}) =>
      _fieldDataMap.containsKey(
          DataTools.convertUniqueKey(field_table_id ?? table_id, fieldName));

  Object? get(String fieldName, {int? field_table_id, Object? notFoundValue}) {
    String uniqueKey =
        DataTools.convertUniqueKey(field_table_id ?? table_id, fieldName);
    bool containsField = false;
    _fieldStructList.forEach((fs) {
      String uk = DataTools.convertUniqueKey(fs.field_table_id, fs.fieldName);
      if (uk == uniqueKey) containsField = true;
    });
    if (!containsField) return notFoundValue;
    return _fieldStructList[_fieldDataMap[uniqueKey]!].value;
  }

  void set(String? fieldName, Object? value,
      {int? field_table_id, Type? targetType}) {
    if (fieldName == null) throw ArgumentError("fieldName must not be null");
    int? tid = field_table_id ?? table_id;
    if (tid == null) throw ArgumentError("There must be a table_id.");
    if (targetType == int) {
      // Values which are supposed to be ints but are empty strings should be null
      if (value.runtimeType == String) {
        String v = value as String;
        if (v.length == 0) value = null;
      }
    }
    FieldStruct fs = FieldStruct(tid, fieldName, value);
    int index = _fieldStructList.length;
    String uniqueKey = DataTools.convertUniqueKey(tid, fieldName);
    if (_fieldDataMap.containsKey(uniqueKey)) {
      _fieldStructList[_fieldDataMap[uniqueKey]!] = fs;
    } else {
      _fieldStructList.add(fs);
      _fieldDataMap[uniqueKey] = index;
    }
  }

  void append(FieldData fieldData, {int? field_table_id}) {
    if (fieldData != null) {
      List<FieldStruct> list = fieldData._fieldStructList;
      list.forEach((FieldStruct fs) {
        int fti = field_table_id ?? fs.field_table_id;
        set(fs.fieldName, fs.value, field_table_id: fti);
      });
    }
  }

  void addFieldSql(String sql) {
    FieldStruct fs = FieldStruct(table_id, null, SqlKeyword(sql));
    _fieldStructList.add(fs);
  }

  set setFieldDataValuesList(List<dynamic> list) {
    int count = 0;
    list.forEach((element) {
      _fieldStructList[count] = list[count];
      count++;
    });
  }

  List<FieldStruct> get getFieldStructList => _fieldStructList;

  List<Object?> get getFieldDataValuesList {
    List<Object?> list = [];
    _fieldStructList.forEach((v) {
      list.add(v.value);
    });
    return list;
  }

  List<String> get getFieldNameList {
    List<String> list = [];
    _fieldStructList.forEach((v) {
      if(v.fieldName!=null) list.add(v.fieldName!);
    });
    return list;
  }

  RawRowData getRawRowData() {
    RawRowData rawRowData = RawRowData(table_id);
    _fieldStructList.forEach((fd) {
      rawRowData.addField(fd.fieldName, fd.value);
    });
    return rawRowData;
  }

  List<dynamic> toList() {
    List<dynamic> list = [];
    _fieldStructList.forEach((fd) {
      list.add(fd.value);
    });
    return list;
  }

  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    _fieldStructList.forEach((fd) {
      map[fd.fieldName!] = fd.value;
    });
    return map;
  }

  String toJson({bool includeTableName = false}) {
    StringBuffer sb = StringBuffer();
    bool isFirst = true;
    _fieldStructList.forEach((fd) {
      if (!isFirst) sb.write(", ");
      sb.write(fd.toJson(includeTableName: includeTableName));
      isFirst = false;
    });
    return sb.toString();
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("====== FieldDataList ======\n");
    sb.write(("table_id: $table_id\n"));
    if (_fieldStructList.length > 0) {
      _fieldStructList.forEach((fd) {
        sb.write(fd.toString());
      });
    } else {
      sb.write("(No field data)\n");
    }
    return sb.toString();
  }
}
