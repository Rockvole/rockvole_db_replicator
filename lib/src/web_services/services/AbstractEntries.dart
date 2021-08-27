import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

abstract class AbstractEntries {
  static final int C_MINIMUM_VERSION = 1;
  static final String C_TEST_PASSWORD = "q1dX4i";
  late MySqlStore poolStore;
  late UserTools userTools;
  UserDto? localUserDto;
  late UserDto remoteUserDto;
  UserStoreDto? remoteUserStoreDto;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late bool testMode;
  late DbTransaction transaction;
  bool transactionBegun=false;
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;

  AbstractEntries(this.smd) {
    poolStore = MySqlStore();
    smdSys = TransactionTools.createTrSchemaMetaData(smd);
    transactionBegun=false;
  }

  Future<void> init() async {}

  Future<void> validateRequest(String? testPassword, String? database) async {
    testMode = false;
    if (testPassword != null) {
      if (testPassword == C_TEST_PASSWORD) {
        testMode = true;
      } else {
        throw RemoteStatusException(RemoteStatus.INVALID_TEST_MODE);
      }
    }
    if (!testMode) {
      database = null;
    }
    AbstractPool dbPool = poolStore.getMySqlPool(database);
    userTools = poolStore.getUserTools(database);
    transaction = DbTransaction(dbPool);
    try {
      await transaction.beginTransaction();
      transactionBegun=true;
    } catch (e) {
      print("WS $e");
    }
  }

  Future<void> validateServer() async {
    try {
      localUserDto = await userTools.getCurrentUserDto(smd, transaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        throw RemoteStatusException(RemoteStatus.SERVER_NOT_DEFINED);
    }
  }

  Future<void> validateUser(int userId) async {
    try {
      remoteUserDto = await userTools.getUserDto(smd, transaction, userId);
      print("Request from user:$remoteUserDto");
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        throw RemoteStatusException(RemoteStatus.USER_NOT_FOUND);
      else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        throw RemoteStatusException(RemoteStatus.DATABASE_ACCESS_ERROR);
    }
    try {
      remoteUserStoreDto =
          await userTools.getUserStoreDto(smd, transaction, userId);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        throw RemoteStatusException(RemoteStatus.USER_NOT_FOUND);
    }
  }

  bool isEmailFresh(int? userId) {
    if (userId == null) {
      throw RemoteStatusException(RemoteStatus.USER_ID_MANDATORY);
    }
    if (userId == 1) return true;
    return false;
  }

  Future<void> endTransaction() async {
    if(transactionBegun) await transaction.getConnection().close();
  }
}
