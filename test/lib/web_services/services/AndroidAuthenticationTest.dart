import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class AndroidAuthenticationTest extends AbstractRequestTest {
  static final String C_EMAIL = "blah@blah.com";
  static late RestGetAuthenticationUtils restInformationUtils;

  AndroidAuthenticationTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
  Future<DbTransaction> test001_SetUp(
      WardenType localWT,
      WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    localTransaction = await super.test001_SetUp(
        WardenType.USER,
        WardenType.USER,
        localDatabaseName: "client_db",
        remoteDatabaseName: "server_db");
    await initializeTables(1, localTransaction);

    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    return remoteTransaction;
  }

  @override
  Future<void> test005_CloneFromCsv(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTrTableTypeEnumSet.add(WaterLineDto.C_TABLE_ID);
    await super.test005_CloneFromCsv(
        localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test007_CloneFromCsvToRemote(
      DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTableTypeEnumSet.add(UserMixin.C_TABLE_ID);
    minTableTypeEnumSet.add(UserStoreMixin.C_TABLE_ID);
    Set<int> waterLineEnumSet = {WaterLineDto.C_TABLE_ID};
    await super.test007_CloneFromCsvToRemote(
        remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: waterLineEnumSet);
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();
  }

  @override
  Future<void> test015_UpdateConfiguration(
      WardenType localWT,
      WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(
        localWardenType, WardenType.NULL, transaction: localTransaction);
    try {
      restPostNewRowUtils = RestPostNewRowUtils(
          localWardenType,
          remoteWardenType,
          smd,
          smdSys,
          localTransaction,
          localUserTools,
          defaults); // Load current user
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        fail(e.cause!);
      }
    }
  }

  // Insert an extra user so that we can test what happens when there will be a gap in user_store
  @override
  Future<void> test017_InsertUnbalancedUser() async {
    await super.test017_InsertUnbalancedUser();
    await CrudHelper.insertUser(
        null,
        "unbalance",
        0,
        WardenType.USER,
        0,
        12345,
        remoteTransaction,
        WardenType.WRITE_SERVER,
        WardenType.ADMIN,
        smd,
        smdSys);
  }

  // Simulate brand new user
  @override
  Future<void> test020_GetNewUser() async {
    await super.test020_GetNewUser();
    await insertUnknownUser();
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    try {
      await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    UserStoreDto? remoteUserStoreDto = await TestHelper_Fetch.fetchUserStore(
        "new@email.com", smd, remoteTransaction);
    int userId = remoteUserStoreDto!.id!;
    UserDto? remoteUserDto =
        await TestHelper_Fetch.fetchUserById(userId, smd, remoteTransaction);
    UserDto? localUserDto =
        await TestHelper_Fetch.fetchUserById(userId, smd, localTransaction);
    TestUserDataStruct userStruct = TestUserDataStruct(
        pass_key: remoteUserDto!.pass_key, subset: 0, warden: WardenType.USER);
    TestHelper_Check.checkUser(
        localUserDto!, userStruct, IdentSpace.SERVER_SPACE, true);
    UserStoreDto? localUserStoreDto = await TestHelper_Fetch.fetchUserStore(
        "new@email.com", smd, localTransaction);
    TestUserStoreDataStruct userStoreStruct =
        TestUserStoreDataStruct(id: userId, name: "New", surname: "Email");
    TestHelper_Check.checkUserStore(
        localUserStoreDto!, userStoreStruct, IdentSpace.SERVER_SPACE, true);
  }

  // Simulate User typing in their email and pass key from fresh
  Future<void> test030_GetMissingUserId() async {
    await super.test030_GetMissingUserId();
    try {
      await moveCurrentUser(1, null);
    } on SqlException {
      // Ignore and assume it worked
    }
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    try {
      await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    UserStoreDto? remoteUserStoreDto = await TestHelper_Fetch.fetchUserStore(
        "new@email.com", smd, remoteTransaction);
    int userId = remoteUserStoreDto!.id!;
    UserDto? remoteUserDto =
        await TestHelper_Fetch.fetchUserById(userId, smd, remoteTransaction);
    UserDto? localUserDto =
        await TestHelper_Fetch.fetchUserById(userId, smd, localTransaction);
    TestUserDataStruct userStruct = TestUserDataStruct(
        pass_key: remoteUserDto!.pass_key, subset: 0, warden: WardenType.USER);
    TestHelper_Check.checkUser(
        localUserDto!, userStruct, IdentSpace.SERVER_SPACE, true);
    UserStoreDto? localUserStoreDto = await TestHelper_Fetch.fetchUserStore(
        "new@email.com", smd, localTransaction);
    TestUserStoreDataStruct userStoreStruct =
        TestUserStoreDataStruct(id: userId, name: "New", surname: "Email");
    TestHelper_Check.checkUserStore(
        localUserStoreDto!, userStoreStruct, IdentSpace.SERVER_SPACE, true);
  }

  // Simulate user changing their email address manually (app changes user_id to 1)
  Future<void> test040_UserWrongPasskey() async {
    print(AbstractRequestTest.preamble + "Authenticate User Wrong Passkey");
    await moveCurrentUser(1, "wrong1");
    // Now send Authentication request
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    try {
      await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      expect(e.transmitStatus, TransmitStatus.REMOTE_STATE_ERROR);
    }
  }

  Future<void> test050_InsertUser() async {
    UserDto userDto = UserDto.sep(2, "g5sn8", 0, WardenType.USER, 0, 23932);
    UserStoreDto userStoreDto = UserStoreDto.sep(
        2, "jason@druce.com", 376894, "Jason", "Druce", 0, 0, 0);
    await TestHelper_Check.setupWriteServer(
        userDto, userStoreDto, smd, remoteTransaction);
    await TestHelper_Check.setCurrentUserDetails(
        userDto, userStoreDto, localUserTools, smd, localTransaction);
  }

  Future<void> test055_Authenticate_UpgradeUser() async {
    await super.test055_Authenticate_UpgradeUser();
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    UserStoreDto? currentUserStoreDto;
    try {
      currentUserStoreDto =
          await localUserTools.getCurrentUserStoreDto(smd, localTransaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail(e.cause!);
    }
    UserDto? currentUserDto = await DataBaseFunctions.alterUserByTransaction(
        currentUserStoreDto!.email!, WardenType.ADMIN, smd, remoteTransaction, closeTransaction: false);

    UserDao remoteUserDao = UserDao(smd, remoteTransaction);
    await remoteUserDao.init();
    late UserDto remoteUserDto;
    try {
      remoteUserDto = await remoteUserDao.getUserDtoById(currentUserDto!.id!);
      print("rdto=$remoteUserDto");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
    expect(remoteUserDto.warden, WardenType.ADMIN);

    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("record count=" + authenticationDto.newRecords.toString());
        expect(authenticationDto.newRecords, 11);
        break;
      default:
        print(remoteDto.toString());
        fail("Only Authentication should be returned $remoteDto");
    }
  }

  Future<void> test065_Authenticate_Pending() async {
    await super.test065_Authenticate_Pending();
    try {
      await waterLineDao.deleteWaterLineByTs(158924618);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND) fail(e.cause!);
    }
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print(authenticationDto.toString());
        expect(authenticationDto.newRecords, 11);
        break;
      default:
        fail("Only Authentication should be returned " +
            remoteDto.water_table_name);
    }
  }

  Future<void> test080_Authenticate_WithRemotePassKeyNoLocal() async {
    await super.test080_Authenticate_WithRemotePassKeyNoLocal();
    await changeCurrentUser("", null);
    await changeCurrentUserOnRemote("12345");
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    try {
      await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      expect(e.remoteStatus, RemoteStatus.EXPECTED_PASSKEY);
    }
  }

  Future<void> test090_Authenticate_NoRemotePassKeyNoLocal() async {
    await super.test090_Authenticate_NoRemotePassKeyNoLocal();
    await changeCurrentUser("", null);
    await changeCurrentUserOnRemote("");

    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("record count=" + authenticationDto.newRecords.toString());
        expect(authenticationDto.newRecords, 0);
        break;
      default:
        fail("Only Authentication should be returned");
    }
  }

  Future<void> test100_Authenticate_NoRemotePassKeyWithLocal() async {
    await super.test100_Authenticate_NoRemotePassKeyWithLocal();
    await changeCurrentUserOnRemote("");

    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("record count=" + authenticationDto.newRecords.toString());
        expect(authenticationDto.newRecords, 0);
        break;
      default:
        fail("Only Authentication should be returned");
    }
  }

  Future<void> test110_Authenticate_WithAllPassKeys() async {
    await super.test110_Authenticate_WithAllPassKeys();
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("record count=" + authenticationDto.newRecords.toString());
        expect(authenticationDto.newRecords, 0);
        break;
      default:
        fail("Only Authentication should be returned");
    }
  }

  Future<void> test125_InsertUser() async {
    await super.test125_InsertUser();

    UserDto userDto = UserDto.sep(2, "g5sn8", 0, WardenType.USER, 0, 23932);
    UserStoreDto userStoreDto = UserStoreDto.sep(
        2, "jason@druce.com", 3462498, "Jason", "Druce", 0, 0, 0);
    await TestHelper_Check.setupWriteServer(
        userDto, userStoreDto, smd, remoteTransaction);
    await TestHelper_Check.setCurrentUserDetails(
        userDto, userStoreDto, localUserTools, smd, localTransaction);
  }

  Future<void> test135_Authenticate_CrcNotMatch() async {
    await super.test135_Authenticate_CrcNotMatch();
    await changeCurrentUser(null, WardenType.ADMIN);
    restInformationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        localTransaction,
        localUserTools,
        defaults,
        null);
    await restInformationUtils.init();
    late RemoteDto remoteDto;
    try {
      remoteDto = await restInformationUtils.requestAuthenticationFromServer(
          AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    AuthenticationDto authenticationDto;
    switch (remoteDto.water_table_id) {
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("record count=" + authenticationDto.newRecords.toString());
        expect(authenticationDto.newRecords, 0);
        break;
      default:
        print(remoteDto.toString());
        fail("Only Authentication should be returned " +
            remoteDto.water_table_name);
    }
    // Ensure results were changed back by server
    UserDto? userDto =
        await TestHelper_Fetch.fetchUserById(2, smd, localTransaction);
    TestUserDataStruct userStruct =
        TestUserDataStruct(subset: 0, warden: WardenType.USER);
    TestHelper_Check.checkUser(
        userDto!, userStruct, IdentSpace.SERVER_SPACE, true);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }

  // ----------------------------------------------------------------------------------------------------------------- TOOLS

  Future<void> moveCurrentUser(int newUserId, String? newPassKey) async {
    int? userId = await localUserTools.getCurrentUserId(smd, localTransaction);
    await localUserTools.setCurrentUserId(smd, localTransaction, newUserId);
    await userDao.modifyId(userId!, newUserId);
    await userStoreDao.modifyId(userId, newUserId);
    UserDto userDto = await userDao.getUserDtoById(newUserId);
    await userDao.updateUserById(newUserId, newPassKey, 0, userDto.warden,
        userDto.request_offset_secs!, userDto.registered_ts!);
  }

  // Change current local user on remote database to Warden.USER (mysql.test)
  Future<void> changeCurrentUserOnRemote(String passKey) async {
    UserDto? currentUserDto;
    try {
      currentUserDto =
          await localUserTools.getCurrentUserDto(smd, localTransaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail(e.cause!);
    }
    UserDao remoteUserDao = UserDao(smd, remoteTransaction);
    await remoteUserDao.init();
    UserDto remoteUserDto;
    try {
      remoteUserDto = await remoteUserDao.getUserDtoById(currentUserDto!.id!);
      print("rudto=$remoteUserDto");
      remoteUserDto.pass_key = passKey;
      remoteUserDto.warden = WardenType.USER;

      await remoteUserDao.setUserDto(remoteUserDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
  }

  // Change local current user database passkey and subset
  Future<void> changeCurrentUser(String? passKey, WardenType? wardenType) async {
    // ---------------------------------------------------------------------PASSKEY
    UserDto? currentUserDto;
    try {
      currentUserDto =
          await localUserTools.getCurrentUserDto(smd, localTransaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail(e.cause!);
    }
    print("cudto=$currentUserDto");
    if (passKey != null) currentUserDto!.pass_key = passKey;
    if (wardenType != null) currentUserDto!.warden = wardenType;
    try {
      await localUserTools.setCurrentUserDto(
          smd, localTransaction, currentUserDto!);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail(e.cause!);
    }
  }

  Future<void> wipeCurrentUserId() async {
    UserDto? currentUserDto;
    try {
      currentUserDto =
          await localUserTools.getCurrentUserDto(smd, localTransaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail(e.cause!);
    }
    try {
      await userDao.deleteUserById(currentUserDto!.id!);
      currentUserDto.registered_ts = null;
      await localUserTools.setCurrentUserDto(
          smd, localTransaction, currentUserDto);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        fail("Wipe Failure");
    }
  }

  Future<void> insertUnknownUser() async {
    try {
      int? currentUserId =
          await localUserTools.getCurrentUserId(smd, localTransaction);
      try {
        await userDao.deleteUserById(currentUserId!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
      }
      try {
        await userStoreDao.deleteUserStoreById(currentUserId!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
      }

      await userDao.setUserDto(UserDto.sep(1, null, 0, WardenType.USER, 0, 0));
      await userStoreDao.setUserStoreDto(UserStoreDto.sep(
          1, "new@email.com", 3287989, "New", "Email", 0, 0, 0));
      await localUserTools.setCurrentUserId(smd, localTransaction, 1);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        print(StackTrace.current);
    }
  }
}
