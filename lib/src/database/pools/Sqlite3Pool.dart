import 'package:rockvole_db/rockvole_db.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:rockvole_db/rockvole_sqlite3.dart';

class Sqlite3Pool extends AbstractPool {
  static final String C_EXT = ".db";

  Sqlite3Pool(String? dir, String dbn) {
    setUpPool(dir, dbn, 10);

    tools = MysqlStrings(getDBType());
  }

  void closeConnection({Database? conn}) {
    if (conn != null) conn.dispose();
  }

  String getPoolName(String? dir, String? dbn) {
    if (dir == null)
      directory = "database";
    else
      directory = dir;
    if (dbn == null)
      dataBaseName = C_DEFAULT_DBNAME + C_EXT;
    else
      dataBaseName = dbn + C_EXT;
    return getDBType().toString() + ":" + directory.toString() + "/" + dataBaseName.toString();
  }

  DBType getDBType() => DBType.Sqlite;

  Future<AbstractDatabase> getConnection() async {
    AbstractDatabase db = Sqlite3Database.filename(dataBaseName!);
    await db.connect();
    return db;
  }

  @override
  bool supportsPool() {
    return false;
  }
}
