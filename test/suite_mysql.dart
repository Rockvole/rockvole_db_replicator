import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'lib/test_db_basics.dart';
import 'lib/test_db_exceptions.dart';
import 'lib/test_db_transactions.dart';
import 'lib/test_db_warden.dart';

Future<void> main() async {
  DbTransaction db = await DataBaseHelper.getDbTransaction('sharecal');

  await test_db_basics(db);

  await test_db_exceptions(db);

  await test_db_transactions(db);

  await test_db_warden(db);
}
