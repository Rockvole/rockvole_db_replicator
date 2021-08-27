import 'package:rockvole_db/rockvole_db.dart';

class GenericDao extends AbstractDao {
  GenericDao(SchemaMetaData smd, DbTransaction transaction) : super.sep(smd, transaction);
}
