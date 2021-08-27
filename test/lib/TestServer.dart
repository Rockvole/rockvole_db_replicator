import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:rockvole_db_replicator/src/web_services/services/MainServer.dart';
import '../rockvole_test.dart';

void main() {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = SchemaMetaDataTools.createSchemaMetaData(smd);

  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  start(smd);
}