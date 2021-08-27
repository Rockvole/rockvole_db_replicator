import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class RestGetAuthenticationUtils extends AbstractRestUtils {
  UserChangeListener? userChangeListener;
  late ClientWarden clientWarden;

  RestGetAuthenticationUtils(
      WardenType? localWardenType,
      WardenType? remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults,
      this.userChangeListener)
      : super.sep(localWardenType, remoteWardenType, smd, smdSys, transaction,
            userTools, defaults);

  Future<void> init() async {
    await super.init();
    clientWarden = ClientWarden(localWardenType, waterLineDao);
  }

  // --------------------------------------------------------------------------------------------------------------------------- AUTHENTICATION
  Future<RemoteDto> sendAuthenticationRequest(
      int version, String? serverDatabase, String? testPassword) async {
    if (initialized == false) throw ArgumentError(AbstractDao.C_MUST_INIT);
    String url = "";
    UserDto? cuDto = await userTools.getCurrentUserDto(smd, transaction);
    int? cuId = await userTools.getCurrentUserId(smd, transaction);
    UserStoreDto? cuStoreDto;
    String email = "";
    try {
      cuStoreDto = await userTools.getCurrentUserStoreDto(smd, transaction);
      email = cuStoreDto!.email!;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }

    if (cuDto!.pass_key == null || cuDto.pass_key!.length == 0) {
      // User has missing pass_key
      url += "email=" + email;
      if (serverDatabase != null) url += "&database=" + serverDatabase;
      if (testPassword != null) url += "&test_pass=" + testPassword;
      url += "&ts=" + TimeUtils.getNowCustomTs().toString();
      url += "&version=" + version.toString();
      url += "&user_id=" + cuId.toString();
    } else {
      Map<String, String> params = Map();
      if (serverDatabase != null) params["database"] = serverDatabase;
      if (testPassword != null) params["test_pass"] = testPassword;
      params["water_line"] = (await clientWarden.getLatestTs()).toString();
      params["ts"] = TimeUtils.getNowCustomTs().toString();
      params["version"] = version.toString();
      params["user_id"] = cuId.toString();

      SignedRequestHelper2 signedRequestHelper =
          SignedRequestHelper2(email, cuDto.pass_key!);
      url += signedRequestHelper.sign(params);
      if (cuId == 1) url += "&email=" + email;
      url +=
          "&crc=" + CrcUtils.getCrcFromString(cuDto.getCrcString()).toString();
    }
    late String response;
    try {
      response = await writeClient.getBaseURI(UrlTools.C_AUTHENTICATE_URL, url);
    } on TransmitStatusException catch (e) {
      print("WS $e");
      throw TransmitStatusException(e.transmitStatus,
          cause: "Send Authentication");
    }
    // Process response
    RemoteDto remoteDto;
    try {
      remoteDto = JsonRemoteDtoTools.getRemoteDtoFromJsonString(
          response, smdSys, defaults);
    } on RemoteStatusException catch (e) {
      print("WS $e");
      throw TransmitStatusException(TransmitStatus.REMOTE_STATE_ERROR,
          cause: "Send Authentication");
    }
    return remoteDto;
  }

  Future<RemoteDto> requestAuthenticationFromServer(int version,
      {String? serverDatabase, String? testPassword}) async {
    if (initialized == false) throw ArgumentError(AbstractDao.C_MUST_INIT);
    RemoteDto remoteDto =
        await sendAuthenticationRequest(version, serverDatabase, testPassword);
    if (remoteDto.water_table_id == RemoteStatusDto.C_TABLE_ID) {
      RemoteStatusDto remoteState = remoteDto as RemoteStatusDto;
      print("State=$remoteState");
      switch (remoteState.getStatus()) {
        case RemoteStatus.FRESH_PASSKEY:
          UserDto? userDto =
              await userTools.getCurrentUserDto(smd, transaction);
          print("get fresh $userDto");
          userDto!.pass_key =
              ""; // Email address is only sent when passKey is empty
          await userTools.setCurrentUserDto(smd, transaction, userDto);
          remoteDto = await sendAuthenticationRequest(
              version, serverDatabase, testPassword);
          break;
        default:
          throw TransmitStatusException(null,
              remoteStatus: remoteState.getStatus(),
              cause: "Send Authentication");
      }
    }
    if (remoteDto.water_table_id == UserMixin.C_TABLE_ID) {
      UserChangeEnum? userChangeEnum =
          await writeNewUser(UserDto.field(remoteDto.trDto));
      remoteDto = await sendAuthenticationRequest(
          version, serverDatabase, testPassword);
      if (userChangeListener != null)
        userChangeListener!.update(userChangeEnum);
      if (remoteDto.water_table_id == RemoteStatusDto.C_TABLE_ID) {
        RemoteStatusDto remoteState = remoteDto as RemoteStatusDto;
        throw TransmitStatusException(null,
            remoteStatus: remoteState.getStatus(),
            cause: "Send Authentication");
      }
    }
    return remoteDto;
  }

  Future<UserChangeEnum?> writeNewUser(UserDto userDto) async {
    UserChangeEnum? userChangeEnum;
    userTools.clearUserCache();
    // Read the latest user entry with newly assigned id
    UserDto? currentUserDto =
        await userTools.getCurrentUserDto(smd, transaction);
    int? newId = userDto.id;

    if (currentUserDto!.id != newId) {
      // rewrite the Ids
      UserStoreDto? userStoreDto =
          await userTools.getCurrentUserStoreDto(smd, transaction);
      int? userStoreId = userStoreDto!.id;

      // Modify user_store entry id
      try {
        UserStoreTrDao userStoreTrDao = UserStoreTrDao(smdSys, transaction);
        await userStoreTrDao.init();
        await userStoreTrDao.modifyField(userStoreId!, newId!, 'id');
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
          print(e.cause);
      }
      try {
        UserStoreDao userStoreDao = UserStoreDao(smd, transaction);
        await userStoreDao.init();
        await userStoreDao.modifyId(userStoreId!, newId!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
          print(e.cause);
      }
      userChangeEnum = UserChangeEnum.USER_ID;
    }
    if (userDto.warden != currentUserDto.warden) {
      userChangeEnum = UserChangeEnum.WARDEN;
    }
    if (userDto.pass_key == null) {
      userDto.pass_key = currentUserDto.pass_key;
      userChangeEnum = UserChangeEnum.PASS_KEY;
    }
    await userTools.setCurrentUserDto(smd, transaction, userDto);
    return userChangeEnum;
  }
}
