import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/src/transactions/warden/Warden.dart';
import 'package:test/test.dart';

import '../rockvole_test.dart';

Future<void> test_ws_permissions(AbstractPermissionRequestTest art, List<int> specialTests) async {

  group(art.runtimeType.toString(), () {
    if(specialTests.contains(0)) {
      late DbTransaction transaction;
      test("setup", () async {
        transaction = await art.test001_SetUp(WardenType.USER, WardenType.USER);
      });
      test("clone client", () async {
        await art.test005_CloneFromCsv(transaction);
      });
      test("clone server", () async {
        await art.test007_CloneFromCsvToRemote(transaction);
      });
      test("insert current user", () async {
        await art.test010_InsertCurrentUser();
      });
    }
    if(specialTests.contains(12)) {
      test("insert current admin", () async {
        await art.test012_InsertCurrentAdmin();
      });
    }
    if(specialTests.contains(0)) {
      test("update configuration", () async {
        await art.test015_UpdateConfiguration(WardenType.NULL, WardenType.NULL);
      });
    }
    if(specialTests.contains(29)) {
      test("user views task item", () async {
        await art.test029_UserViewsTaskItem();
      });
    }
    if(specialTests.contains(47)) {
      test("user create task item", () async {
        await art.test047_User_Create_TaskItem();
      });
    }
    if(specialTests.contains(48)) {
      test("insert like task", () async {
        await art.test048_Like_Task();
      });
    }
    if(specialTests.contains(49)) {
      test("user create task", () async {
        await art.test049_User_Create_Task();
      });
    }
    if(specialTests.contains(58)) {
      test("post fields", () async {
        await art.test058_Post_Fields();
      });
    }
    if(specialTests.contains(59)) {
      test("user post task", () async {
        await art.test059_User_Post_Task();
      });
    }
    if(specialTests.contains(67)) {
      test("user post task item", () async {
        await art.test067_User_Post_TaskItem();
      });
    }
    if(specialTests.contains(68)) {
      test("insert like count", () async {
        await art.test068_Insert_LikeCount();
      });
    }
    if(specialTests.contains(69)) {
      test("user create task item", () async {
        await art.test069_User_Create_TaskItem();
      });
    }
    if(specialTests.contains(70)) {
      test("user create task item", () async {
        await art.test070_User_Create_TaskItem();
      });
    }
    if(specialTests.contains(78)) {
      test("simulate remote likes", () async {
        await art.test078_SimulateRemoteLikes();
      });
    }
    if(specialTests.contains(79)) {
      test("user post task item", () async {
        await art.test079_User_Post_TaskItem();
      });
    }
    if(specialTests.contains(88)) {
      test("admin get fields", () async {
        await art.test088_Admin_Get_Fields();
      });
    }
    if(specialTests.contains(90)) {
      test("user post duplicate task item", () async {
        await art.test090_User_Post_Duplicate_TaskItem();
      });
    }
    if(specialTests.contains(97)) {
      test("start admin 1", () async {
        await art.test097_Admin1();
      });
    }
    if(specialTests.contains(107)) {
      test("update configuration admin 1", () async {
        await art.test107_UpdateConfiguration_Admin1();
      });
    }
    if(specialTests.contains(110)) {
      test("insert current admin", () async {
        await art.test110_InsertCurrentAdmin();
      });
    }
    if(specialTests.contains(115)) {
      test("insert current admin1", () async {
        await art.test115_Insert_Current_Admin1();
      });
    }

    if(specialTests.contains(117)) {
      test("get pending admin", () async {
        await art.test117_Get_Pending_Admin1();
      });
    }
    if(specialTests.contains(118)) {
      test("remove local user entries", () async {
        await art.test118_RemoveLocalUserEntries();
      });
    }
    if(specialTests.contains(197)) {
      test("start admin 2", () async {
        await art.test197_Admin2();
      });
    }
    if(specialTests.contains(200)) {
      test("get pending admin", () async {
        await art.test200_Get_Pending_Admin();
      });
    }
    if(specialTests.contains(207)) {
      test("update configuration admin 2", () async {
        await art.test207_UpdateConfiguration_Admin2();
      });
    }
    if(specialTests.contains(210)) {
      test("wait", () async {
        await art.test210_Wait();
      });
    }
    if(specialTests.contains(215)) {
      test("insert current admin 2", () async {
        await art.test215_InsertCurrentAdmin2();
      });
    }
    if(specialTests.contains(217)) {
      test("get pending admin 2", () async {
        await art.test217_Get_Pending_Admin2();
      });
    }
    if(specialTests.contains(220)) {
      test("approve task", () async {
        await art.test220_Approve_Task();
      });
    }
    if(specialTests.contains(297)) {
      test("wait", () async {
        await art.test297_Wait();
      });
    }
    if(specialTests.contains(300)) {
      test("admin post approved task", () async {
        await art.test300_Admin_Post_Approved_Task();
      });
    }
    if(specialTests.contains(310)) {
      test("approve task item", () async {
        await art.test310_Approve_TaskItem();
      });
    }
    if(specialTests.contains(317)) {
      test("approve admin 2", () async {
        await art.test317_Approve_Admin2();
      });
    }
    if(specialTests.contains(320)) {
      test("admin post approved task item", () async {
        await art.test320_Admin_Post_Approved_TaskItem();
      });
    }
    if(specialTests.contains(325)) {
      test("request empty task item", () async {
        await art.test325_RequestEmptyTaskItem();
      });
    }
    if(specialTests.contains(330)) {
      test("post approval admin 2", () async {
        await art.test330_Post_Approval_Admin2();
      });
    }
    if(specialTests.contains(350)) {
      test("request rows", () async {
        await art.test350_Request_Rows();
      });
    }
    if(specialTests.contains(400)) {
      test("wait admin 1", () async {
        await art.test400_Wait_Admin1();
      });
    }
    if(specialTests.contains(420)) {
      test("approve admin 1", () async {
        await art.test420_Approve_Admin1();
      });
    }
    if(specialTests.contains(430)) {
      test("post approval admin 1", () async {
        await art.test430_Post_Approval_Admin1();
      });
    }
    test("Finish", () async {
      await art.test999_Finish();
    });
  });
}
