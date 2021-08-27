import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'lib/warden/client/LocalAdminRemoteAdminWardenTest.dart';
import 'lib/warden/client/LocalAdminRemoteUserWardenTest.dart';
import 'lib/warden/client/LocalAdminRemoteWriteServerWardenTest.dart';
import 'lib/warden/client/LocalUserRemoteReadServerWardenTest.dart';
import 'lib/warden/client/LocalUserRemoteUserWardenTest.dart';

import 'lib/warden/server/LocalReadServerRemoteUserWardenTest.dart';
import 'lib/warden/server/LocalReadServerRemoteWriteServerWardenTest.dart';
import 'lib/warden/server/LocalWriteServerRemoteAdminWardenTest.dart';
import 'lib/warden/server/LocalWriteServerRemoteReadServerWardenTest.dart';
import 'lib/warden/server/LocalWriteServerRemoteUserWardenTest.dart';

import 'lib/warden/LocalWriteServerRemoteWriteServerWardenTest.dart';

Future<void> main() async {
  DbTransaction clientDb = await DataBaseHelper.getDbTransaction('client_db');

  DbTransaction serverDb = await DataBaseHelper.getDbTransaction('server_db');
  const C_TEST=0;

  // -------------------------------------------------- CLIENT
  if(C_TEST==0||C_TEST==1) {
    LocalAdminRemoteAdminWardenTest larawt = LocalAdminRemoteAdminWardenTest(clientDb, serverDb);
    await larawt.run_test();
  }
  if(C_TEST==0||C_TEST==2) {
    LocalAdminRemoteUserWardenTest laruwt = LocalAdminRemoteUserWardenTest(clientDb, serverDb);
    await laruwt.run_test();
  }
  if(C_TEST==0||C_TEST==3) {
    LocalAdminRemoteWriteServerWardenTest larwswt = LocalAdminRemoteWriteServerWardenTest(clientDb, serverDb);
    await larwswt.run_test();
  }
  if(C_TEST==0||C_TEST==4) {
    LocalUserRemoteReadServerWardenTest lurrswt = LocalUserRemoteReadServerWardenTest(
        clientDb, serverDb);
    await lurrswt.run_test();
  }
  if(C_TEST==0||C_TEST==5) {
    LocalUserRemoteUserWardenTest luruwt = LocalUserRemoteUserWardenTest(clientDb, serverDb);
    await luruwt.run_test();
  }
  // -------------------------------------------------- SERVER
  if(C_TEST==0||C_TEST==6) {
    LocalReadServerRemoteUserWardenTest lrsruwt = LocalReadServerRemoteUserWardenTest(clientDb, serverDb);
    await lrsruwt.run_test();
  }
  if(C_TEST==0||C_TEST==7) {
    LocalReadServerRemoteWriteServerWardenTest lrsrwswt = LocalReadServerRemoteWriteServerWardenTest(clientDb, serverDb);
    await lrsrwswt.run_test();
  }
  if(C_TEST==0||C_TEST==8) {
    LocalWriteServerRemoteAdminWardenTest lwsrawt = LocalWriteServerRemoteAdminWardenTest(clientDb, serverDb);
    await lwsrawt.run_test();
  }
  if(C_TEST==0||C_TEST==9) {
    LocalWriteServerRemoteReadServerWardenTest lwsrrswt = LocalWriteServerRemoteReadServerWardenTest(clientDb, serverDb);
    await lwsrrswt.run_test();
  }
  if(C_TEST==0||C_TEST==10) {
    LocalWriteServerRemoteUserWardenTest lwsruwt = LocalWriteServerRemoteUserWardenTest(clientDb, serverDb);
    await lwsruwt.run_test();
  }

  if(C_TEST==0||C_TEST==11) {
    LocalWriteServerRemoteWriteServerWardenTest lwsrwswt = LocalWriteServerRemoteWriteServerWardenTest(clientDb, serverDb);
    await lwsrwswt.run_test();
  }
}
