import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class UrlTools {
  static const String C_HTTP = "http";
  static const String C_SERVER_ADDRESS = "localhost";
  static const String C_ANDROID_ADDRESS = "10.0.2.2";
  static const int C_SERVER_PORT = 9090;
  static const String C_REST_BASE_URL = "/rockvole_db/rest/";

  static const String C_AUTHENTICATE_URL = "authenticate/get";
  static const String C_LATEST_ROWS_URL = "latest_rows/get";
  static const String C_LATEST_FIELDS_URL = "latest_fields/get";
  static const String C_NEW_ROW_POST_URL = "new_row/post";
  static const String C_SELECTED_ROWS_POST_URL = "selected_rows/post";
  static const String C_WATERLINE_FIELDS_POST_URL = "water_line_fields/post";

  UserTools userTools;
  SchemaMetaData smd;
  DbTransaction transaction;

  UrlTools(this.userTools, this.smd, this.transaction);

  Future<SimpleEntry> getServerUrl(WardenType warden) async {
    if (warden == WardenType.USER || warden == WardenType.ADMIN)
      throw ArgumentError("Invalid WArdenType $warden");
    SimpleEntry simpleEntry = SimpleEntry(C_SERVER_PORT, C_SERVER_ADDRESS);
    ConfigurationNameEnum configEnum = ConfigurationNameEnum.READ_SERVER_URL;
    if (warden == WardenType.WRITE_SERVER)
      configEnum = ConfigurationNameEnum.WRITE_SERVER_URL;
    try {
      simpleEntry = (await userTools.getConfigurationEntry(
          smd, transaction, configEnum))!;
    } on Exception {}
    return simpleEntry;
  }

  //Future<String> getWebsiteUrl() async {
  //  return "https://" + await getWebUrl().toString();
  //}
}
