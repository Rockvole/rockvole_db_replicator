import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

/**
 * Send the water_line_field entries created by the user to the server.<br/>
 * <p>
 * Sends LIKE/DISLIKE for local User <br/>
 * Sends INCREMENT/DECREMENT for local Read Server<br/>
 * <p>
 * Receives list of associated table entries
 *
 */
class RestRequestSelectedRowsUtils extends AbstractRestUtils {
  late JsonRemoteWaterLineFieldDtoTools jsonRemoteFieldTools;
  late RestGetLatestRowsUtils latestRowsUtils;

  RestRequestSelectedRowsUtils(WardenType? localWardenType,
      WardenType? remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults)
      : super.sep(
            localWardenType,
            remoteWardenType,
            smd,
            smdSys,
            transaction,
            userTools,
            defaults);

  Future<void> init() async {
    await super.init();

    jsonRemoteFieldTools =
        JsonRemoteWaterLineFieldDtoTools(smdSys);
    latestRowsUtils = RestGetLatestRowsUtils(
        localWardenType, remoteWardenType, smd, smdSys, transaction, userTools, defaults);
    await latestRowsUtils.init();
  }

  Future<List<RemoteDto>> getRemoteFieldDtoListToSend(
      WaterLineField waterLineField) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    // Get list of entries
    List<WaterLineFieldDto>? waterLineFieldList;
    try {
      waterLineFieldList =
          await waterLineField.getOutOfDateNotificationsListToSend();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    print("list=$waterLineFieldList");
    List<RemoteDto> remoteDtoList = [];
    if (waterLineFieldList != null) {
      Iterator<WaterLineFieldDto> iter = waterLineFieldList.iterator;
      WaterLineFieldDto waterLineFieldDto;

      while (iter.moveNext()) {
        waterLineFieldDto = iter.current;
        remoteDtoList.add(RemoteWaterLineFieldDto(waterLineFieldDto, smd));
      }
    }
    return remoteDtoList;
  }

  Future<void> requestUpdatedRowsFromServer(
      List<RemoteDto> remoteDtoList, int version,
      {String? serverDatabase, String? testPassword}) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    // Convert RemoteDto list into Json
    Map<String, String> params = Map();
    Map<String, dynamic> tableData;
    Iterator<RemoteDto> iter = remoteDtoList.iterator;
    RemoteDto remoteDto;
    RemoteWaterLineFieldDto remoteWaterLineFieldDto;

    while (iter.moveNext()) {
      List<Map<String, dynamic>> tablesArray = [];
      remoteDto = iter.current;
      remoteWaterLineFieldDto = remoteDto as RemoteWaterLineFieldDto;

      tableData = JsonRemoteDtoConversion.getJsonFromWaterLineFieldDto(
          remoteWaterLineFieldDto, remoteDto.waterLineDto!);
      tablesArray.add(tableData);

      // Now send one record at a time
      UserStoreDto? userStoreDto = await userTools.getCurrentUserStoreDto(smd, transaction);
      UserDto? userDto = await userTools.getCurrentUserDto(smd, transaction);
      signedRequestHelper = SignedRequestHelper2(
          userStoreDto!.email!,
          userDto!.pass_key!);
      params["ts"] = TimeUtils.getNowCustomTs().toString();
      params["version"] = version.toString();

      if (serverDatabase != null) params["database"] = serverDatabase;
      if (testPassword != null) params["test_pass"] = testPassword;
      int? uid = await userTools.getCurrentUserId(smd, transaction);
      params["user_id"] = uid.toString();
      String jsonResponseString;
      try {
        jsonResponseString = await readClient.postBaseURI(
            jsonEncode(tablesArray),
            UrlTools.C_SELECTED_ROWS_POST_URL,
                signedRequestHelper.sign(params));
      } on TransmitStatusException catch (e) {
        print("WS $e");
        rethrow;
      }
      print("server response string=" + jsonResponseString);
      List<RemoteDto> returnedRemoteFieldDtoList =
          JsonRemoteDtoTools.getRemoteDtoListFromJsonString(
              jsonResponseString, smdSys, defaults);

      print("parsed server list=$returnedRemoteFieldDtoList");
      await latestRowsUtils.storeRemoteDtoList(returnedRemoteFieldDtoList);
    }
  }
}
