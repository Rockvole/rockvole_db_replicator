import 'package:rockvole_db/rockvole_transactions.dart';

class LocalAdminRemoteAdminWarden extends LocalUserRemoteUserWarden {
  LocalAdminRemoteAdminWarden()
      : super(
            localWardenType: WardenType.ADMIN,
            remoteWardenType: WardenType.ADMIN);
}
