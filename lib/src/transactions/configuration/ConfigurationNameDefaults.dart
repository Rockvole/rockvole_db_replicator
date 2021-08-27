import 'package:rockvole_db/rockvole_web_services.dart';

enum ConfigurationNameEnum {
  // MUST be above 0
  // User id of current user
  USER_ID,
// Number of records user will request from server
  ROWS_LIMIT,
// URL to reach the write server
  WRITE_SERVER_URL,
// LIST URLs to reach the read servers
  READ_SERVER_URL,
// How much the time on the phone differs from the server
  SERVER_TIME_OFFSET,
// Synchronize using wi-fi only
  SYNC_WIFI_ONLY,
// Next time alarm manager will check server for row data
  ROWS_NEXT_SYNC_CHANGES_TS,
// How many minutes between checking the server for row data
  ROWS_SYNC_INTERVAL_MINS,
// LIST Number of minutes to wait between requesting row data
  ROWS_SYNC_INTERVAL,
// Next time alarm manager will check server for field data
  FIELDS_NEXT_SYNC_CHANGES_TS,
// How many minutes between checking the server for field data
  FIELDS_SYNC_INTERVAL_MINS,
// Number of minutes to wait before sending the user entered data
  SEND_CHANGES_DELAY_MINS,
// LIST
  SEND_CHANGES_DELAY,
// User options for whether to confirm send
  SEND_CHANGES_DELAY_OPTS,
// User should see only ingredients from their home country
  HOME_COUNTRY_ONLY,
// Whether reports should use all Aversions or custom
  REPORTS_MY_AVERSIONS,
// Database version
  DATABASE_VERSION,
// WebUrl
  WEB_URL
}

class ConfigurationNameStruct {
  int id;
  ConfigurationNameEnum configurationNameEnum;
  String name;
  SimpleEntry defaultValues;
  ConfigurationNameStruct(
      this.id, this.configurationNameEnum, this.name, this.defaultValues);

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("id=$id||");
    sb.write("configurationNameEnum=$configurationNameEnum||");
    sb.write("name=$name||");
    sb.write("defaultValues=$defaultValues");
    return sb.toString();
  }
}

