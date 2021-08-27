import 'package:rockvole_db_replicator/rockvole_db.dart';

class GenericDao extends AbstractDao {
  GenericDao(SchemaMetaData smd, DbTransaction transaction) : super.sep(smd, transaction);
}
