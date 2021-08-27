import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

/**
 * This receives a list of water_line_field table entries from the User or Read Server
 * and updates the database with those entries.
 * <p>
 * We return a list of processed water_line_field entries so the client
 * can update its water_line_field status
 *
 * LIKE/DISLIKE entries received will increment/decrement the like count of that field by 1
 * INCREMENT/DECREMENT entries received will increment/decrement the count of the field by the supplied amount
 * NOTIFY - NOT Passed.
 *
 */
class PostWaterLineFields extends AbstractEntries {
  final String C_THIS_NAME = " POST WATER LINE FIELDS ";
  late JsonRemoteWaterLineFieldDtoTools jsonTools;
  late List<RemoteDto> remoteWaterLineFieldDtoList;
  AbstractFieldWarden? abstractFieldWarden;
  ConfigurationNameDefaults defaults;

  PostWaterLineFields(SchemaMetaData smd, this.defaults) : super(smd);

  Future<void> init() async {
    jsonTools =
        JsonRemoteWaterLineFieldDtoTools(smdSys);
  }

  Future<String> putEntry(int userId, int ts, String? testPassword,
      String? database, String signature, String? jsonString) async {
    print(
        "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////" +
            C_THIS_NAME +
            "REQUEST");
    print("PARAMS:user_id=$userId||ts=$ts||testPassword=$testPassword||database=$database||sig=$signature");
    print("jsonString=$jsonString");
    List<RemoteDto> remoteDtoList = [];
    try {
      await validateRequest(testPassword, database);
      await validateServer();
      isEmailFresh(userId);
      await validateUser(userId);

      localWardenType = localUserDto!.warden;
      remoteWardenType = remoteUserDto.warden;
      // ------------------------------------------------------------ Validation Complete
      print(
          "--------------------------------------------------------------------------------------------------------------------------------" +
              C_THIS_NAME +
              "VALIDATION");
      SignedRequestHelper2 signedRequestHelper = SignedRequestHelper2(
          remoteUserStoreDto!.email!, remoteUserDto.pass_key!);
      Map<String, String> params = Map();
      params["ts"] = ts.toString();

      if (testMode) {
        if (database != null) params["database"] = database;
        params["test_pass"] = AbstractEntries.C_TEST_PASSWORD;
      }
      params["user_id"] = remoteUserDto.id.toString();
      String generateSignature = SignedRequestHelper2.percentDecodeRfc3986(
          signedRequestHelper.getHmac(params));
      if (signature == generateSignature) {
        // Authenticated

        if (abstractFieldWarden == null) {
          abstractFieldWarden = AbstractFieldWarden(
              localWardenType, remoteWardenType, smd, smdSys, transaction);
        }
        remoteWaterLineFieldDtoList =
            jsonTools.processRemoteWaterLineFieldDtoListJson(jsonString);
        RemoteDto remoteDto;
        RemoteWaterLineFieldDto remoteWaterLineFieldDto;

        Iterator<RemoteDto> iter = remoteWaterLineFieldDtoList.iterator;
        WaterLineFieldDto? returnWaterLineFieldDto;
        while (iter.moveNext()) {
          print(
              "--------------------------------------------------------------------------------------------------------------------------------" +
                  C_THIS_NAME);
          remoteDto = iter.current;
          remoteWaterLineFieldDto = remoteDto as RemoteWaterLineFieldDto;
          print("rwlfdto=$remoteWaterLineFieldDto");

          await abstractFieldWarden!
              .init(remoteWaterLineFieldDto.getWaterLineFieldDto());
          try {
            returnWaterLineFieldDto = await abstractFieldWarden!.write();
            remoteDtoList.add(RemoteWaterLineFieldDto(
                returnWaterLineFieldDto!, smdSys,
                waterLineDto: WaterLineDto.sep(
                    0, null, null, WaterLineFieldDto.C_TABLE_ID, smdSys)));
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
              print("WS $e");
          }
        }
      } else {
        // Authentication Failed
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
    } on RemoteStatusException catch (e) {
      return JsonRemoteDtoConversion.getJsonFromRemoteState(RemoteStatusDto.sep(
              smdSys,
              status: e.remoteStatus,
              message: e.cause))
          .toString();
    } finally {
      await endTransaction();
    }
    return JsonRemoteDtoTools.getJsonStringFromRemoteDtoList(
        remoteDtoList, defaults);
  }
}
