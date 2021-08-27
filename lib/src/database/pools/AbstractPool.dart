import 'package:rockvole_db/rockvole_db.dart';

abstract class AbstractPool {
  String? directory = null;
  String? dataBaseName = null;
  late AbstractSqlStrings tools;
  String C_DEFAULT_DBNAME = "test";
  String C_DEFAULT_DIR = "data";
  //AbstractDatabase connection;
  //DataSource dataSource;
  //ConnectionPoolDataSource poolDataSource;

  late int maxPoolSize;
  static Map<String, Object>? dbPool = null;
  late String poolName;

  AbstractPool();

  void setUpPool(String? dir, String dbn, int maxPoolSize) {
    this.maxPoolSize = maxPoolSize;
    if (dbPool == null) dbPool = Map();
    poolName = getPoolName(dir, dbn);
    if (dbPool!.containsKey(poolName)) {
      for (String name in dbPool!.keys) {
        print("set=" + name);
      }
      //throw SqlException(SqlExceptionEnum.SQL_SYNTAX_ERROR,
      //    cause: "Cannot create a pool with existing database " + poolName);
    } else {
      print("Adding pool " + poolName);
      if (supportsPool()) {
        throw ArgumentError("Pooling not supported in dartlang");
        //dbPool[poolName]= MiniConnectionPoolManager(getConnectionPoolDataSource(), maxPoolSize);
      } else
        dbPool![poolName] = Object();
    }
  }

  String getPoolName(String? dir, String? dbn) {
    if (dir == null)
      directory = C_DEFAULT_DIR;
    else
      directory = dir;
    if (dbn == null)
      dataBaseName = C_DEFAULT_DBNAME;
    else
      dataBaseName = dbn;
    return getDBType().toString() + ":" + directory.toString() + "/" + dataBaseName.toString();
  }

  int getMaximumPoolSize() {
    return maxPoolSize;
  }

  Future<AbstractDatabase> getConnection();

  DBType getDBType();
  bool supportsPool();

  void closePool() {
    if (supportsPool()) {
      try {
        throw ArgumentError("Pooling not supported in dartlang");
        //((MiniConnectionPoolManager)dbPool.get(poolName)).dispose();
      } on SqlException catch (e) {
        print("DB $e");
      }
    }
    print("Closing pool " + poolName);
    for (String name in dbPool!.keys) {
      print("set=" + name);
    }
    dbPool!.remove(poolName);
  }

  void closeConnection();

  @override
  String toString() {
    return "AbstractPool [directory=" +
        directory.toString() +
        ", dataBaseName=" +
        dataBaseName.toString() +
        ", tools=$tools" +
        ", maxPoolSize=$maxPoolSize" +
        ", poolName=$poolName" +
        ", poolManager=" +
        dbPool![poolName].toString() +
        "]";
  }
}
