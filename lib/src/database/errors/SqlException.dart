enum SqlExceptionEnum {
  DUPLICATE_ENTRY, ENTRY_NOT_FOUND, FAILED_SELECT, FAILED_UPDATE, INVALID_ENTRY,
  JOIN_FAILURE, PARTITION_NOT_FOUND, SOCKET_CLOSED, SQL_SYNTAX_ERROR, TABLE_ALREADY_EXISTS,
  TABLE_NOT_FOUND, UNKNOWN
}

enum FailedUpdateReason {
  FAILED_UPDATE, NO_TABLE_FOUND, DUPLICATE_ENTRY
}

class SqlException implements Exception {
  String? cause;
  String? sql;
  String? json;
  late SqlExceptionEnum sqlExceptionEnum;
  FailedUpdateReason? failedUpdateReason;
  SqlException(this.sqlExceptionEnum, {this.cause, this.sql, this.json}) {
    if(cause==null) cause=SqlExceptionTools.getMessage(sqlExceptionEnum);
  }
  SqlException.renew(SqlException sqlException, {this.cause}) {
    if(cause==null) cause=sqlException.cause;
    sql=sqlException.sql;
    json=sqlException.json;
    sqlExceptionEnum=sqlException.sqlExceptionEnum;
  }

  @override
  String toString() {
    String SEP="\n";
    StringBuffer sb=StringBuffer();
    sb.write("----------------------------------- $sqlExceptionEnum"+SEP);
    sb.write("cause: $cause"+SEP);
    sb.write("sql: $sql"+SEP);
    sb.write("json: $json"+SEP);
    return sb.toString();
  }
}

class SqlExceptionTools {

  static String getMessage(SqlExceptionEnum sqlExceptionEnum) {
    switch(sqlExceptionEnum) {
      case SqlExceptionEnum.DUPLICATE_ENTRY:
        return "Duplicate Entry Error";
      case SqlExceptionEnum.ENTRY_NOT_FOUND:
        return "Entry not found";
      case SqlExceptionEnum.FAILED_SELECT:
        return "Failed Select";
      case SqlExceptionEnum.FAILED_UPDATE:
        return "Failed Update";
      case SqlExceptionEnum.INVALID_ENTRY:
        return "Invalid Entry";
      case SqlExceptionEnum.JOIN_FAILURE:
        return "Join Failure";
      case SqlExceptionEnum.PARTITION_NOT_FOUND:
        return "Partition not found";
      case SqlExceptionEnum.SOCKET_CLOSED:
        return "Socket Closed";
      case SqlExceptionEnum.SQL_SYNTAX_ERROR:
        return "Sql Syntax Error";
      case SqlExceptionEnum.TABLE_ALREADY_EXISTS:
        return "Table already exists";
      case SqlExceptionEnum.TABLE_NOT_FOUND:
        return "Table not found";
      case SqlExceptionEnum.UNKNOWN:
        return "Unknown Sql Error";
    }
    throw ArgumentError("Unknown SqlException $sqlExceptionEnum");
  }
}