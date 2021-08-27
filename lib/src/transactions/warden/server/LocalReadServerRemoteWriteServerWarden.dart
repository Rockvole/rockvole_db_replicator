import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class LocalReadServerRemoteWriteServerWarden extends AbstractWarden {
  LocalReadServerRemoteWriteServerWarden() :
    super(localWardenType: WardenType.READ_SERVER,
        remoteWardenType: WardenType.WRITE_SERVER);

  @override
  Future<void> init(SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    await super.init(smd, smdSys, transaction);
    defaultWaterState = WaterState.SERVER_APPROVED;
    validWaterStates = {WaterState.SERVER_APPROVED};
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
    return await super.writeOverWrite();
  }

  @override
  Future<RemoteDto?> processDelete() async {
    return await super.writeDelete(null);
  }
}
