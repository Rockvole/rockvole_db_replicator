import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class RestGetLatestRowsUtils extends AbstractRestUtils {
  late AbstractWarden _abstractWarden;
  late ClientWarden clientWarden;
  Set<int> tableTypeSet = Set();

  RestGetLatestRowsUtils(
      WardenType? localWardenType,
      WardenType? remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults)
      : super.sep(localWardenType, remoteWardenType, smd, smdSys, transaction,
            userTools, defaults);

  Future<void> init() async {
    await super.init();

    if (localWardenType == WardenType.USER &&
        remoteWardenType != WardenType.READ_SERVER)
      throw ArgumentError(
          "Local WardenType USER can only receive from WardenType READ_SERVER");
    if (localWardenType == WardenType.ADMIN &&
        remoteWardenType != WardenType.WRITE_SERVER)
      throw ArgumentError(
          "Local WardenType ADMIN can only receive from WardenType WRITE_SERVER");

    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    clientWarden = ClientWarden(localWardenType!, waterLineDao);
    clearTablesReceived();
    _abstractWarden =
        WardenFactory.getAbstractWarden(localWardenType!, remoteWardenType!);
  }

  Future<List<RemoteDto>> requestRemoteDtoListFromServer(
      {int? waterLineTs,
      String? serverDatabase,
      String? testPassword,
      bool compact = true,
      int? limit}) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    String jsonResponseString;
    UserStoreDto? userStoreDto =
        await userTools.getCurrentUserStoreDto(smd, transaction);
    String? email = userStoreDto!.email;
    UserDto? userDto = await userTools.getCurrentUserDto(smd, transaction);
    String? passKey = userDto!.pass_key;
    signedRequestHelper = SignedRequestHelper2(email!, passKey!);
    Map<String, String> params = Map();
    params["ts"] = TimeUtils.getNowCustomTs().toString();
    params["limit"] =
        limit != null ? limit.toString() : userRowsLimit.toString();

    if (testPassword != null) {
      params["test_pass"] = testPassword;
      if (serverDatabase != null) params["database"] = serverDatabase;
      if (waterLineTs != null) params["water_line"] = waterLineTs.toString();
    }
    if (waterLineTs == null) {
      int wts = await clientWarden.getLatestTs();
      params["water_line"] = wts.toString();
    }
    int? uid = await userTools.getCurrentUserId(smd, transaction);
    params["user_id"] = uid.toString();
    try {
      jsonResponseString = await readClient.getBaseURI(
          UrlTools.C_LATEST_ROWS_URL, signedRequestHelper.sign(params));
    } on TransmitStatusException catch (e) {
      print("WS $e");
      throw TransmitStatusException(e.transmitStatus, cause: e.cause);
    }
    print("url=" + readClient.getURLString());
    print("returned json=" + jsonResponseString);

    List<RemoteDto> list;
    list = JsonRemoteDtoTools.getRemoteDtoListFromJsonString(
        jsonResponseString, smdSys, defaults,
        compact: compact);
    return list;
  }

  Future<RemoteStatusDto> storeRemoteDtoList(
      List<RemoteDto> remoteDtoList) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    RemoteStatusDto remoteStatusDto =
        RemoteStatusDto.sep(smdSys, status: RemoteStatus.PROCESSED_OK);
    TransactionsFactory transactionsFactory = TransactionsFactory(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    late int tableType;
    late RemoteDto remoteDto;
    AbstractTableTransactions tableTransactions;

    for (int f = 0; f < remoteDtoList.length; f++) {
      remoteDto = remoteDtoList[f];
      tableType = remoteDto.waterLineDto!.water_table_id;
      if (tableType == RemoteStatusDto.C_TABLE_ID) {
        break;
      }
      tableTypeSet.add(tableType);
      try {
        int? cuid = await userTools.getCurrentUserId(smd, transaction);
        if (cuid == remoteDto.trDto.user_id) {
          // Remove the original user entry added by this user
          tableTransactions = TableTransactions.sep(remoteDto.trDto);
          await tableTransactions.init(
              localWardenType, remoteWardenType, smd, smdSys, transaction);

          await tableTransactions.getTrDtoByUserTs(remoteDto.trDto.user_ts!);
          await tableTransactions.delete(remoteDto.trDto);
          await tableTransactions.deleteTrRowByTs(tableTransactions.getTs()!);
          WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
          await waterLineDao.init();
          await waterLineDao.deleteWaterLineByTs(tableTransactions.getTs()!);
        }
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
          print("WS $e");
        } else if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("WS $e");
        }
      }
      try {
        tableTransactions =
            await transactionsFactory.getTransactionsFromRemoteDto(remoteDto);
        await _abstractWarden.init(smd, smdSys, transaction);
        _abstractWarden.initialize(tableTransactions,
            passedWaterState: remoteDto.waterLineDto!.water_state);
        await _abstractWarden.write();
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) {
          print("WS $e");
        }
      }
    } // for remoteDtoList
    await clientWarden.cleanWaterLine();

    if (tableType == RemoteStatusDto.C_TABLE_ID) {
      remoteStatusDto = remoteDto as RemoteStatusDto;
    }
    return remoteStatusDto;
  }

  void clearTablesReceived() {
    tableTypeSet = Set();
  }

  Set<int> getTablesReceived() {
    return tableTypeSet;
  }

  bool wasTableReceived(int tableType) {
    return tableTypeSet.contains(tableType);
  }
}
