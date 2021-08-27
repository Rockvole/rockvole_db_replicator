import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:mysql1/mysql1.dart';
import 'package:rockvole_db_replicator/rockvole_mysql.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class MySqlPool extends AbstractPool {
  String hostName;
  int port;
  String userName;
  String password;
  String schemaName;

  MySqlPool(
      {this.hostName: 'localhost',
      this.port: 3306,
      this.userName = 'aversions',
      this.password = 'aversions',
      this.schemaName = DataBaseHelper.C_DEFAULT_DATABASE}) {
    setUpPool(null, schemaName, 30);

    tools = MysqlStrings(getDBType());
  }

  void closeConnection({MySqlConnection? conn}) {
    if (conn != null) conn.close();
  }

  @override
  String getPoolName(String? dir, String? dbn) {
    if (dir == null)
      directory = C_DEFAULT_DIR;
    else
      directory = dir;
    if (dbn == null)
      dataBaseName = DataBaseHelper.C_DEFAULT_DATABASE;
    else
      dataBaseName = dbn;
    return getDBType().toString() + ":" + dataBaseName.toString();
  }

  DBType getDBType() => DBType.Mysql;

  Future<AbstractDatabase> getConnection() async {
    AbstractDatabase db = MysqlDatabase.settings(
        hostName: hostName,
        port: port,
        userName: userName,
        password: password,
        schemaName: schemaName);
    await db.connect();
    return db;
  }

  @override
  bool supportsPool() {
    return false;
  }
}
