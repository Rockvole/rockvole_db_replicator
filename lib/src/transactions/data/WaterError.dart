enum WaterError {
  NONE,
  FAILED_UPDATE,
  ID_NOT_FOUND,
  ENTRY_NOT_FOUND,
  ID_NOT_SET,
  JOIN_FAILURE,
  OPERATION_NOT_SUPPORTED,
  INVALID_TABLE,
  TABLE_NOT_FOUND,
  PARTITION_NOT_FOUND,
  UPDATE_NO_ENTRY,
  CRC_NOT_MATCH,
  INVALID_ENTRY,
  DUPLICATE_ENTRY,
  DUPLICATE_APPROVAL
}

class WaterErrorAccess {
  static List<int> getWaterErrorList(Set<WaterError> waterErrorSet) {
    List<int> list = [];
    waterErrorSet.forEach((es) {
      list.add(getWaterErrorValue(es)!);
    });
    return list;
  }

  static Set<WaterError> getAllOfWaterErrorSet() {
    return {
      WaterError.NONE,
      WaterError.FAILED_UPDATE,
      WaterError.ID_NOT_FOUND,
      WaterError.ENTRY_NOT_FOUND,
      WaterError.ID_NOT_SET,
      WaterError.JOIN_FAILURE,
      WaterError.OPERATION_NOT_SUPPORTED,
      WaterError.INVALID_TABLE,
      WaterError.TABLE_NOT_FOUND,
      WaterError.PARTITION_NOT_FOUND,
      WaterError.UPDATE_NO_ENTRY,
      WaterError.CRC_NOT_MATCH,
      WaterError.INVALID_ENTRY,
      WaterError.DUPLICATE_ENTRY,
      WaterError.DUPLICATE_APPROVAL
    };
  }

  static int? getWaterErrorValue(WaterError? waterError) {
    if (waterError == null) return null;
    switch (waterError) {
      case WaterError.NONE:
        return 0;
      case WaterError.FAILED_UPDATE:
        return 1;
      case WaterError.ID_NOT_FOUND:
        return 2;
      case WaterError.ENTRY_NOT_FOUND:
        return 3;
      case WaterError.ID_NOT_SET:
        return 4;
      case WaterError.JOIN_FAILURE:
        return 5;
      case WaterError.OPERATION_NOT_SUPPORTED:
        return 10;
      case WaterError.INVALID_TABLE:
        return 11;
      case WaterError.TABLE_NOT_FOUND:
        return 12;
      case WaterError.PARTITION_NOT_FOUND:
        return 13;
      case WaterError.UPDATE_NO_ENTRY:
        return 14;
      case WaterError.CRC_NOT_MATCH:
        return 16;
      case WaterError.INVALID_ENTRY:
        return 17;
      case WaterError.DUPLICATE_ENTRY:
        return 18;
      case WaterError.DUPLICATE_APPROVAL:
        return 19;
    }
    throw ArgumentError("Invalid WaterError $waterError");
  }

  static WaterError? getWaterError(int? errorValue,
      {bool returnNullIfNotFound = false}) {
    switch (errorValue) {
      case 0:
        return WaterError.NONE;
      case 1:
        return WaterError.FAILED_UPDATE;
      case 2:
        return WaterError.ID_NOT_FOUND;
      case 3:
        return WaterError.ENTRY_NOT_FOUND;
      case 4:
        return WaterError.ID_NOT_SET;
      case 5:
        return WaterError.JOIN_FAILURE;
      case 10:
        return WaterError.OPERATION_NOT_SUPPORTED;
      case 11:
        return WaterError.INVALID_TABLE;
      case 12:
        return WaterError.TABLE_NOT_FOUND;
      case 13:
        return WaterError.PARTITION_NOT_FOUND;
      case 14:
        return WaterError.UPDATE_NO_ENTRY;
      case 16:
        return WaterError.CRC_NOT_MATCH;
      case 17:
        return WaterError.INVALID_ENTRY;
      case 18:
        return WaterError.DUPLICATE_ENTRY;
      case 19:
        return WaterError.DUPLICATE_APPROVAL;
    }
    if (returnNullIfNotFound) return null;
    throw ArgumentError("Invalid WaterError value $errorValue");
  }
}
