import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class WardenFactory {
  static AbstractWarden getAbstractWarden(
      WardenType localWardenType,
      WardenType remoteWardenType) {
    AbstractWarden abstractWarden;
    switch (localWardenType) {
      case WardenType.ADMIN:
        switch (remoteWardenType) {
          case WardenType.ADMIN:
            abstractWarden = LocalAdminRemoteAdminWarden();
            return abstractWarden;
          case WardenType.USER:
            throw IllegalStateException("Cannot send from User to Admin");
          case WardenType.WRITE_SERVER:
            abstractWarden = LocalAdminRemoteWriteServerWarden();
            return abstractWarden;
          case WardenType.READ_SERVER:
            throw IllegalStateException(
                "Cannot send from Read Server to Admin");
          case WardenType.NULL:
            throw IllegalStateException(
                "NULL is invalid type");
        }
      case WardenType.USER:
        switch (remoteWardenType) {
          case WardenType.ADMIN:
            throw IllegalStateException("Cannot send from Admin to User");
          case WardenType.USER:
            abstractWarden = LocalUserRemoteUserWarden();
            return abstractWarden;
          case WardenType.WRITE_SERVER:
            abstractWarden = LocalUserRemoteReadServerWarden();
            return abstractWarden;
          case WardenType.READ_SERVER:
            abstractWarden = LocalUserRemoteReadServerWarden();
            return abstractWarden;
          case WardenType.NULL:
            throw IllegalStateException(
                "NULL is invalid type");
        }
      case WardenType.WRITE_SERVER:
        switch (remoteWardenType) {
          case WardenType.ADMIN:
            abstractWarden = LocalWriteServerRemoteAdminWarden();
            return abstractWarden;
          case WardenType.USER:
            abstractWarden = LocalWriteServerRemoteUserWarden();
            return abstractWarden;
          case WardenType.WRITE_SERVER:
            abstractWarden = LocalWriteServerRemoteWriteServerWarden();
            return abstractWarden;
          case WardenType.READ_SERVER:
            abstractWarden = LocalWriteServerRemoteReadServerWarden();
            return abstractWarden;
          case WardenType.NULL:
            throw IllegalStateException(
                "NULL is invalid type");
        }
      case WardenType.READ_SERVER:
        switch (remoteWardenType) {
          case WardenType.ADMIN:
            throw IllegalStateException(
                "Cannot send from Admin to Read Server");
          case WardenType.USER:
            abstractWarden = LocalReadServerRemoteUserWarden();
            return abstractWarden;
          case WardenType.WRITE_SERVER:
            abstractWarden = LocalReadServerRemoteWriteServerWarden();
            return abstractWarden;
          case WardenType.READ_SERVER:
            throw IllegalStateException(
                "Cannot send from Read Server to Read Server");
          case WardenType.NULL:
            throw IllegalStateException(
                "NULL is invalid type");
        }
      case WardenType.NULL:
        throw IllegalStateException(
            "NULL is invalid type");
    }
  }
}
