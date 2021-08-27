import 'package:rockvole_db_replicator/rockvole_db.dart';

class WhereGenerator {
  DBType dbType;
  SchemaMetaData smd;
  WhereGenerator(this.dbType, this.smd);

  String getSetString(FieldData fieldData) {
    return _generateSet(fieldData.getFieldStructList);
  }

  String getWhereString(WhereData whereData) {
    return _generateWhere(whereData.whereStructList);
  }

  String getWhereStringNoPrefix(WhereData whereData) {
    return _generateSuffix(whereData.whereStructList, "", "AND");
  }

  String getOrderString(WhereData whereData) {
    String orderString="";
    List<OrderStruct> orderStructList = whereData.orderStructList;
    if(orderStructList.length>0) {
      orderString += " ORDER BY ";
      Iterator<OrderStruct> iter = orderStructList.iterator;
      while(iter.moveNext()) {
        OrderStruct orderStruct=iter.current;
        orderString += orderStruct.orderFieldName;
        if(orderStruct.orderType==OrderType.DESC) orderString += " DESC";
      }
    }
    return orderString;
  }

  String _generateSet(List<FieldStruct> fieldStructList) {
    List<WhereStruct> list = [];
    WhereStruct ws;
    fieldStructList.forEach((sd) {
      ws = WhereStruct(
          sd.field_table_id, sd.fieldName!, SqlOperator.EQUAL, sd.value);
      list.add(ws);
    });
    return _generateSuffix(list, "SET", ",");
  }

  String _generateWhere(List<WhereStruct> whereStructList) {
    return _generateSuffix(whereStructList, "WHERE", "AND");
  }

  String _generateSuffix(
      List<WhereStruct> list, String beginning, String separator) {
    WhereStruct whereStruct;
    String setClause = "";
    Object value;
    bool hasSet = false;

    Iterator<WhereStruct> iter = list.iterator;
    String op;
    while (iter.moveNext()) {
      bool validClause = true;
      whereStruct = iter.current;
      op = WhereData.getSqlOperatorString(whereStruct.sqlOperator);
      if (whereStruct.value == null) validClause = false;
      if (validClause) {
        if (hasSet) {
          setClause += separator + " ";
        } else {
          hasSet = true;
          setClause += " " + beginning + " ";
        }
        if (whereStruct.fieldName != null) {
          setClause += whereStruct.fieldName;
        }
        setClause += " " + op + " ";
        if (whereStruct.sqlOperator == SqlOperator.IN ||
            whereStruct.sqlOperator == SqlOperator.NOT_IN) {
          value = "(" + whereStruct.value.toString() + ") ";
          setClause += value.toString();
        } else if (whereStruct.value is SqlKeyword) {
          value = (whereStruct.value as SqlKeyword).getKeywordString + " ";
          setClause += value.toString();
        } else if (whereStruct.value is String) {
          value = "'" + encode(whereStruct.value.toString()) + "' ";
          setClause += value.toString();
        } else if (dbType == DBType.Hsql) {
          value = "'" + whereStruct.value.toString() + "' ";
          setClause += value.toString();
        } else {
          value = whereStruct.value.toString() + " ";
          setClause += value.toString();
        }
      }
    }

    return setClause;
  }
}

class SqlKeyword {
  String _keywordString;
  SqlKeyword(this._keywordString);
  String get getKeywordString => _keywordString;
}

String encode(String en) {
  String out;
  out = en.replaceAll("'", "''");
  return out;
}
