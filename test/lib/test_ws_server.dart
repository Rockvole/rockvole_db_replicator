import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/src/transactions/warden/Warden.dart';
import 'package:test/test.dart';

import '../rockvole_test.dart';

Future<void> test_ws_server(AbstractRequestTest art, List<int> specialTests) async {

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
      test("update configuration", () async {
        await art.test015_UpdateConfiguration(WardenType.NULL, WardenType.NULL);
      });
    }
    if(specialTests.contains(17)) {
      test("insert unbalanced user", () async {
        await art.test017_InsertUnbalancedUser();
      });
    }
    if(specialTests.contains(20)) {
      test("get new user", () async {
        await art.test020_GetNewUser();
      });
    }
    if(specialTests.contains(25)) {
      test("update user surname", () async {
        await art.test025_UpdateUserSurname();
      });
    }
    if(specialTests.contains(30)) {
      test("get missing user id", () async {
        await art.test030_GetMissingUserId();
      });
    }
    if(specialTests.contains(35)) {
      test("post user change", () async {
        await art.test035_PostUserChange();
      });
    }
    if(specialTests.contains(40)) {
      test("user wrong passkey", () async {
        await art.test040_UserWrongPasskey();
      });
    }
    if(specialTests.contains(50)) {
      test("insert user", () async {
        await art.test050_InsertUser();
      });
    }
    if(specialTests.contains(55)) {
      test("authenticate upgrade user", () async {
        await art.test055_Authenticate_UpgradeUser();
      });
    }
    if(specialTests.contains(60)) {
      test("configuration", () async {
        await art.test060_Configuration();
      });
    }
    if(specialTests.contains(65)) {
      test("authenticate pending", () async {
        await art.test065_Authenticate_Pending();
      });
    }
    if(specialTests.contains(70)) {
      test("task item", () async {
        await art.test070_TaskItem();
      });
    }
    if(specialTests.contains(80)) {
      test("authenticate with remote passkey no local", () async {
        await art.test080_Authenticate_WithRemotePassKeyNoLocal();
      });
    }
    if(specialTests.contains(90)) {
      test("authenticate no remote passkey no local", () async {
        await art.test090_Authenticate_NoRemotePassKeyNoLocal();
      });
    }
    if(specialTests.contains(100)) {
      test("authenticate no remote passkey with local", () async {
        await art.test100_Authenticate_NoRemotePassKeyWithLocal();
      });
    }
    if(specialTests.contains(110)) {
      test("authenticate with all passkeys", () async {
        await art.test110_Authenticate_WithAllPassKeys();
      });
    }
    if(specialTests.contains(120)) {
      test("task", () async {
        await art.test120_Task();
      });
    }
    if(specialTests.contains(125)) {
      test("insert user", () async {
        await art.test125_InsertUser();
      });
    }
    if(specialTests.contains(130)) {
      test("User", () async {
        await art.test130_User();
      });
    }
    if(specialTests.contains(135)) {
      test("authenticate crc not match", () async {
        await art.test135_Authenticate_CrcNotMatch();
      });
    }
    if(specialTests.contains(140)) {
      test("User Store", () async {
        await art.test140_UserStore();
      });
    }
    if(specialTests.contains(150)) {
      test("WaterLineField Empty", () async {
        await art.test150_Check_WaterLineFieldEmpty();
      });
    }
    if(specialTests.contains(160)) {
      test("User Store Other", () async {
        await art.test160_UserStore_Other();
      });
    }
    if(specialTests.contains(170)) {
      test("GetLatest WaterLine", () async {
        await art.test170_GetLatestWaterLine();
      });
    }
    test("Finish", () async {
      await art.test999_Finish();
    });
  });
}
