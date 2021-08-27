import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class TrDto extends FieldData {
  static const List<String> trFieldNames = [
    "ts",
    "operation",
    "user_id",
    "user_ts",
    "comment",
    "crc"
  ];
  TrDto();
  TrDto.wee(int table_id) : super.wee(table_id);
  TrDto.field(FieldData fieldData, {int? field_table_id}) {
    super.wee(fieldData.table_id,
        fieldData: fieldData, field_table_id: field_table_id);
  }
  TrDto.sep(int? ts, OperationType? operation, int? user_id, int? user_ts,
      String? comment, int? crc, int table_id,
      {FieldData? fieldData}) {
    sep(ts, operation, user_id, user_ts, comment, crc, table_id,
        fieldData: fieldData);
  }

  TrDto.clone(TrDto? trDto, {FieldData? fieldData, int? table_id}) {
    clone(trDto, fieldData: fieldData);
  }
  void clone(TrDto? trDto, {FieldData? fieldData, int? table_id}) {
    if(trDto==null && table_id==null) throw ArgumentError("table_id must be passed when TrDto is null");
    if (trDto == null) trDto = TrDto.wee(table_id!);
    sep(trDto.ts, trDto.operation, trDto.user_id, trDto.user_ts, trDto.comment,
        trDto.crc, trDto.table_id,
        fieldData: fieldData);
  }

  void list(List<dynamic> list, int offset, int table_id,
      {FieldData? fieldData}) {
    int ts = list[offset];
    OperationType? operationType =
        OperationTypeAccess.getOperationType(list[offset + 1]);
    int userId = list[offset + 2];
    int userTs = list[offset + 3];
    String comment = list[offset + 4];
    int crc = list[offset + 5];
    sep(ts, operationType, userId, userTs, comment, crc, table_id,
        fieldData: fieldData);
  }

  void sep(int? ts, OperationType? operation, int? user_id, int? user_ts,
      String? comment, int? crc, int table_id,
      {FieldData? fieldData}) {
    super.wee(table_id, fieldData: fieldData);
    this.ts = ts;
    this.operation = operation;
    this.user_id = user_id;
    this.user_ts = user_ts;
    this.comment = comment;
    this.crc = crc;
  }

  TrDto get getTrDto => this;

  FieldData get getFieldDataNoTr {
    FieldData fd = FieldData.wee(table_id);
    List<FieldStruct> list = getFieldStructList;
    list.forEach((fs) {
      if (!trFieldNames.contains(fs.fieldName)) fd.set(fs.fieldName, fs.value);
    });
    return fd;
  }

  FieldData get getFieldData {
    FieldData fd = FieldData.wee(table_id);
    List<FieldStruct> list = getFieldStructList;
    list.forEach((fs) {
      fd.set(fs.fieldName, fs.value);
    });
    return fd;
  }

  WhereData getWhereData() {
    WhereData whereData = WhereData();
    whereData.set('ts', SqlOperator.EQUAL, ts);
    whereData.set('operation', SqlOperator.EQUAL, operation);
    whereData.set('user_id', SqlOperator.EQUAL, user_id);
    whereData.set('user_ts', SqlOperator.EQUAL, user_ts);
    whereData.set('comment', SqlOperator.EQUAL, comment);
    whereData.set('crc', SqlOperator.EQUAL, crc);
    return whereData;
  }

  SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) =>
      schemaMetaData;

  int? get id => get("id") as int;
  set id(int? id) => set("id", id);
  int? get ts => get("ts") as int;
  set ts(int? ts) => set("ts", ts);
  OperationType? get operation =>
      OperationTypeAccess.getOperationType(get("operation") as int);
  set operation(OperationType? operationType) =>
      set("operation", OperationTypeAccess.getOperationValue(operationType));
  int? get user_id => get("user_id") as int;
  set user_id(int? userId) => set("user_id", userId);
  int? get user_ts => get("user_ts") as int;
  set user_ts(int? user_ts) => set("user_ts", user_ts);
  String? get comment => get("comment") as String;
  set comment(String? comment) => set("comment", comment);
  int? get crc => get("crc") as int;
  set crc(int? crc) => set("crc", crc);

  @override
  Map<String, dynamic> toMap({bool fullEnum = false}) {
    Map<String, dynamic> map = Map();
    getFieldStructList.forEach((fs) {
      if (fullEnum && fs.fieldName == 'operation') {
        map[fs.fieldName!] =
            OperationTypeAccess.getOperationType(fs.value as int);
      } else {
        map[fs.fieldName!] = fs.value;
      }
    });
    return map;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("HistoricalChangesDto (" + table_id.toString() + ") [");
    bool isFirst = true;
    getFieldStructList.forEach((fs) {
      if (!isFirst) sb.write(", ");
      sb.write("${fs.fieldName}:");
      if (fs.fieldName == 'operation') {
        sb.write(
            OperationTypeAccess.getOperationType(fs.value as int).toString());
      } else {
        sb.write(fs.value.toString());
      }
      isFirst = false;
    });
    sb.write(" ]");
    return sb.toString();
  }
}
