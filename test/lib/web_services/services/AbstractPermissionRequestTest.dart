import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:test/test.dart';

import '../../../rockvole_test.dart';

abstract class AbstractPermissionRequestTest extends AbstractRequestTest {
  static late AbstractWarden userWarden;
  static late AbstractWarden userReadWarden;
  static late AbstractWarden adminWarden;
  static late int localTs;
  static late int remoteTs;

  static final int C_USER_ID = 2;
  static final int C_ADMIN_ID = 4;
  static final WaterState C_STATE_TYPE = WaterState.SERVER_PENDING;

  AbstractPermissionRequestTest(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);

  Future<DbTransaction> test001_SetUp(WardenType localWT, WardenType remoteWT,
      {String? localDatabaseName,
      String? remoteDatabaseName,
      int? rowLimit}) async {
    localTransaction = await super.test001_SetUp(localWT, remoteWT,
        localDatabaseName: localDatabaseName,
        remoteDatabaseName: remoteDatabaseName);

    // Now clone from android_in
    remoteTransaction =
        await DataBaseHelper.getDbTransaction(AbstractRequestTest.C_REMOTE_DB);
    userWarden =
        WardenFactory.getAbstractWarden(WardenType.USER, WardenType.USER);
    userReadWarden = WardenFactory.getAbstractWarden(
        WardenType.USER, WardenType.READ_SERVER);
    adminWarden = WardenFactory.getAbstractWarden(
        WardenType.ADMIN, WardenType.ADMIN);
    return localTransaction;
  }

  @override
  Future<void> test010_InsertCurrentUser() async {
    await super.test010_InsertCurrentUser();

    UserDto userDto = UserDto.sep(2, "g5sn8", 0, WardenType.USER, 0, 23932);
    UserStoreDto userStoreDto = UserStoreDto.sep(
        2, "jason@druce.com", 362789, "Jason", "Druce", 0, 0, 0);
    await TestHelper_Check.setupWriteServer(
        userDto, userStoreDto, smd, remoteTransaction);
    await TestHelper_Check.setCurrentUserDetails(
        userDto, userStoreDto, localUserTools, smd, localTransaction);
  }

  Future<void> test012_InsertCurrentAdmin() async {}

  @override
  Future<void> test015_UpdateConfiguration(
      WardenType localWT, WardenType remoteWT,
      {DbTransaction? transaction}) async {
    await super.test015_UpdateConfiguration(localWT, WardenType.NULL,
        transaction: transaction);
  }

  Future<void> test029_UserViewsTaskItem() async {
    print(AbstractRequestTest.preamble + "User Views Task Item");
  }

