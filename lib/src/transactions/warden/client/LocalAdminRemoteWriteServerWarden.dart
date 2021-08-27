import 'package:rockvole_db/rockvole_transactions.dart';

class LocalAdminRemoteWriteServerWarden extends AbstractWarden {
  LocalAdminRemoteWriteServerWarden() :
    super(localWardenType: WardenType.ADMIN,
        remoteWardenType: WardenType.WRITE_SERVER);

  @override
  void initialize(AbstractTableTransactions tableTransactions,
      {WaterState? passedWaterState}) {
    super.initialize(tableTransactions, passedWaterState: passedWaterState);
    writeWaterLine =
        waterLine.getWriteUserWaterLine(tableTransactions.table_id);
    if (passedWaterState == WaterState.SERVER_PENDING) {
      writeWaterLine = true;
    }
  }

  @override
  Future<RemoteDto?> write() async {
    checkValidWaterStates();
    WaterLineDto waterLineDto = WaterLineDto.sep(
        0,
        passedWaterState,
        WaterError.NONE, tableTransactions.table_id, smdSys);
    setWaterLineDto(waterLineDto);
    return await super.write();
  }

  @override
  void setStates() {
    waterLine.setWaterState(passedWaterState);
  }

  @override
  Future<RemoteDto?> processInsert() async {
    return await super.writeOverWrite();
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    bool success = false;

    if (passedWaterState == WaterState.SERVER_PENDING) {
      success = true;
    } else {
      return await super.writeOverWrite();
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processDelete() async {
    bool success = false;

    if (passedWaterState == WaterState.SERVER_PENDING) {
      success = true;
    } else {
      return await super.writeDelete(null);
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }
}
