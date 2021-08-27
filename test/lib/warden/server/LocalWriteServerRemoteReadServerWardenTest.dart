import 'package:test/test.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import '../AbstractWardenTest.dart';
import '../../../rockvole_test.dart';

class LocalWriteServerRemoteReadServerWardenTest extends AbstractWardenTest {
  static TestTrDataStruct insertTrStruct = TestTrDataStruct(
      ts: 1,
      operation: OperationType.INSERT,
      user_id: 74,
      user_ts: 2828,
      comment: "ServerWarden User insert into Task",
      crc: null,
      idSpace: IdentSpace.USER_SPACE,
      tsSpace: IdentSpace.USER_SPACE,
      ensureExists: true);
  TestTaskDataStruct insertTaskStruct = TestTaskDataStruct(
      id: 11,
      task_description: "Pay Bills",
      task_complete: false,
      idSpace: insertTrStruct.idSpace,
      ensureExists: true);

  LocalWriteServerRemoteReadServerWardenTest(
      DbTransaction clientDb, DbTransaction serverDb)
      : super(clientDb, serverDb);

  Future<void> run_test() async {
    await super.run_all_tests(WardenType.WRITE_SERVER, WardenType.READ_SERVER);
  }

  Future<void> insert_server() async {
    bool found = true;
    TaskTrDto taskTrDto = TaskTrDto.sep(
        null,
        insertTaskStruct.task_description,
        insertTaskStruct.task_complete,
        insertTrStruct.getTrDto(TaskMixin.C_TABLE_ID));
    AbstractWarden abstractWarden =
        await initializeAbstractWarden(taskTrDto, WaterState.CLIENT_STORED);
    try {
      await abstractWarden.write();
    } on IllegalStateException {
      found = false;
    }
    if (found) fail(AbstractWardenTest.C_ENTRY_MUST_BE_ILLEGAL_STATE);
  }

  Future<void> update_server() async {
    // NOT NEEDED
    return null;
  }

  Future<void> delete_server() async {
    // NOT NEEDED
    return null;
  }
}
