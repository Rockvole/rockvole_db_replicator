import 'dart:convert';
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
 * This is used to update the appropriate table values
 * <p>
 * VOTING will return the total LIKE/DISLIKE counts<br/>
 * NUMERALS will return the total INCREMENT/DECREMENT counts<br/>
 * CHANGES will return water_line_field entries to indicate that
 * those rows have been updated<br/>
 *
 */
class GetLatestWaterLineFields extends AbstractEntries {
  final String C_THIS_NAME = " GET LATEST WATER LINE FIELDS ";
  late JsonRemoteWaterLineFieldDtoTools jsonRemoteWaterLineFieldDtoTools;
  ChangeSuperType? changeSuperType;
  AbstractRemoteFieldWarden? abstractRemoteFieldWarden;
  ConfigurationNameDefaults defaults;

  GetLatestWaterLineFields(SchemaMetaData smd, this.defaults) : super(smd);

  Future<void> init() async {
    jsonRemoteWaterLineFieldDtoTools =
        JsonRemoteWaterLineFieldDtoTools(smdSys);
  }

  Future<String> getJsonEntries(
      int? userId,
      int? remoteTs,
      int? changeSuperTypeInt,
      int? limit,
      String? signature,
      int? ts,
      String? testPassword,
      String? database) async {
    print(
        "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////" +
            C_THIS_NAME +
            "REQUEST");
    print(
        "PARAMS:user_id=$userId||remote_ts=$remoteTs||change_super_type=$changeSuperTypeInt||limit=$limit||ts=$ts||database=$database");
    List<RemoteDto> remoteDtoList;
    try {
      if (ts == null) {
        throw RemoteStatusException(RemoteStatus.TS_MANDATORY);
      }
      if (remoteTs == null) {
        throw RemoteStatusException(RemoteStatus.WATER_LINE_FIELD_MANDATORY);
      }
      changeSuperType = WaterLineField.getChangeSuperType(changeSuperTypeInt);

      await validateRequest(testPassword, database);
      await validateServer();
      isEmailFresh(userId);
      await validateUser(userId!);

      localWardenType = localUserDto!.warden;
      remoteWardenType = remoteUserDto.warden;
      if (remoteWardenType == WardenType.ADMIN &&
          localWardenType != WardenType.WRITE_SERVER) {
        throw RemoteStatusException(RemoteStatus.INVALID_SERVER_TYPE,
            cause: "invalid server type $localWardenType");
      }
      if (remoteWardenType == WardenType.READ_SERVER &&
          localWardenType != WardenType.WRITE_SERVER) {
        throw RemoteStatusException(RemoteStatus.INVALID_SERVER_TYPE,
            cause: "invalid server type $localWardenType");
      }
      if (remoteWardenType == WardenType.USER &&
          localWardenType == WardenType.WRITE_SERVER)
        localWardenType = WardenType
            .READ_SERVER; // User can only retrieve values from READ_SERVER
      if (remoteWardenType == WardenType.USER &&
          localWardenType != WardenType.READ_SERVER) {
        throw RemoteStatusException(RemoteStatus.INVALID_SERVER_TYPE,
            cause: "invalid server type $localWardenType");
      }
      // ------------------------------------------------------------ Validation Complete
      print(
          "--------------------------------------------------------------------------------------------------------------------------------" +
              C_THIS_NAME +
              "VALIDATION");
      SignedRequestHelper2 signedRequestHelper = SignedRequestHelper2(
          remoteUserStoreDto!.email!, remoteUserDto.pass_key!);
      Map<String, String> params = Map();
      params["ts"] = ts.toString();
      params["limit"] = limit.toString();
      params["remote_ts"] = remoteTs.toString();
      params["change_super_type"] = changeSuperTypeInt.toString();
      if (testMode) {
        if (database != null) params["database"] = database;
        params["test_pass"] = AbstractEntries.C_TEST_PASSWORD;
      }
      params["user_id"] = remoteUserDto.id.toString();
      String generateSignature = SignedRequestHelper2.percentDecodeRfc3986(
          signedRequestHelper.getHmac(params));
      if (signature == generateSignature) {
        // Authenticated
        print("Authenticated !!!!");
        if (abstractRemoteFieldWarden == null) {
          abstractRemoteFieldWarden = AbstractRemoteFieldWarden(
              localWardenType, remoteWardenType, smd, smdSys, transaction);
          await abstractRemoteFieldWarden!.init();
        }
        remoteDtoList = await abstractRemoteFieldWarden!
            .getRemoteFieldListAboveLocalTs(remoteTs, changeSuperType!, 100);
      } else {
        // Authentication Failed
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
      print("rdto=$remoteDtoList");
    } on RemoteStatusException catch (e) {
      print(e.toString());
      return jsonEncode(JsonRemoteDtoConversion.getJsonFromRemoteState(
          RemoteStatusDto.sep(smdSys,
              status: e.remoteStatus, message: e.cause)));
    } finally {
      await endTransaction();
    }
    return JsonRemoteDtoTools.getJsonStringFromRemoteDtoList(
            remoteDtoList, defaults)
        .toString();
  }
}
