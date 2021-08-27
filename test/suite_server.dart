import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'lib/test_ws_permissions.dart';
import 'lib/test_ws_server.dart';
import 'rockvole_test.dart';

Future<void> main() async {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = SchemaMetaDataTools.createSchemaMetaData(smd);

  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  SchemaMetaData smdSys = TransactionTools.createTrSchemaMetaData(smd);
  ConfigurationNameDefaults defaults = ConfigurationNameDefaults();
  List<int> specialTests;
  const C_TEST=1;

  // ------------------------------------- GET
  if(C_TEST==0||C_TEST==1) {
    specialTests=[0, 60, 70, 120, 130, 140, 150];
    LocalServerRemoteServerRequestListTest lsrsrlt = LocalServerRemoteServerRequestListTest(smd, smdSys, defaults);
    await test_ws_server(lsrsrlt, specialTests);
  }

  if(C_TEST==0||C_TEST==2) {
    specialTests=[0, 60, 70, 120, 130, 140];
    LocalServerRemoteServerRequestTest lsrsrt = LocalServerRemoteServerRequestTest(smd, smdSys, defaults);
    await test_ws_server(lsrsrt, specialTests);
  }

  if(C_TEST==0||C_TEST==3) {
    specialTests=[0, 60, 70, 120, 130, 140, 170];
    LocalUserRemoteServerRequestListTest lursrlt = LocalUserRemoteServerRequestListTest(
        smd, smdSys, defaults);
    await test_ws_server(lursrlt, specialTests);
  }

  if(C_TEST==0||C_TEST==4) {
    specialTests=[0, 60, 70, 120, 130, 140];
    LocalUserRemoteServerRequestTest lursrt = LocalUserRemoteServerRequestTest(smd, smdSys, defaults);
    await test_ws_server(lursrt, specialTests);
  }

  // ------------------------------------- POST
  if(C_TEST==0||C_TEST==5) {
    specialTests=[0, 140];
    LocalAdminRemoteServerListTest larslt = LocalAdminRemoteServerListTest(
        smd, smdSys, defaults);
    await test_ws_server(larslt, specialTests);
  }

  if(C_TEST==0||C_TEST==6) {
    specialTests=[0, 140, 160];
    LocalUserRemoteServerListTest lurslt = LocalUserRemoteServerListTest(
        smd, smdSys, defaults);
    await test_ws_server(lurslt, specialTests);
  }
  // ------------------------------------- ANDROID
  if(C_TEST==0||C_TEST==7) {
    specialTests=[0, 17, 20, 30, 40, 50, 55, 65, 80, 90, 100, 110, 125, 135];
    AndroidAuthenticationTest aat = AndroidAuthenticationTest(smd, smdSys, defaults);
    await test_ws_server(aat, specialTests);
  }
  if(C_TEST==0||C_TEST==8) {
    specialTests=[0, 25, 35];
    AndroidSendUserChangeTest asuct = AndroidSendUserChangeTest(smd, smdSys, defaults);
    await test_ws_server(asuct, specialTests);
  }
  // ------------------------------------- PERMISSION
  if(C_TEST==0||C_TEST==9) {
    specialTests=[0, 12, 48, 58, 68, 78, 88];
    WlfLike_TaskTest wltt = WlfLike_TaskTest(smd, smdSys, defaults);
    await test_ws_permissions(wltt, specialTests);
  }
  if(C_TEST==0||C_TEST==10) {
    specialTests=[0, 49, 59, 69,79, 110, 118, 200, 210, 220, 300, 310, 320, 325, 350];
    ApprovalRequest_Task_Test artt = ApprovalRequest_Task_Test(smd, smdSys, defaults);
    await test_ws_permissions(artt, specialTests);
  }
  if(C_TEST==0||C_TEST==11) {
    specialTests=[0, 49, 59, 69, 79, 110, 118, 200, 220, 300, 310, 320, 325, 350];
    RejectRequest_Task_Test rrtt = RejectRequest_Task_Test(smd, smdSys, defaults);
    await test_ws_permissions(rrtt, specialTests);
  }
  if(C_TEST==0||C_TEST==12) {
    specialTests=[0, 70, 79, 90];
    PostTaskItemTest ptit = PostTaskItemTest(smd, smdSys, defaults);
    await test_ws_permissions(ptit, specialTests);
  }
  if(C_TEST==0||C_TEST==13) {
    specialTests=[0, 47, 67, 97, 107, 115, 117, 197, 207, 215, 217, 297, 317, 330, 400, 420, 430];
    DoubleApproval_TaskItemTest datit = DoubleApproval_TaskItemTest(smd, smdSys, defaults);
    await test_ws_permissions(datit, specialTests);
  }
  if(C_TEST==0||C_TEST==14) {
    specialTests=[0, 29];
    BaseWlfChangesTest bwct = BaseWlfChangesTest(smd, smdSys, defaults);
    await test_ws_permissions(bwct, specialTests);
  }
}
