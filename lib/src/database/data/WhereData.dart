import 'package:rockvole_db_replicator/rockvole_db.dart';

enum SqlOperator {
  MAX,
  EQUAL,
  LESS,
  GREATER,
  LESS_EQUAL,
  GREATER_EQUAL,
  LIKE,
  LIKE_START,
  MATCH,
  IN,
  NOT_IN,
  IS
}

class WhereStruct {
  int? table_id;
  String fieldName;
  SqlOperator sqlOperator;
  Object? value;

  WhereStruct(this.table_id, this.fieldName, this.sqlOperator, Object? value) {
    if (value is List) {
      StringBuffer sb = StringBuffer();
      bool isFirst = true;
      value.forEach((o) {
        if (!isFirst) sb.write(",");
        sb.write(o.toString());
        isFirst = false;
      });
      value = sb.toString();
    }
    this.value = value;
  }

  String toJson({bool includeTableName = false}) {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("{ '");
    if (includeTableName) sb.write("$table_id.");
    sb.write("$fieldName " +
        WhereData.getSqlOperatorString(sqlOperator) +
        "':'$value' }" +
        SEP);
    return sb.toString();
  }

  @override
  String toString() {
    String SEP = "\n";
    StringBuffer sb = StringBuffer();
    sb.write("=== WhereData ===" + SEP);
    sb.write("table_id    : $table_id" + SEP);
    sb.write("fieldName   : $fieldName" + SEP);
    sb.write(
        "sqlOperator : " + WhereData.getSqlOperatorString(sqlOperator) + SEP);
    sb.write("value       : $value" + SEP);
    return sb.toString();
  }
}

enum OrderType { ASC, DESC }

class OrderStruct {
  String orderFieldName;
  OrderType orderType;

  OrderStruct(this.orderFieldName,this.orderType);
}

class WhereData {
  late List<WhereStruct> _whereStructList;
  late List<OrderStruct> _orderStructList;
  int? limit;

  WhereData() {
    _whereStructList = [];
    _orderStructList = [];
  }

  bool contains(String fieldName, {int? table_id}) {
    bool alreadyExists = false;
    int whereLength = _whereStructList.length;
    for (int i = 0; i < whereLength; i++) {
      if (_whereStructList[i].table_id == table_id &&
          _whereStructList[i].fieldName == fieldName) {
        alreadyExists = true;
      }
    }
    return alreadyExists;
  }

  void set(String fieldName, SqlOperator sqlOperator,
      Object? value, {int? table_id}) {
    bool alreadyExists = false;
    WhereStruct whereStruct =
        WhereStruct(table_id, fieldName, sqlOperator, value);
    int whereLength = _whereStructList.length;
    for (int i = 0; i < whereLength; i++) {
      if (_whereStructList[i].table_id == table_id &&
          _whereStructList[i].fieldName == fieldName) {
        _whereStructList[i] = whereStruct;
        alreadyExists = true;
      }
    }
    if (!alreadyExists) {
      _whereStructList.add(whereStruct);
    }
  }

  void addOrder(String orderFieldName, OrderType orderType) {
    OrderStruct orderStruct = OrderStruct(orderFieldName, orderType);
    _orderStructList.add(orderStruct);
  }

  /**
   * If value is null then search value IS NULL
   */
  void addWhereFindNull(String fieldName, Object? value, {int? table_id}) {
    if (value == null) {
      WhereStruct whereStruct=WhereStruct(table_id, fieldName, SqlOperator.IS, SqlKeyword("NULL"));
      _whereStructList.add(whereStruct);
    } else {
      WhereStruct whereStruct=WhereStruct(table_id, fieldName, SqlOperator.EQUAL, value);
      _whereStructList.add(whereStruct);
    }
  }

  List<WhereStruct> get whereStructList => _whereStructList;
  List<OrderStruct> get orderStructList => _orderStructList;

  static String getSqlOperatorString(SqlOperator sqlOperator) {
    switch (sqlOperator) {
      case SqlOperator.MAX:
        return "MAX";
      case SqlOperator.EQUAL:
        return "=";
      case SqlOperator.LESS:
        return "<";
      case SqlOperator.GREATER:
        return ">";
      case SqlOperator.LESS_EQUAL:
        return "<=";
      case SqlOperator.GREATER_EQUAL:
        return ">=";
      case SqlOperator.LIKE:
        return "LIKE";
      case SqlOperator.LIKE_START:
        return "LIKE";
      case SqlOperator.MATCH:
        return "MATCH";
      case SqlOperator.IN:
        return "IN";
      case SqlOperator.NOT_IN:
        return "NOT IN";
      case SqlOperator.IS:
        return "IS";
    }
    return "=";
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("====== WhereDataList ======\n");
    if (_whereStructList.length > 0) {
      _whereStructList.forEach((ws) {
        sb.write(ws);
      });
    } else {
      sb.write("(No where data)\n");
    }
    return sb.toString();
  }

  String toJson({bool includeTableName = false}) {
    StringBuffer sb = StringBuffer();
    bool isFirst = true;
    if(_whereStructList!=null) {
      _whereStructList.forEach((ws) {
        if (!isFirst) sb.write(", ");
        sb.write(ws.toJson(includeTableName: includeTableName));
        isFirst = false;
      });
    }
    return sb.toString();
  }
}
