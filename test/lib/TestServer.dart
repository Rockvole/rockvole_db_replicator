import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_db/src/web_services/services/MainServer.dart';
import '../rockvole_test.dart';

void main() {
  SchemaMetaData smd = SchemaMetaData(false);
  smd = SchemaMetaDataTools.createSchemaMetaData(smd);

  smd = TaskDto.addSchemaMetaData(smd);
  smd = TaskItemDto.addSchemaMetaData(smd);

  start(smd);
}