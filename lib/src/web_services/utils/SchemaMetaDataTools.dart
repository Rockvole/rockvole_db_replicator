import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class SchemaMetaDataTools {

  static SchemaMetaData createSchemaMetaData(SchemaMetaData smd) {
    smd = ConfigurationDto.addSchemaMetaData(smd);
    smd = UserDto.addSchemaMetaData(smd);
    smd = UserStoreDto.addSchemaMetaData(smd);
    return smd;
  }

}