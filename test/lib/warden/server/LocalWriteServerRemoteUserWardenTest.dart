import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import '../AbstractWardenTest.dart';
import '../../../rockvole_test.dart';

// Based on Brand_LocalWriteServer_WardenTest
class LocalWriteServerRemoteUserWardenTest extends AbstractWardenTest {
  // -------------------------------------------- INSERT
  static TestTrDataStruct insertTrStruct = TestTrDataStruct(
      ts: 1,
      operation: OperationType.INSERT,
      user_id: 74,
      user_ts: 2828,
      comment: "ServerWarden User insert into Task",
      crc: null,
      idSpace: IdentSpace.SERVER_SPACE,
      tsSpace: IdentSpace.SERVER_SPACE,
      ensureExists: true);
  TestWaterLineDataStruct insertWlStruct = TestWaterLineDataStruct(
      water_ts: insertTrStruct.ts,
      water_table_id: AbstractWardenTest.C_TASK_TABLE_ID,
      water_state: WaterState.SERVER_PENDING,
      water_error: WaterError.NONE,
      tsSpace: insertTrStruct.tsSpace);
  TestTaskDataStruct insertTaskStruct = TestTaskDataStruct(
      id: 11,
      task_description: "Pay Bills",
      task_complete: false,
      idSpace: insertTrStruct.idSpace,
      ensureExists: true);
  // -------------------------------------------- UPDATE
  static TestTrDataStruct updateTrStruct = TestTrDataStruct(
      ts: 2,
      operation: OperationType.UPDATE,
      user_id: 74,
      user_ts: 3098,
      comment: "User Updated Task",
      crc: null,
      idSpace: IdentSpace.SERVER_SPACE,
      tsSpace: IdentSpace.SERVER_SPACE,
      ensureExists: true);
  TestWaterLineDataStruct updateWlStruct = TestWaterLineDataStruct(
      water_ts: updateTrStruct.ts,
      water_table_id: AbstractWardenTest.C_TASK_TABLE_ID,
      water_state: WaterState.SERVER_PENDING,
      water_error: WaterError.NONE,
      tsSpace: updateTrStruct.tsSpace);
  // Check nothing is written over existing value
  TestTaskDataStruct updateTaskStruct = TestTaskDataStruct(
      id: 1,
      task_description: "Clean Car",
      task_complete: false,
      idSpace: updateTrStruct.idSpace,
      ensureExists: true);
  // -------------------------------------------- DELETE
  static TestTrDataStruct deleteTrStruct = TestTrDataStruct(
      ts: 3,
      operation: OperationType.DELETE,
      user_id: 74,
      user_ts: 4672,
      comment: "User deleted Task",
      crc: null,
      idSpace: IdentSpace.SERVER_SPACE,
      tsSpace: IdentSpace.SERVER_SPACE,
      ensureExists: true);
  TestWaterLineDataStruct deleteWlStruct = TestWaterLineDataStruct(
      water_ts: deleteTrStruct.ts,
      water_table_id: AbstractWardenTest.C_TASK_TABLE_ID,
      water_state: WaterState.SERVER_PENDING,
      water_error: WaterError.NONE,
      tsSpace: deleteTrStruct.tsSpace);
  TestTaskDataStruct deleteTaskStruct = TestTaskDataStruct(
      id: 2,
      task_description: "Gardening",
      task_complete: false,
      idSpace: deleteTrStruct.idSpace,
      ensureExists: true);

  LocalWriteServerRemoteUserWardenTest(
      DbTransaction clientDb, DbTransaction serverDb)
      : super(clientDb, serverDb);

  Future<void> run_test() async {
    await super.run_all_tests(WardenType.WRITE_SERVER, WardenType.USER);
  }

  Future<void> insert_server() async {
    await runServerTest(null, WaterState.CLIENT_STORED, insertTaskStruct,
        insertTrStruct, insertWlStruct, null, null);
  }

  Future<void> update_server() async {
    await runServerTest(updateTaskStruct.id, WaterState.SERVER_PENDING,
        updateTaskStruct, updateTrStruct, updateWlStruct, null, null);
  }

  Future<void> delete_server() async {
    await runServerTest(deleteTaskStruct.id, WaterState.SERVER_PENDING,
        deleteTaskStruct, deleteTrStruct, deleteWlStruct, null, null);
  }
}
