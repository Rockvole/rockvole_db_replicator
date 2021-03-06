import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class LocalAdminRemoteServerListTest extends AbstractRequestTest {
  static final bool C_FRESH_DATABASE = true;
  static final WaterState C_STATE_TYPE = WaterState.CLIENT_SENT;
  static late int receivedTs;
  static final int C_ID = 1;
  static final int C_PRODUCT_ID = 1;
  late AbstractWarden localWarden;

  LocalAdminRemoteServerListTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
  Future<DbTransaction> test001_SetUp(WardenType localWT, WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    localTransaction = await super.test001_SetUp(
        WardenType.ADMIN, WardenType.ADMIN,
        localDatabaseName: "client_db", remoteDatabaseName: "server_db");

    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    await remoteTransaction.getConnection().connect();
    return remoteTransaction;
  }

  @override
  Future<void> test005_CloneFromCsv(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test005_CloneFromCsv(localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test007_CloneFromCsvToRemote(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    await super.test007_CloneFromCsvToRemote(remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet, trTableTypeEnumSet: null);
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();

    UserDto userDto =
        UserDto.sep(4, "D34ws0", 0, WardenType.ADMIN, 0, 34636456);
    UserStoreDto userStoreDto = UserStoreDto.sep(
        4, "charlton@heston.com", 3265478, "Charlton", "Heston", 0, 0, 0);
    await TestHelper_Check.setupWriteServer(
        userDto, userStoreDto, smd, remoteTransaction);
    await TestHelper_Check.setCurrentUserDetails(
        userDto, userStoreDto, localUserTools, smd, localTransaction);
  }

  @override
  Future<void> test015_UpdateConfiguration(
      WardenType localWT, WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(localWardenType, WardenType.NULL,
        transaction: localTransaction);

    localWarden =
        WardenFactory.getAbstractWarden(localWardenType, remoteWardenType);
    /*
    // This is initialised in AbstractRequestTest.configureRestUtils()
    // Called from test015_UpdateConfiguration()
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
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) fail("$e");
    }
     */
    receivedTs = WaterLineDto.min_id_for_user - 1;
  }

  @override
  Future<void> test140_UserStore() async {
    await super.test140_UserStore();

    TrDto trDto = TrDto.sep(839284, OperationType.INSERT, 33, null,
        "Insert User Store", 0, UserStoreMixin.C_TABLE_ID);
    UserStoreTrDto? userStoreTrDto = UserStoreTrDto.sep(
        null, "user@store.com", 436782341, "User", "Store", 0, 0, 0, trDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(userStoreTrDto);
    await tableTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, localTransaction);
    await localWarden.init(smd, smdSys, localTransaction);
    localWarden.initialize(tableTransactions);
    try {
      await localWarden.write();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) fail("$e");
    }
    try {
      await super.postNewRows(localTransaction);
    } on TransmitStatusException {
      print(StackTrace.current);
    }
    // ---------------------------------------------Now Unit test
    // Test Local DB
    receivedTs += 1;
    WaterLineDto? waterLineDto = await TestHelper_Fetch.fetchWaterLineDtoByTs(
        receivedTs, smdSys, localTransaction);
    TestWaterLineDataStruct localWlStruct = TestWaterLineDataStruct(
        water_ts: receivedTs,
        water_table_id: UserStoreMixin.C_TABLE_ID,
        water_state: C_STATE_TYPE,
        water_error: WaterError.NONE,
        tsSpace: IdentSpace.USER_SPACE);
    TestHelper_Check.checkWaterLineDto(waterLineDto, localWlStruct);

    userStoreTrDto = await TestHelper_Fetch.fetchUserStoreTr(
        receivedTs, smdSys, localTransaction);
    TestTrDataStruct localTrStruct = TestTrDataStruct(
        ts: 2000000000,
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.USER_SPACE,
        ensureExists: true,
        min_id_for_user: UserStoreMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(userStoreTrDto, localTrStruct);
    expect(userStoreTrDto!.name, "User");
    expect(userStoreTrDto.ts, greaterThanOrEqualTo(2000000000));
    expect(userStoreTrDto.id, 3);

    // Test Remote DB
    UserStoreDto? userStoreDto = await TestHelper_Fetch.fetchUserStore(
        "user@store.com", smd, remoteTransaction);
    TestUserStoreDataStruct remoteUsStruct =
        TestUserStoreDataStruct(id: 3, name: "User", surname: "Store");
    TestHelper_Check.checkUserStore(
        userStoreDto!, remoteUsStruct, IdentSpace.SERVER_SPACE, true);
    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            UserStoreMixin.C_TABLE_ID,
            null,
            null,
            true,
            smdSys,
            remoteTransaction);
    userStoreTrDto = await TestHelper_Fetch.fetchUserStoreTr(
        remoteWaterLineDto!.water_ts!, smdSys, remoteTransaction);
    TestTrDataStruct remoteTrStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true,
        min_id_for_user: UserStoreMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(userStoreTrDto, remoteTrStruct);
    expect(userStoreTrDto!.name, "User");
    expect(userStoreTrDto.ts, lessThan(2000000000));
    expect(userStoreTrDto.id, 3);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
