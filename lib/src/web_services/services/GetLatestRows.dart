import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

/**
 * Get the latest Rows from the server to send to the user
 *
 */
class GetLatestRows extends AbstractEntries {
  final String C_THIS_NAME = " GET LATEST ROWS ";
  late WaterLineTools waterLineTools;
  ServerWarden? serverWarden;
  late WaterLineDao waterLineDao;
  late UserStoreDao userStoreDao;
  late ConfigurationNameDefaults defaults;

  GetLatestRows(SchemaMetaData smd, this.defaults) : super(smd);

  Future<void> init() async {
    waterLineTools = WaterLineTools(smd, smdSys, defaults);
  }

  Future<String> getJsonEntries(
      int? userId,
      int? waterLineTs,
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
        "PARAMS:user_id=$userId||water_line=$waterLineTs||limit=$limit||ts=$ts||database=$database");
    List<RemoteDto>? remoteDtoList;
    try {
      if (ts == null) {
        throw RemoteStatusException(RemoteStatus.TS_MANDATORY);
      }
      if (waterLineTs == null) {
        throw RemoteStatusException(RemoteStatus.WATER_LINE_MANDATORY);
      }
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
      params["water_line"] = waterLineTs.toString();
      params["user_id"] = remoteUserDto.id.toString();
      if (testMode) {
        if (database != null) params["database"] = database;
        params["test_pass"] = AbstractEntries.C_TEST_PASSWORD;
      }
      List<WaterLineDto>? waterLineList;
      String generateSignature = SignedRequestHelper2.percentDecodeRfc3986(
          signedRequestHelper.getHmac(params));
      if (signature == generateSignature) {
        // Authenticated
        if (serverWarden == null) {
          waterLineDao = WaterLineDao.sep(smdSys, transaction);
          await waterLineDao.init();
          serverWarden = ServerWarden(remoteWardenType!, waterLineDao);
        }
        int? C_MAX_ROWS_LIMIT;

        ConfigurationDao configParams =
            ConfigurationDao(smd, transaction, defaults);
        await configParams.init(initTable: true);

        if (limit == null) {
          try {
            limit = await configParams.getInteger(
                0,
                remoteUserDto.warden,
                ConfigurationNameEnum.ROWS_LIMIT);
          } on Exception catch (e) {
            print("WS $e");
          }
        }
        bool noMoreEntries = false;
        try {
          C_MAX_ROWS_LIMIT = await configParams.getInteger(
              0,
              localWardenType,
              ConfigurationNameEnum.ROWS_LIMIT);
          if (limit! > C_MAX_ROWS_LIMIT!) limit = C_MAX_ROWS_LIMIT;

          print("Retrieve water_line above='$waterLineTs'");
          waterLineList = await serverWarden!.getWaterLineListAboveTs(
              waterLineTs, limit);
          print("waterLineList=$waterLineList");
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
            noMoreEntries = true;
          } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
            print("WS $e");
        }

        remoteDtoList = await waterLineTools.processWaterLineList(
            waterLineList,
            waterLineDao,
            noMoreEntries,
            localWardenType,
            remoteUserDto,
            transaction);
      } else {
        // Authentication Failed
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
      print("rdto=$remoteDtoList");
      if (waterLineList != null) {
        // Update user_store
        int waterLineListSize = waterLineList.length;
        if (waterLineListSize > 0) {
          try {
            userStoreDao = UserStoreDao(smd, transaction);
            await userStoreDao.init(initTable: true);
            UserStoreDto userStoreDto = await userStoreDao
                .getUserStoreDtoByUnique(remoteUserStoreDto!.email!);
            userStoreDto.last_seen_ts = TimeUtils.getNowCustomTs();
            await userStoreDao.updateUserStoreDtoByUnique(userStoreDto);
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE)
              print("WS $e");
          }
        }
      }
    } on RemoteStatusException catch (e) {
      print(e.toString());
      return jsonEncode(
          RemoteStatusDto.sep(smdSys, status: e.remoteStatus, message: e.toString())
              .toMap());

    } finally {
      await endTransaction();
    }
    return JsonRemoteDtoTools.getJsonStringFromRemoteDtoList(remoteDtoList, defaults);
  }
}
