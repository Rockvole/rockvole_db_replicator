import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class LocalUserRemoteReadServerWarden extends AbstractWarden {
  LocalUserRemoteReadServerWarden()
      : super(
            localWardenType: WardenType.USER,
            remoteWardenType: WardenType.READ_SERVER);

  @override
  void initialize(AbstractTableTransactions tableTransactions,
      {WaterState? passedWaterState}) {
    super.initialize(tableTransactions, passedWaterState: passedWaterState);
    writeWaterLine =
        waterLine.getWriteUserWaterLine(tableTransactions.table_id);
  }

  @override
  Future<RemoteDto?> write() async {
    checkValidWaterStates();
    writeHistoricalChanges = false;
    WaterLineDto waterLineDto = WaterLineDto.sep(0, passedWaterState,
        WaterError.NONE, tableTransactions.table_id, smdSys);
    setWaterLineDto(waterLineDto);
    return await super.write();
  }

  @override
  void setStates() {
    waterLine.setWaterState(WaterState.SERVER_APPROVED);
  }

  @override
  Future<RemoteDto?> processInsert() async {
    return await super.writeOverWrite();
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    return await super.writeOverWrite();
  }

  @override
  Future<RemoteDto?> processDelete() async {
    return await super.writeDelete(null);
  }
}