class ConfigurationNameDefaults {
  late Map<ConfigurationNameEnum, ConfigurationNameStruct> _configurationNameMap;
  ConfigurationNameDefaults() {
    _configurationNameMap = Map();
    // Set defaults
    _configurationNameMap[ConfigurationNameEnum.USER_ID] =
        ConfigurationNameStruct(
            1, ConfigurationNameEnum.USER_ID, "USER-ID", SimpleEntry(1, null));
    _configurationNameMap[ConfigurationNameEnum.ROWS_LIMIT] =
        ConfigurationNameStruct(2, ConfigurationNameEnum.ROWS_LIMIT,
            "ROWS-LIMIT", SimpleEntry(100, null));
    _configurationNameMap[ConfigurationNameEnum.WRITE_SERVER_URL] =
        ConfigurationNameStruct(
            4,
            ConfigurationNameEnum.WRITE_SERVER_URL,
            "WRITE-SERVER-URL",
            SimpleEntry(
                UrlTools.C_SERVER_PORT,
                UrlTools.C_SERVER_ADDRESS));
    _configurationNameMap[ConfigurationNameEnum.READ_SERVER_URL] =
        ConfigurationNameStruct(
            5,
            ConfigurationNameEnum.READ_SERVER_URL,
            "READ-SERVER-URL",
            SimpleEntry(
                UrlTools.C_SERVER_PORT,
                UrlTools.C_SERVER_ADDRESS));
    _configurationNameMap[ConfigurationNameEnum.SERVER_TIME_OFFSET] =
        ConfigurationNameStruct(6, ConfigurationNameEnum.SERVER_TIME_OFFSET,
            "SERVER-TIME-OFFSET", SimpleEntry(0, null));
    _configurationNameMap[ConfigurationNameEnum.SYNC_WIFI_ONLY] =
        ConfigurationNameStruct(7, ConfigurationNameEnum.SYNC_WIFI_ONLY,
            "SYNC-WIFI-ONLY", SimpleEntry(1, null));
    _configurationNameMap[ConfigurationNameEnum.ROWS_NEXT_SYNC_CHANGES_TS] =
        ConfigurationNameStruct(
            8,
            ConfigurationNameEnum.ROWS_NEXT_SYNC_CHANGES_TS,
            "ROWS-NEXT-SYNC-CHANGES-TS",
            SimpleEntry(null, null));
    _configurationNameMap[ConfigurationNameEnum.ROWS_SYNC_INTERVAL_MINS] =
        ConfigurationNameStruct(
            9,
            ConfigurationNameEnum.ROWS_SYNC_INTERVAL_MINS,
            "ROWS-SYNC-INTERVAL-MINS",
            SimpleEntry(1440, null));
    _configurationNameMap[ConfigurationNameEnum.ROWS_SYNC_INTERVAL] =
        ConfigurationNameStruct(10, ConfigurationNameEnum.ROWS_SYNC_INTERVAL,
            "ROWS-SYNC-INTERVAL", SimpleEntry(0, "Manual"));
    _configurationNameMap[ConfigurationNameEnum.FIELDS_NEXT_SYNC_CHANGES_TS] =
        ConfigurationNameStruct(
            11,
            ConfigurationNameEnum.FIELDS_NEXT_SYNC_CHANGES_TS,
            "FIELDS-NEXT-SYNC-CHANGES-TS",
            SimpleEntry(null, null));
    _configurationNameMap[ConfigurationNameEnum.FIELDS_SYNC_INTERVAL_MINS] =
        ConfigurationNameStruct(
            12,
            ConfigurationNameEnum.FIELDS_SYNC_INTERVAL_MINS,
            "FIELDS-SYNC-INTERVAL-MINS",
            SimpleEntry(6, null));
    _configurationNameMap[ConfigurationNameEnum.SEND_CHANGES_DELAY_MINS] =
        ConfigurationNameStruct(
            13,
            ConfigurationNameEnum.SEND_CHANGES_DELAY_MINS,
            "SEND-CHANGES-DELAY-MINS",
            SimpleEntry(120, null));
    _configurationNameMap[ConfigurationNameEnum.SEND_CHANGES_DELAY] =
        ConfigurationNameStruct(14, ConfigurationNameEnum.SEND_CHANGES_DELAY,
            "SEND-CHANGES-DELAY", SimpleEntry(120, "2 Hours"));
    _configurationNameMap[ConfigurationNameEnum.SEND_CHANGES_DELAY_OPTS] =
        ConfigurationNameStruct(
            15,
            ConfigurationNameEnum.SEND_CHANGES_DELAY_OPTS,
            "SEND-CHANGES-DELAY-OPTS",
            SimpleEntry(0, null));
    _configurationNameMap[ConfigurationNameEnum.HOME_COUNTRY_ONLY] =
        ConfigurationNameStruct(16, ConfigurationNameEnum.HOME_COUNTRY_ONLY,
            "HOME-COUNTRY-ONLY", SimpleEntry(0, null));
    _configurationNameMap[ConfigurationNameEnum.REPORTS_MY_AVERSIONS] =
        ConfigurationNameStruct(17, ConfigurationNameEnum.REPORTS_MY_AVERSIONS,
            "REPORTS-MY-AVERSIONS", SimpleEntry(0, null));
    _configurationNameMap[ConfigurationNameEnum.DATABASE_VERSION] =
        ConfigurationNameStruct(18, ConfigurationNameEnum.DATABASE_VERSION,
            "DATABASE-VERSION", SimpleEntry(1, null));
    _configurationNameMap[ConfigurationNameEnum.WEB_URL] =
        ConfigurationNameStruct(19, ConfigurationNameEnum.WEB_URL, "WEB-URL",
            SimpleEntry(null, UrlTools.C_SERVER_ADDRESS));
  }

  ConfigurationNameStruct getConfigurationNameStruct(
          ConfigurationNameEnum configurationNameEnum) =>
      _configurationNameMap[configurationNameEnum]!;

  ConfigurationNameStruct? getConfigurationNameStructFromName(
      String configurationName) {
    ConfigurationNameStruct? configurationNameStruct = null;
    _configurationNameMap.values.forEach((ConfigurationNameStruct struct) {
      if (struct.name == configurationName) configurationNameStruct = struct;
    });
    if (configurationNameStruct == null)
      throw RangeError("Configuration Name not found");
    return configurationNameStruct;
  }

  ConfigurationNameStruct? getConfigurationNameStructFromId(int id) {
    ConfigurationNameStruct? configurationNameStruct = null;
    _configurationNameMap.values.forEach((ConfigurationNameStruct struct) {
      if (struct.id == id) configurationNameStruct = struct;
    });
    return configurationNameStruct;
  }

  Map<ConfigurationNameEnum, ConfigurationNameStruct>
      getConfigurationNameMap() {
    return _configurationNameMap;
  }

  @override
  String toString() {
    return _configurationNameMap.toString();
  }
}
