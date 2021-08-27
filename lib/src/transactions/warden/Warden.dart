enum WardenType { WRITE_SERVER, READ_SERVER, ADMIN, USER, NULL }

class Warden {
  static int? getWardenValue(WardenType? wardenType) {
    switch (wardenType) {
      case WardenType.WRITE_SERVER:
        return 1;
      case WardenType.READ_SERVER:
        return 3;
      case WardenType.ADMIN:
        return 5;
      case WardenType.USER:
        return 7;
    }
    return null;
  }

  static WardenType getWardenType(int wardenValue) {
    switch (wardenValue) {
      case 1:
        return WardenType.WRITE_SERVER;
      case 3:
        return WardenType.READ_SERVER;
      case 5:
        return WardenType.ADMIN;
      case 7:
        return WardenType.USER;
    }
    throw ArgumentError("Invalid WardenType $wardenValue");
  }

  static bool isServer(WardenType? wardenType) {
    return (wardenType == WardenType.WRITE_SERVER ||
        wardenType == WardenType.READ_SERVER);
  }

  static bool isClient(WardenType? wardenType) {
    return (wardenType == WardenType.USER || wardenType == WardenType.ADMIN);
  }

  static String getSimpleWardenString(WardenType? wardenType) {
    switch (wardenType) {
      case WardenType.WRITE_SERVER:
        return "WRITE";
      case WardenType.READ_SERVER:
        return "READ";
      case WardenType.ADMIN:
        return "ADMIN";
      case WardenType.USER:
        return "USER";
    }
    return "NULL";
  }

  static String getWardenName(WardenType? wardenType, {bool toUpper=false}) {
    String wardenString;
    switch (wardenType) {
      case WardenType.WRITE_SERVER:
        wardenString = "write";
        break;
      case WardenType.READ_SERVER:
        wardenString = "read";
        break;
      case WardenType.ADMIN:
        wardenString = "admin";
        break;
      case WardenType.USER:
        wardenString = "user";
        break;
      default:
        throw ArgumentError("Invalid WardenType $wardenType");
    }
    if (toUpper) return wardenString.toUpperCase();
    return wardenString;
  }
}
