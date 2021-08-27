import 'dart:convert';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class GetAuthentication extends AbstractEntries {
  final String C_THIS_NAME = " GET AUTHENTICATION ";
  ServerWarden? serverWarden;
  late WaterLineDao waterLineDao;
  late StringUtils stringUtils;
  int? recordCount;

  GetAuthentication(SchemaMetaData smd) : super(smd);

  Future<void> init() async {
    stringUtils = StringUtils();
  }

  Future<String> getJsonEntries(
      int? userId,
      String? email,
      int? waterLineTs,
      int? crc,
      String? signature,
      int? ts,
      int? version,
      String? testPassword,
      String? database) async {
    print(
        "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////" +
            C_THIS_NAME +
            "REQUEST");
    int cts = TimeUtils.getNowCustomTs();
    print("Current Server Time=$cts");
    print(
        "PARAMS:user_id=$userId||email=$email||water_line=$waterLineTs||version=$version||crc=$crc||ts=$ts||database=$database||sig=$signature");
    Map<String, dynamic> tablesArray = Map();
    try {
      bool freshEmail = isEmailFresh(userId);
      await validateRequest(testPassword, database);
      await validateServer();
      if (version! < AbstractEntries.C_MINIMUM_VERSION) {
        throw RemoteStatusException(RemoteStatus.VERSION_NOT_MATCH);
      }
      // If email is passed, check if user is in database with no passKey and generate and return
      if (email != null) {
        UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
        await userStoreDao.init();
        UserDao userDao = UserDao(smd, transaction);
        await userDao.init();
        try {
          remoteUserStoreDto =
              await userStoreDao.getUserStoreDtoByUnique(email);
          remoteUserDto = await userDao.getUserDtoById(remoteUserStoreDto!.id!);
          if (remoteUserDto.pass_key == null ||
              remoteUserDto.pass_key!.length == 0) {
            TrDto trDto = TrDto.sep(null, OperationType.UPDATE, 0, null,
                "Add PassKey", null, UserMixin.C_TABLE_ID);
            String passKey;
            if (remoteUserDto.warden == WardenType.USER)
              passKey = stringUtils.randomAlphaNumericString(6);
            else
              passKey = stringUtils.randomAlphaNumericString(20);
            remoteUserDto.pass_key = passKey;

            TrDto userTrDto = TrDto.clone(trDto, fieldData: remoteUserDto);
            AbstractTableTransactions userTransactions =
                TableTransactions.sep(userTrDto);
            await userTransactions.init(WardenType.WRITE_SERVER,
                WardenType.WRITE_SERVER, smd, smdSys, transaction);
            AbstractWarden warden = WardenFactory.getAbstractWarden(
                WardenType.WRITE_SERVER, WardenType.WRITE_SERVER);
            await warden.init(smd, smdSys, transaction);
            warden.initialize(userTransactions);
            try {
              await warden.write();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
                print("WS $e");
            }

            tablesArray = JsonRemoteDtoConversion.getJsonFromUserTrDto(
                UserTrDto.field(userTrDto), null);

            return jsonEncode(tablesArray);
          } else if (signature == null) {
            throw RemoteStatusException(RemoteStatus.EXPECTED_PASSKEY);
          }
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) {
            RemoteDto? userRemoteDto;
            TrDto trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
                "Inserting new user", null, UserMixin.C_TABLE_ID);
            int requestOffsetSecs =
                NumberUtils.randInt(0, TimeUtils.C_SECS_IN_DAY);
            UserDto userDto = UserDto.sep(
                null,
                stringUtils.randomAlphaNumericString(6),
                0,
                WardenType.USER,
                requestOffsetSecs,
                0);
            TrDto userTrDto = TrDto.clone(trDto, fieldData: userDto);

            AbstractTableTransactions userTransactions =
                TableTransactions.sep(userTrDto);
            await userTransactions.init(WardenType.WRITE_SERVER,
                WardenType.ADMIN, smd, smdSys, transaction);
            AbstractWarden abstractWarden = WardenFactory.getAbstractWarden(
                WardenType.WRITE_SERVER, WardenType.ADMIN);
            await abstractWarden.init(smd, smdSys, transaction);
            abstractWarden.initialize(userTransactions,
                passedWaterState: WaterState.CLIENT_STORED);
            try {
              userRemoteDto = await abstractWarden.write();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
                print("WS $e");
            }
            userTrDto = userRemoteDto!.trDto;
            UserTrDto returnUserTrDto;

            // Now read back the written entry and put in the correct ts
            UserTrDao userTrDao = UserTrDao(smdSys, transaction);
            await userTrDao.init();
            userTrDto.set("registered_ts", TimeUtils.getNowCustomTs());
            try {
              await userDao.getUserDtoById(userTrDto.id!);
              await userDao
                  .setUserDto(UserDto.field(userTrDto.getFieldDataNoTr));
              returnUserTrDto =
                  await userTrDao.upsertDto(UserTrDto.field(userTrDto));
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
                print("WS $e");
            }
            // ---------------------------------------------------------------------------------------------------- USER STORE
            RemoteDto? userStoreRemoteDto;
            trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
                "Inserting new user", null, UserStoreMixin.C_TABLE_ID);
            UserStoreDto userStoreDto = UserStoreDto.sep(userTrDto.id!, email,
                TimeUtils.getNowCustomTs(), null, null, 0, 0, 0);
            UserStoreTrDto userStoreTrDto =
                UserStoreTrDto.wee(userStoreDto, trDto);

            AbstractTableTransactions userStoreTransactions =
                TableTransactions.sep(userStoreTrDto);
            await userStoreTransactions.init(WardenType.WRITE_SERVER,
                WardenType.WRITE_SERVER, smd, smdSys, transaction);
            abstractWarden.initialize(userStoreTransactions,
                passedWaterState: WaterState.CLIENT_STORED);
            try {
              userStoreRemoteDto = await abstractWarden.write();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
                  e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                  e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
                print("WS $e");
              }
            }
            tablesArray = JsonRemoteDtoConversion.getJsonFromUserTrDto(
                UserTrDto.field(userTrDto), null);

            return jsonEncode(tablesArray);
          }
        }
      } else {
        // email is null
        if (waterLineTs == null) {
          throw RemoteStatusException(RemoteStatus.WATER_LINE_MANDATORY);
        }
        if (crc == null) {
          throw RemoteStatusException(RemoteStatus.CRC_MANDATORY);
        }
        await validateUser(userId!);
      }
      // ------------------------------------------------------------ Validation Complete
      print(
          "--------------------------------------------------------------------------------------------------------------------------------" +
              C_THIS_NAME +
              "VALIDATION");

      if ((remoteUserDto.pass_key == null ||
              remoteUserDto.pass_key!.length == 0) &&
          email == null) {
        // Make client send email address next time
        throw RemoteStatusException(RemoteStatus.FRESH_PASSKEY);
      }
      // ------------------------------------------------------------------------------------------------ AUTHENTICATION
      SignedRequestHelper2 signedRequestHelper = SignedRequestHelper2(
          remoteUserStoreDto!.email!, remoteUserDto.pass_key!);
      Map<String, String> params = Map();
      if (testMode) {
        if (database != null) params["database"] = database;
        params["test_pass"] = AbstractEntries.C_TEST_PASSWORD;
      }
      if (waterLineTs != null) params["water_line"] = waterLineTs.toString();
      params["ts"] = ts.toString();
      params["version"] = version.toString();
      params["user_id"] = userId.toString();
      String generateSignature = SignedRequestHelper2.percentDecodeRfc3986(
          signedRequestHelper.getHmac(params));
      if (signature == generateSignature) {
        // Authenticated
        if (freshEmail) {
          // User doesn't have user_id so return it
          TrDto trDto = TrDto.sep(null, OperationType.INSERT, 0, null,
              "Returning user_id", null, UserMixin.C_TABLE_ID);
          UserTrDto userTrDto = UserTrDto.wee(remoteUserDto, trDto);

          tablesArray =
              JsonRemoteDtoConversion.getJsonFromUserTrDto(userTrDto, null);

          return jsonEncode(tablesArray);
        } else if (crc != null &&
            !(crc ==
                CrcUtils.getCrcFromString((remoteUserDto.getCrcString())))) {
          // UserDto crc does not match so pass back changes
          print("crc dont match " +
              CrcUtils.getCrcFromString((remoteUserDto.getCrcString()))
                  .toString());
          UserDao userDao = UserDao(smd, transaction);
          await userDao.init();
          UserDto? newUserDto;
          try {
            newUserDto = await userDao.getUserDtoById(remoteUserDto.id!);
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
              print("WS $e");
          }
          newUserDto!.pass_key = null; // Dont pass back passKey
          UserTrDto userTrDto = UserTrDto.wee(newUserDto, null);

          tablesArray =
              JsonRemoteDtoConversion.getJsonFromUserTrDto(userTrDto, null);

          return jsonEncode(tablesArray);
        }
        if (serverWarden == null) {
          waterLineDao = WaterLineDao.sep(smdSys, transaction);
          await waterLineDao.init(initTable: false);
          serverWarden = ServerWarden(remoteUserDto.warden, waterLineDao);
        }
        try {
          recordCount = await serverWarden!
              .getWaterLineRecordCount(waterLineTs);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
            print("WS $e");
        }
        AuthenticationDto auth = AuthenticationDto.sep(
            recordCount!, cts, localUserDto!.warden, smdSys);

        tablesArray =
            JsonRemoteDtoConversion.getJsonFromAuthenticationDto(auth);
      } else {
        // Authentication Failed
        print(remoteUserDto);
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
    } on RemoteStatusException catch (e) {
      print(e.cause);
      return jsonEncode(JsonRemoteDtoConversion.getJsonFromRemoteState(
          RemoteStatusDto.sep(smdSys,
              status: e.remoteStatus, message: e.cause)));
    } finally {
      await endTransaction();
    }
    print("Record Count=$recordCount");
    return jsonEncode(tablesArray);
  }
}
