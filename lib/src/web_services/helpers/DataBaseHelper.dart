import 'package:rockvole_db_replicator/rockvole_db.dart';

class DataBaseHelper {
  static const String C_DEFAULT_DATABASE = "default_db";
  // --------------------------------------------------------------------------------------- DATABASE
  static Future<DbTransaction> getDbTransaction(String? localDatabase) async {
    late AbstractPool pool;
    late DbTransaction transaction;
    if(localDatabase==null) localDatabase=C_DEFAULT_DATABASE;
    try {
      pool = MySqlPool(schemaName: localDatabase);
      transaction = DbTransaction(pool);
      await transaction.beginTransaction();
    } catch (e) {
      print("WS $e");
    }
    return transaction;
  }

  static Future<DbTransaction> getSqlite3DbTransaction(String localDatabase, String? location) async {
    late AbstractPool pool;
    late DbTransaction transaction;
    try {
      pool = Sqlite3Pool(location,localDatabase);
      transaction = DbTransaction(pool);
      await transaction.beginTransaction();
    } catch (e) {
      print("WS $e");
    }
    return transaction;
  }
}
