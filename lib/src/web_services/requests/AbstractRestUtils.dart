import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

abstract class AbstractRestUtils {
  bool initialized = false;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  late DbTransaction transaction;
  late Client readClient;
  late Client writeClient;
  late UserTools userTools;
  late UrlTools urlTools;
  late WaterLineDao waterLineDao;
  late WaterLine waterLine;
  late SignedRequestHelper2 signedRequestHelper;
  int? userRowsLimit;
  late ConfigurationNameDefaults defaults;

  AbstractRestUtils();
  AbstractRestUtils.sep(this.localWardenType, this.remoteWardenType, this.smd,
      this.smdSys, this.transaction, this.userTools, this.defaults);
  void sep(
      WardenType localWardenType,
      WardenType remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults) {
    this.localWardenType = localWardenType;
    this.remoteWardenType = remoteWardenType;
    this.smd = smd;
    this.smdSys = smdSys;
    this.transaction = transaction;
    this.userTools = userTools;
    this.defaults = defaults;
  }

  Future<void> init() async {
    initialized = true;
    this.urlTools = UrlTools(userTools, smd, transaction);
    waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    waterLine = WaterLine(waterLineDao, smd, transaction);

    UserDto? currentUserDto;
    try {
      currentUserDto = await userTools.getCurrentUserDto(smd, transaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
    }
    SimpleEntry writeServerUrl = await urlTools.getServerUrl(WardenType.WRITE_SERVER);
    SimpleEntry readServerUrl;
    if (currentUserDto == null ||
        currentUserDto.warden ==
            WardenType.USER) // Only users use a different server
      readServerUrl = await urlTools.getServerUrl(WardenType.READ_SERVER);
    else
      readServerUrl = writeServerUrl;
    userRowsLimit = await userTools.getConfigurationInteger(
        smd, transaction, ConfigurationNameEnum.ROWS_LIMIT);

    writeClient = Client(writeServerUrl.stringValue, writeServerUrl.intValue,
        UrlTools.C_REST_BASE_URL);
    readClient = Client(readServerUrl.stringValue, readServerUrl.intValue,
        UrlTools.C_REST_BASE_URL);
  }
}
