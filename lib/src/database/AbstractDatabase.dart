import 'package:rockvole_db_replicator/rockvole_db.dart';

abstract class AbstractDatabase {
  DBType dbType;

  AbstractDatabase(this.dbType);

  Future<bool> connect();
  Future<RawTableData> query(String sql, FieldData fieldData);
  Future<int?> updateQuery(String sql);
  Future<int?> insertQuery(String sql, FieldData fieldData);
  Future<bool> close();
}