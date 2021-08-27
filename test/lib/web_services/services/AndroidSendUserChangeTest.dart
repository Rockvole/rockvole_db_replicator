import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

class AndroidSendUserChangeTest extends AbstractRequestTest {
  static late UserDto userDto;
  static late UserStoreDto userStoreDto;
  static int C_ID = 2;
  static late RestGetAuthenticationUtils restInformationUtils;
  late AbstractWarden localWarden;

  AndroidSendUserChangeTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  @override
  Future<DbTransaction> test001_SetUp(WardenType localWT, WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    localTransaction = await super.test001_SetUp(
        WardenType.USER, WardenType.USER,
        localDatabaseName: "client_db", remoteDatabaseName: "server_db");
    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    await remoteTransaction.getConnection().connect();
    return localTransaction;
  }

  @override
  Future<void> test005_CloneFromCsv(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) {
    return super.test005_CloneFromCsv(localTransaction,
        tableTypeEnumSet: minTableTypeEnumSet,
        trTableTypeEnumSet: minTrTableTypeEnumSet,
        dropPartitions: false);
  }

  @override
  Future<void> test007_CloneFromCsvToRemote(DbTransaction transaction,
      {Set<int>? tableTypeEnumSet,
      Set<int>? trTableTypeEnumSet,
      bool? dropPartitions}) async {
    minTableTypeEnumSet.add(UserMixin.C_TABLE_ID);
    await super.test007_CloneFromCsvToRemote(remoteTransaction,
        tableTypeEnumSet: minTableTypeEnumSet, trTableTypeEnumSet: null);
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();

    userDto = UserDto.sep(2, "g5sn8", 0, WardenType.USER, 0, 23932);
    userStoreDto = UserStoreDto.sep(
        2, "jason@druce.com", 352678, "Jason", "Druce", 120987, 103, 93);
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
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        fail(e.cause);
      }
    }
     */
  }

  Future<void> test025_UpdateUserSurname() async {
    await super.test025_UpdateUserSurname();
    userStoreDto.surname = "Juice";
    // The entries below should not be changed by user
    userStoreDto.records_downloaded = 100;
    userStoreDto.changes_approved_count = 23;
    userStoreDto.changes_denied_count = 22;
    TrDto trDto = TrDto.sep(null, OperationType.UPDATE, 73, 287692,
        "Update Country", 0, UserStoreMixin.C_TABLE_ID);
    UserStoreTrDto userStoreTrDto = UserStoreTrDto.wee(userStoreDto, trDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(userStoreTrDto);
    await tableTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, localTransaction);
    await localWarden.init(smd, smdSys, localTransaction);
    localWarden.initialize(tableTransactions);
    try {
      await localWarden.write();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
        fail(e.cause!);
    }
  }

  @override
  Future<void> test035_PostUserChange() async {
    await super.test035_PostUserChange();
    try {
      await super.postNewRows(localTransaction);
    } on TransmitStatusException catch (e) {
      fail(e.cause!);
    }
    UserDto? userDto =
        await TestHelper_Fetch.fetchUserById(C_ID, smd, remoteTransaction);
    TestUserDataStruct userStruct = TestUserDataStruct(
        pass_key: "g5sn8", subset: 0, warden: WardenType.USER);
    TestHelper_Check.checkUser(
        userDto!, userStruct, IdentSpace.SERVER_SPACE, true);
    UserStoreDto? userStoreDto = await TestHelper_Fetch.fetchUserStore(
        "jason@druce.com", smd, remoteTransaction);
    TestUserStoreDataStruct userStoreStruct = TestUserStoreDataStruct(
        id: C_ID,
        name: "Jason",
        surname: "Juice",
        records_downloaded: 120987,
        changes_approved_count: 103,
        changes_denied_count: 93);
    TestHelper_Check.checkUserStore(
        userStoreDto!, userStoreStruct, IdentSpace.SERVER_SPACE, true);

    WaterLineDto? remoteWaterLineDto =
        await TestHelper_Fetch.fetchWaterLineDtoByTableType(
            UserStoreMixin.C_TABLE_ID,
            null,
            null,
            true,
            smdSys,
            remoteTransaction);
    UserStoreTrDto? trDto = await TestHelper_Fetch.fetchUserStoreTr(
        remoteWaterLineDto!.water_ts!, smdSys, remoteTransaction);
    TestTrDataStruct trStruct = TestTrDataStruct(
        idSpace: IdentSpace.SERVER_SPACE,
        tsSpace: IdentSpace.SERVER_SPACE,
        ensureExists: true,
        min_id_for_user: UserStoreMixin.min_id_for_user);
    TestHelper_Check.checkTrDto(trDto, trStruct);
  }

  @override
  Future<void> test999_Finish() async {
    await super.test999_Finish();
  }
}
