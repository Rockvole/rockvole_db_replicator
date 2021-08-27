import 'package:test/test.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import '../AbstractWardenTest.dart';
import '../../../rockvole_test.dart';

// Based on Brand_LocalReadServer_WardenTest
class LocalReadServerRemoteUserWardenTest extends AbstractWardenTest {
  static TestTrDataStruct insertTrStruct = TestTrDataStruct(
      ts: 1,
      operation: OperationType.INSERT,
      user_id: 74,
      user_ts: 2828,
      comment: "Inserted in Task",
      crc: null,
      idSpace: IdentSpace.SERVER_SPACE,
      tsSpace: IdentSpace.SERVER_SPACE,
      ensureExists: true);
  TestTaskDataStruct insertTaskStruct = TestTaskDataStruct(
      id: 11,
      task_description: "Pay Bills",
      task_complete: false,
      idSpace: insertTrStruct.idSpace,
      ensureExists: true);

  LocalReadServerRemoteUserWardenTest(
      DbTransaction clientDb, DbTransaction serverDb)
      : super(clientDb, serverDb);

  Future<void> run_test() async {
    await super.run_all_tests(WardenType.READ_SERVER, WardenType.USER);
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
      fail(AbstractWardenTest.C_ENTRY_SHOULD_NOT_EXIST);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        fail(e.cause!);
      }
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
