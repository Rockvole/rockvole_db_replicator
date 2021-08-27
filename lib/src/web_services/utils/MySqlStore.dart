import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class MySqlStore {
  static late Map<String, RestStore> _storeMap;

  MySqlStore() {
    _storeMap = Map<String, RestStore>();
  }

  RestStore getStore(String? database) {
    if (database == null) database = DataBaseHelper.C_DEFAULT_DATABASE;
    if (!_storeMap.containsKey(database)) {
      _storeMap[database] = RestStore(MySqlPool(schemaName: database));
    }
    return _storeMap[database]!;
  }

  AbstractPool getMySqlPool(String? database) {
    if (database == null) database = DataBaseHelper.C_DEFAULT_DATABASE;
    RestStore store = getStore(database);
    /*
    AbstractPool dbPool = store.pool;
    if (dbPool == null) {
      try {
        dbPool = MySqlPool(schemaName: database);
        store.pool = dbPool;
      } on SqlException catch (e) {
        print("WS $e");
      }
    }
     */
    return store.pool;
  }

  UserTools getUserTools(String? database) {
    RestStore store = getStore(database);
    /*
    UserTools restTools = store.userTools;
    if (restTools == null) {
      restTools = UserTools();
      store.userTools = restTools;
    }
     */
    return store.userTools;
  }
}

class RestStore {
  late AbstractPool pool;
  late UserTools userTools;
  RestStore(this.pool) {
    userTools = UserTools();
  }
}
