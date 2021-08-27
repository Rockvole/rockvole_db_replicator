import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class LocalReadServerRemoteUserWarden extends AbstractWarden {
  LocalReadServerRemoteUserWarden() :
    super(localWardenType: WardenType.READ_SERVER,
        remoteWardenType: WardenType.USER);

  @override
  Future<RemoteDto?> write() {
    throw IllegalStateException(
        "Write Server cannot write to Read Server.");
  }

  @override
  Future<RemoteDto?> processInsert() async {
    return await null;
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    return await null;
  }

  @override
  Future<RemoteDto?> processDelete() async {
    return await null;
  }
}
