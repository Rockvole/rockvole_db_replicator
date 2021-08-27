import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class ConfigurationUtils {
  //static final String C_TEST_WEB = "192.168.1.110"; // david-mint
  static final String C_TEST_WEB = "192.168.1.160"; // david-dell
  static final int C_TEST_SUBSET = 99;

  bool initialized = false;
  late ConfigurationDao configurationDao;
  WardenType wardenType;
  SchemaMetaData smd;
  DbTransaction transaction;
  ConfigurationNameDefaults defaults;

  ConfigurationUtils(
      this.wardenType, this.smd, this.transaction, this.defaults) {
    configurationDao = ConfigurationDao(smd, transaction, defaults);
  }

  Future<bool> init({int? table_id, bool initTable = true}) async {
    initialized = true;
    return await configurationDao.init(initTable: initTable);
  }

  Future<void> storeConfigurationString(ConfigurationNameEnum configurationName,
      String newConfigString) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    String? configString;
    try {
      configString = await configurationDao.getString(0, wardenType, configurationName);
      await configurationDao.setString(C_TEST_SUBSET, wardenType,
          configurationName, configString!, defaults);
      await configurationDao.setString(
          0, wardenType, configurationName, newConfigString, defaults);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
    }
  }

  Future<void> fetchConfigurationString(
      ConfigurationNameEnum configurationName) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    String? configString;
    try {
      configString =
          await configurationDao.getString(C_TEST_SUBSET, wardenType, configurationName);
      await configurationDao.setString(
          0, wardenType, configurationName, configString!, defaults);
      await configurationDao.deleteConfigurationByUnique(
          C_TEST_SUBSET, wardenType, configurationName, 0);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) print("$e");
    }
  }
}