  Future<void> test047_User_Create_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Create Task Item");
  }

  Future<void> test048_Like_Task() async {
    print(AbstractRequestTest.preamble + "Insert Like Task");
  }

  Future<void> test049_User_Create_Task() async {
    print(AbstractRequestTest.preamble + "User Create Task");
  }

  Future<void> test058_Post_Fields() async {
    print(AbstractRequestTest.preamble + "Post Fields");
  }

  Future<void> test059_User_Post_Task() async {
    print(AbstractRequestTest.preamble + "User Post Task");
  }

  Future<void> test068_Insert_LikeCount() async {
    print(AbstractRequestTest.preamble + "Insert Like count");
  }

  Future<void> test067_User_Post_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Post TaskItem");
  }

  Future<void> test069_User_Create_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Create TaskItem");
  }

  Future<void> test070_User_Create_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Create TaskItem");
  }

  Future<void> test078_SimulateRemoteLikes() async {
    print(AbstractRequestTest.preamble + "Simulate Remote Likes");
  }

  Future<void> test079_User_Post_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Post TaskItem");
  }

  Future<void> test088_Admin_Get_Fields() async {
    print(AbstractRequestTest.preamble + "Admin Get Fields");
  }

  Future<void> test090_User_Post_Duplicate_TaskItem() async {
    print(AbstractRequestTest.preamble + "User Post Duplicate TaskItem");
  }

  Future<void> test097_Admin1() async {
    print(AbstractRequestTest.preamble + "Start Admin 1");
  }

  Future<void> test107_UpdateConfiguration_Admin1() async {
    print(AbstractRequestTest.preamble + "Update Configuration Admin 1");
  }

  Future<void> test110_InsertCurrentAdmin(
      {UserDto? userDto, UserStoreDto? userStoreDto}) async {
    print(AbstractRequestTest.preamble + "Insert Current Admin");

    if (userDto == null) {
      userDto = UserDto.sep(4, "D34ws0", 0, WardenType.ADMIN, 0, 34636456);
    }
    if (userStoreDto == null) {
      userStoreDto = UserStoreDto.sep(
          4, "charlton@heston.com", 3267345, "Charlton", "Heston", 0, 0, 0);
    }
    await TestHelper_Check.setupWriteServer(
        userDto, userStoreDto, smd, remoteTransaction);
    await TestHelper_Check.setCurrentUserDetails(
        userDto, userStoreDto, localUserTools, smd, localTransaction);
    await configureRestUtils();
  }

  Future<void> test115_Insert_Current_Admin1() async {
    print(AbstractRequestTest.preamble + "Insert Current Admin1");
  }

  Future<void> test117_Get_Pending_Admin1() async {}

  Future<void> test118_RemoveLocalUserEntries() async {
    print(AbstractRequestTest.preamble + "Remove Local User Entries");
  }

  Future<void> test197_Admin2() async {
    print(AbstractRequestTest.preamble + "Start Admin 2");
  }

  Future<void> test200_Get_Pending_Admin() async {
    print(AbstractRequestTest.preamble + "Get Pending Admin");
    await super.requestPendingAdmin("task");
  }

  Future<void> test207_UpdateConfiguration_Admin2() async {}

  Future<void> test210_Wait() async {
    print(AbstractRequestTest.preamble + "Wait");
    await TestHelper_Check.waitASec();
  }

  Future<void> test215_InsertCurrentAdmin2() async {
    print(AbstractRequestTest.preamble + "Insert Current Admin 2");
  }

  Future<void> test217_Get_Pending_Admin2() async {}

  Future<void> test220_Approve_Task() async {
    print(AbstractRequestTest.preamble + "Approve Task");
  }

  Future<void> test297_Wait() async {}

  Future<void> test300_Admin_Post_Approved_Task() async {
    print(AbstractRequestTest.preamble + "Admin Post Approved Task");
  }

  Future<void> test310_Approve_TaskItem() async {
    print(AbstractRequestTest.preamble + "Approve Task Item");
  }

  Future<void> test317_Approve_Admin2() async {}

  Future<void> test320_Admin_Post_Approved_TaskItem() async {
    print(AbstractRequestTest.preamble + "Admin Post Approved TaskItem");
  }

  Future<void> test325_RequestEmptyTaskItem() async {
    print(AbstractRequestTest.preamble + "Request Empty Task Item");
  }

  Future<void> test330_Post_Approval_Admin2() async {
    print(AbstractRequestTest.preamble + "Post Approval Admin2");
  }

  Future<void> test350_Request_Rows() async {
    print(AbstractRequestTest.preamble + "Request Rows");
  }

  Future<void> test400_Wait_Admin1() async {
    print(AbstractRequestTest.preamble + "Wait Admin 1");
  }

  Future<void> test420_Approve_Admin1() async {
    print(AbstractRequestTest.preamble + "Approve Admin 1");
  }

  Future<void> test430_Post_Approval_Admin1() async {
    print(AbstractRequestTest.preamble + "Post Approval Admin 1");
  }

  Future<void> requestUpdatedWaterLineFields(
      ChangeSuperType changeSuperType, int? remoteTs) async {
    List<RemoteDto> remoteDtoList;
    try {
      remoteDtoList = await restGetLatestWaterLineFieldsUtils
          .requestUpdatedWaterLineFieldsFromServer(changeSuperType,
              remoteTs: remoteTs,
              serverDatabase: AbstractRequestTest.C_REMOTE_DB,
              testPassword: AbstractRequestTest.C_TEST_PASSWORD);
      print("RFDTO.list=$remoteDtoList");
      await restGetLatestWaterLineFieldsUtils
          .storeWaterLineFieldsList(remoteDtoList);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.toString());
    } on TransmitStatusException catch (e) {
      fail(e.toString());
    } on RemoteStatusException catch (e) {
      fail(e.toString());
    }
  }

  Future<List<RemoteDto>> requestUpdatedRows() async {
    WaterLineField waterLineField = WaterLineField(
        localWardenType, remoteWardenType, smdSys, localTransaction);
    await waterLineField.init();
    List<RemoteDto> remoteDtoList = await restRequestSelectedRowsUtils
        .getRemoteFieldDtoListToSend(waterLineField);
    print("remoteDtoList=$remoteDtoList");

    try {
      await restRequestSelectedRowsUtils.requestUpdatedRowsFromServer(
          remoteDtoList, AbstractRequestTest.C_VERSION,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.toString());
    } on TransmitStatusException catch (e) {
      fail(e.toString());
    } on IllegalStateException catch (e) {
      fail(e.toString());
    }
    return remoteDtoList;
  }

  Future<void> postWaterLineFields() async {
    List<RemoteDto> remoteDtoList =
        await restPostWaterLineFieldsUtils.getRemoteFieldDtoListToSend();
    print("remoteDtoList=$remoteDtoList");
    try {
      await restPostWaterLineFieldsUtils.sendRemoteFieldDtoListToServer(
          remoteDtoList,
          serverDatabase: AbstractRequestTest.C_REMOTE_DB,
          testPassword: AbstractRequestTest.C_TEST_PASSWORD);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        fail(e.toString());
    } on TransmitStatusException catch (e) {
      fail(e.toString());
    } on IllegalStateException catch (e) {
      fail(e.toString());
    }
  }
}
