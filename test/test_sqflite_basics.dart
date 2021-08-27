import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_sqflite.dart';
import 'package:sqflite/sqflite.dart';

import 'lib/test_db_basics.dart';

Future<void> main() async {
  var databasesPath = await getDatabasesPath() + "/task_data.db";
  AbstractDatabase db = SqfliteDatabase.filename(fileName: databasesPath);

  await test_db_basics(db);

}
