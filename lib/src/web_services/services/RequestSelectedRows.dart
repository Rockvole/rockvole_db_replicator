import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

/**
 * This receives a list of water_line_field table entries from the User or Read Server
 * <p>
 * We return a list of rows from the requested tables.
 *
 */
class RequestSelectedRows extends AbstractEntries {
  final String C_THIS_NAME = " REQUEST SELECTED ROWS ";
  late JsonRemoteWaterLineFieldDtoTools jsonTools;
  //RemoteWaterLineFieldDtoPartitionTools partitionTools;
  late List<RemoteDto> remoteDtoList;
  AbstractFieldWarden? abstractFieldWarden;
  late UserStoreDao userStoreDao;
  ConfigurationNameDefaults defaults;

  RequestSelectedRows(SchemaMetaData smd, this.defaults) : super(smd);

  Future<void> init() async {
    jsonTools = JsonRemoteWaterLineFieldDtoTools(smdSys);
    //partitionTools = RemoteWaterLineFieldDtoPartitionTools();
  }

  Future<String> putEntry(int userId, int ts, int version, String? testPassword,
      String? database, String signature, String? jsonString) async {
    print(
        "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////" +
            C_THIS_NAME +
            "REQUEST");
    print(
        "PARAMS:user_id=$userId||ts=$ts||version=$version||database=$database||sig=$signature");
    print("jsonString=$jsonString");
    //List<RemoteDto> joinedRowsList = List();
    try {
      await validateRequest(testPassword, database);
      await validateServer();
      if (version < AbstractEntries.C_MINIMUM_VERSION) {
        throw RemoteStatusException(RemoteStatus.VERSION_NOT_MATCH);
      }
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
      params["version"] = version.toString();

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
        remoteDtoList =
            jsonTools.processRemoteWaterLineFieldDtoListJson(jsonString);

        //joinedRowsList = partitionTools.retrieveJoinedRows(remoteDtoList, localWardenType, remoteWardenType, transaction);
      } else {
        // Authentication Failed
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
      print("returnJson=$remoteDtoList");
      try {
        userStoreDao = UserStoreDao(smd, transaction);
        await userStoreDao.init();
        UserStoreDto userStoreDto = await userStoreDao
            .getUserStoreDtoByUnique(remoteUserStoreDto!.email!);
        userStoreDto.records_downloaded = userStoreDto.records_downloaded! + 1;
        await userStoreDao.updateUserStoreDtoByUnique(userStoreDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE)
          print("WS $e");
      }
    } on RemoteStatusException catch (e) {
      print(RemoteStatusDto.getDefaultMessage(e.remoteStatus));
      remoteDtoList.add(RemoteStatusDto.sep(smdSys,
          status: e.remoteStatus, message: e.cause));
    } finally {
      await endTransaction();
    }
    return JsonRemoteDtoTools.getJsonStringFromRemoteDtoList(
        remoteDtoList, defaults);
  }
}
