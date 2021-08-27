import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class RemoteDtoDbHelper {
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  DbTransaction transaction;
  late TransactionsFactory transactionsFactory;
  AbstractWarden abstractWarden;
  late AbstractTableTransactions tableTransactions;

  RemoteDtoDbHelper(WardenType localWardenType, WardenType remoteWardenType,
      this.smd, this.smdSys, this.transaction, this.abstractWarden) {
    transactionsFactory = TransactionsFactory(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    this.abstractWarden = abstractWarden;
  }

  Future<void> storeRemoteDto(RemoteDto remoteDto) async {
    try {
      tableTransactions =
          await transactionsFactory.getTransactionsFromRemoteDto(remoteDto);
      await abstractWarden.init(smd, smdSys, transaction);
      abstractWarden.initialize(tableTransactions,
          passedWaterState: remoteDto.waterLineDto!.water_state);
      await abstractWarden.write();
    } on SqlException catch (e) {
      print("WS $e");
    }
  }

  void storeRemoteDtoList(List<RemoteDto> remoteDtoList) {
    RemoteDto remoteDto;

    for (int f = 0; f < remoteDtoList.length; f++) {
      remoteDto = remoteDtoList[f];
      storeRemoteDto(remoteDto);
    }
  }
}
