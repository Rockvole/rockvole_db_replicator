import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class LocalWriteServerRemoteReadServerWarden extends AbstractWarden {
  LocalWriteServerRemoteReadServerWarden() :
    super(localWardenType: WardenType.WRITE_SERVER,
        remoteWardenType: WardenType.READ_SERVER);

  @override
  Future<RemoteDto> write() {
    throw IllegalStateException(
        "Write Server cannot get data from Read Server.");
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
