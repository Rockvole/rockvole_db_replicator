
enum WaterState {
  SERVER_PENDING, // Server = Newly added to change table
  SERVER_APPROVED, // Change has been Approved
  SERVER_REJECTED, // Change has been Rejected
  SERVER_PLACEHOLDER, // Temporary Placeholder for entry

  CLIENT_STORED, // Phone = Change has been stored in correct table
  CLIENT_SENT, // Phone = Change has been sent to Server
  CLIENT_APPROVED, // Phone = Change has been approved
  CLIENT_REJECTED, // Phone = Change has been rejected
  CLIENT_SNAPSHOT // Phone = Point to a snapshot in the table
}

class WaterStateAccess {

  static List<int> getWaterStateList(List<WaterState> waterStateList) {
    List<int> list = [];
    waterStateList.forEach((st) {
      list.add(getWaterStateValue(st)!);
    });
    return list;
  }

  static int? getWaterStateValue(WaterState? waterState) {
    if(waterState==null) return null;
    switch (waterState) {
      case WaterState.SERVER_PENDING:
        return 0;
      case WaterState.SERVER_APPROVED:
        return 1;
      case WaterState.SERVER_REJECTED:
        return 2;
      case WaterState.SERVER_PLACEHOLDER:
        return 3;
      case WaterState.CLIENT_STORED:
        return 10;
      case WaterState.CLIENT_SENT:
        return 11;
      case WaterState.CLIENT_APPROVED:
        return 12;
      case WaterState.CLIENT_REJECTED:
        return 13;
      case WaterState.CLIENT_SNAPSHOT:
        return 18;
    }
    throw ArgumentError("Invalid WaterState $waterState");
  }

  static WaterState? getWaterState(int stateValue, {bool returnNullIfNotFound=false}) {
    switch(stateValue) {
      case 0: return WaterState.SERVER_PENDING;
      case 1: return WaterState.SERVER_APPROVED;
      case 2: return WaterState.SERVER_REJECTED;
      case 3: return WaterState.SERVER_PLACEHOLDER;
      case 10: return WaterState.CLIENT_STORED;
      case 11: return WaterState.CLIENT_SENT;
      case 12: return WaterState.CLIENT_APPROVED;
      case 13: return WaterState.CLIENT_REJECTED;
      case 18: return WaterState.CLIENT_SNAPSHOT;
    }
    if(returnNullIfNotFound) return null;
    throw ArgumentError("Invalid WaterState value $stateValue");
  }

  static WaterState getWaterStateFromString(String waterStateString) {
    switch(waterStateString) {
      case 'SERVER_PENDING': return WaterState.SERVER_PENDING;
      case 'SERVER_APPROVED': return WaterState.SERVER_APPROVED;
      case 'SERVER_REJECTED': return WaterState.SERVER_REJECTED;
      case 'SERVER_PLACEHOLDER': return WaterState.SERVER_PLACEHOLDER;
      case 'CLIENT_STORED': return WaterState.CLIENT_STORED;
      case 'CLIENT_SENT': return WaterState.CLIENT_SENT;
      case 'CLIENT_APPROVED': return WaterState.CLIENT_APPROVED;
      case 'CLIENT_REJECTED': return WaterState.CLIENT_REJECTED;
      case 'CLIENT_SNAPSHOT': return WaterState.CLIENT_SNAPSHOT;
      default:
        throw ArgumentError("Invalid WaterState String '$waterStateString'");
    }
  }
}