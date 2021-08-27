import 'dart:io';
import 'dart:convert';
import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

/**
 * Send the water_line_field entries created by the user to the server.<br/>
 * <p>
 * Sends LIKE/DISLIKE for local User <br/>
 * Sends INCREMENT/DECREMENT for local Read Server<br/>
 * <p>
 * Receives list of processed water_line_field entries and updates the notify_state to CLIENT_SENT<br/>
 *
 */
class RestPostWaterLineFieldsUtils extends AbstractRestUtils {
  late JsonRemoteWaterLineFieldDtoTools jsonTools;
  late WaterLineField waterLineField;

  RestPostWaterLineFieldsUtils(
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
    jsonTools = JsonRemoteWaterLineFieldDtoTools(smdSys);
    waterLineField =
        WaterLineField(localWardenType, remoteWardenType, smdSys, transaction);
    await waterLineField.init();
  }

  Future<List<RemoteDto>> getRemoteFieldDtoListToSend() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    // Get list of entries
    List<WaterLineFieldDto>? waterLineFieldList;
    List<RemoteDto> remoteDtoList = [];
    try {
      waterLineFieldList = await waterLineField.getWaterLineFieldListToSend();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    print("list=$waterLineFieldList");

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

  Future<void> updateOriginalRecordsUsingRemoteFieldDto(
      RemoteDto remoteDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    RemoteWaterLineFieldDto remoteWaterLineFieldDto = remoteDto as RemoteWaterLineFieldDto;
    WaterLineFieldDto waterLineFieldDto =
        remoteWaterLineFieldDto.getWaterLineFieldDto();
    if (waterLineFieldDto.change_type_enum != ChangeType.NOTIFY) {
      waterLineField.setWaterLineFieldDto(waterLineFieldDto);
      try {
        await waterLineField.updateNotifyState(NotifyState.CLIENT_SENT);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
          print("WS $e");
        }
      }
    }
  }

  void updateOriginalRecordsUsingRemoteFieldDtoList(
      List<RemoteDto> remoteDtoList) {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (remoteDtoList != null) {
      Iterator<RemoteDto> iter = remoteDtoList.iterator;
      RemoteDto remoteDto;

      while (iter.moveNext()) {
        remoteDto = iter.current;
        updateOriginalRecordsUsingRemoteFieldDto(remoteDto);
      }
    }
  }

  Future<void> sendRemoteFieldDtoListToServer(List<RemoteDto> remoteDtoList,
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
      if (serverDatabase != null) params["database"] = serverDatabase;
      if (testPassword != null) params["test_pass"] = testPassword;
      int? uid = await userTools.getCurrentUserId(smd, transaction);
      params["user_id"] = uid.toString();

      String jsonResponseString;
      try {
        jsonResponseString = await writeClient.postBaseURI(
            jsonEncode(tablesArray),
            UrlTools.C_WATERLINE_FIELDS_POST_URL,
                signedRequestHelper.sign(params));
      } on TransmitStatusException catch (e) {
        print("WS $e");
        throw TransmitStatusException(e.transmitStatus,
            cause: e.cause, sourceName: "Send Field List");
      }
      print("js=" + jsonResponseString);
      List<RemoteDto> returnedRemoteFieldDtoList =
          jsonTools.processRemoteWaterLineFieldDtoListJson(jsonResponseString);
      updateOriginalRecordsUsingRemoteFieldDtoList(returnedRemoteFieldDtoList);
      print("rl=$returnedRemoteFieldDtoList");
    }
  }
}
