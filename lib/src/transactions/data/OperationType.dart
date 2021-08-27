

enum OperationType { INSERT, UPDATE, DELETE, SNAPSHOT }

class OperationTypeAccess {
  static OperationType? getOperationType(int? operationValue) {
    switch (operationValue) {
      case 1:
        return OperationType.INSERT;
      case 2:
        return OperationType.UPDATE;
      case 3:
        return OperationType.DELETE;
      case 5:
        return OperationType.SNAPSHOT;
    }
    return null;
  }

  static int? getOperationValue(OperationType? operationType) {
    switch (operationType) {
      case OperationType.INSERT:
        return 1;
      case OperationType.UPDATE:
        return 2;
      case OperationType.DELETE:
        return 3;
      case OperationType.SNAPSHOT:
        return 5;
    }
    return null;
  }

}