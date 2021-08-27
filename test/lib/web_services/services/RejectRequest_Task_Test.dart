import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import '../../../rockvole_test.dart';

class RejectRequest_Task_Test extends ApprovalRequest_Task_Test {

  RejectRequest_Task_Test(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults)
      : super(smd, smdSys, defaults);


  @override
  Future<void> test220_Approve_Task() async {
    await TestHelper_Request.rejectByAdmin(ApprovalRequest_Task_Test.localTaskTs, smd, smdSys, localTransaction);
  }

  @override
  Future<void> test300_Admin_Post_Approved_Task() async {
    print(AbstractRequestTest.preamble+"Admin Post Rejected "+ApprovalRequest_Task_Test.C_TABLE_FULL_NAME);

    await Admin_Post_AppRej_Task(WaterState.SERVER_REJECTED, false);
  }

}
