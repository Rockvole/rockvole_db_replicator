import 'package:rockvole_db/rockvole_db.dart';

class GenericTrDao extends AbstractDao {
  GenericTrDao(SchemaMetaData smdSys, DbTransaction transaction) : super.sep(smdSys, transaction);

  Future<bool> init({int? table_id, bool initTable = true}) async {
    if (table_id == null) throw ArgumentError("table_id must not be null");

    return await super.init(table_id: table_id, initTable: initTable);
  }
}

