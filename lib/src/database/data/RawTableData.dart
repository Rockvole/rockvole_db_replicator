import 'package:rockvole_db/rockvole_db.dart';

class RawTableData {
  int table_id;
  List<List<Object?>> _table;
  Map<String, int> _fieldNamesMap=Map();

  RawTableData(this.table_id, this._table, List<String> fieldNamesList) {
    int count = 0;
    if(_table.length>0) {
      _table[0].forEach((list) {
        if (fieldNamesList.length == 0 || fieldNamesList[count] == null) {
          _fieldNamesMap[count.toString()] = count;
        } else {
          _fieldNamesMap[fieldNamesList[count]] = count;
        }
        count++;
      });
    }
  }

  int get rowCount {
    return _table.length;
  }

  List<RawRowData> getRawRows() {
    List<RawRowData> rows=[];
    _table.forEach((List<Object?> list) {
      rows.add(RawRowData.sep(table_id, list, _fieldNamesMap));
    });
    return rows;
  }

  RawRowData getRawRowData(int rowNum) {
    return RawRowData.sep(table_id, _table[rowNum], _fieldNamesMap);
  }

  Object? getRawFieldByFieldName(int rowNum, String fieldName) {
    if(!_fieldNamesMap.containsKey(fieldName)) throw ArgumentError("Field '$fieldName' not found.");
    return _table[rowNum][_fieldNamesMap[fieldName]!];
  }

  Object? getRawField(int rowNum, int colNum) {
    return _table[rowNum][colNum];
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("RawTableData (table_id:$table_id) [");
    List<String> fieldNamesList=_fieldNamesMap.keys.toList();
    _table.forEach((List<Object?> row) {
      int count=0;
      row.forEach((Object? field) {
        String fieldName=fieldNamesList[count++];
        sb.write(fieldName+":"+field.toString()+", ");
      });
      sb.write("]"+SEP);
    });
    return sb.toString();
  }

  String toJson() {
    StringBuffer sb=StringBuffer();
    int length=_table.length;
    for(int rowNum=0;rowNum<length;rowNum++) {
      sb.write(getRawRowData(rowNum).toJson());
    }
    return sb.toString();
  }
}
