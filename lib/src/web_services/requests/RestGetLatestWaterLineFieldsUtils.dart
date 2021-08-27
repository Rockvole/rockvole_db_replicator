import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

/**
 * Get the Latest Fields using ChangeSuperType
 * <p>
 * ChangeSuperType can be :<br/>
 * VOTING (For LIKE/DISLIKE)<br/>
 * NUMERALS (For INCREMENT/DECREMENT)<br/>
 * CHANGES (For NOTIFY)
 * <p>
 * Response is the water_line_field entries<br/>
 * This is used to update the corresponding table values
 *
 */
class RestGetLatestWaterLineFieldsUtils extends AbstractRestUtils {
  late WaterLineField waterLineField;
  late JsonRemoteWaterLineFieldDtoTools jsonTools;
  late AbstractRemoteFieldWarden abstractRemoteFieldWarden;

  RestGetLatestWaterLineFieldsUtils(
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
    abstractRemoteFieldWarden = AbstractRemoteFieldWarden(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
  }

  Future<List<RemoteDto>> requestUpdatedWaterLineFieldsFromServer(
      ChangeSuperType changeSuperType,
      {int? remoteTs,
      String? serverDatabase,
      String? testPassword}) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (changeSuperType == null)
      throw NullPointerException("ChangeSuperType must not be null");
    String jsonResponseString;
    UserStoreDto? userStoreDto = await userTools.getCurrentUserStoreDto(smd, transaction);
    UserDto? userDto = await userTools.getCurrentUserDto(smd, transaction);
    signedRequestHelper = SignedRequestHelper2(
        userStoreDto!.email!,
        userDto!.pass_key!);
    Map<String, String> params = Map();
    params["ts"] = TimeUtils.getNowCustomTs().toString();
    params["limit"] = userRowsLimit.toString();

    if (testPassword != null) {
      params["test_pass"] = testPassword;
      if (serverDatabase != null) params["database"] = serverDatabase;
      if (remoteTs != null) params["remote_ts"] = remoteTs.toString();
    }
    if (remoteTs == null)
      params["remote_ts"] =
          (await waterLineField.getMaxTs(changeSuperType)).toString();
    params["change_super_type"] =
        WaterLineField.getChangeSuperTypeValue(changeSuperType).toString();
    params["user_id"] =
        (await userTools.getCurrentUserId(smd, transaction)).toString();
    try {
      jsonResponseString = await readClient
          .getBaseURI(UrlTools.C_LATEST_FIELDS_URL, signedRequestHelper.sign(params));
    } on TransmitStatusException catch (e) {
      print("WS $e");
      throw TransmitStatusException(e.transmitStatus,
          cause: e.cause, sourceName: "Request Fields");
    }
    print("url=" + readClient.getURLString());
    print("returned json=" + jsonResponseString);

    List<RemoteDto> list;
    list = jsonTools.processRemoteWaterLineFieldDtoListJson(jsonResponseString);
    return list;
  }

  Future<bool> storeWaterLineFieldsList(List<RemoteDto> list) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    late String tableName;
    RemoteDto remoteDto;
    late RemoteStatusDto remoteState;

    bool finalEntryReceived = true;
    for (int f = 0; f < list.length; f++) {
      finalEntryReceived = false;
      tableName = list[f].water_table_name;
      if (tableName == "remote_state") {
        remoteState = list[f] as RemoteStatusDto;
        finalEntryReceived = true;
        break;
      }
      remoteDto = list[f];
      await abstractRemoteFieldWarden.init();
      try {
        await abstractRemoteFieldWarden.updateClient();
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
          print("WS $e");
      }
    } // for
    try {
      if (abstractRemoteFieldWarden.getRemoteDto() != null)
        abstractRemoteFieldWarden.updateMaxTs();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
    }
    if (tableName == "remote_state") {
      if (remoteState.isError())
        throw RemoteStatusException(remoteState.status!,
            cause: remoteState.message);
    }
    return finalEntryReceived;
  }
}
