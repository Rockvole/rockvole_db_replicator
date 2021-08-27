import 'package:rockvole_db_replicator/rockvole_db.dart';

class DbTransaction {
  late AbstractPool pool;
  late AbstractDatabase connection;
  bool poolOpen=false;
  AbstractSqlStrings? tools;

  DbTransaction(AbstractPool pool) {
    this.pool = pool;
    //connection = null;
    tools = null;
  }
  Future<void> beginTransaction() async {
    connection = await pool.getConnection();
    poolOpen=true;
    tools = pool.tools;
  }

  Future<void> endTransaction() async {
    if (pool != null) {
      await (await pool.getConnection()).close();
      tools = null;
    }
  }

  Future<void> closePool() async {
    if (poolOpen) {
      pool.closePool();
      poolOpen=false;
    }
    return await null;
  }

  AbstractDatabase getConnection() {
    return connection;
  }

  AbstractSqlStrings? getTools() {
    return tools;
  }

  AbstractPool? getPool() {
    return pool;
  }

  @override
  String toString() {
    return "DbTransaction [pool=$pool" +
        ", connection=$connection" +
        ", tools=$tools" +
        "]";
  }
}
