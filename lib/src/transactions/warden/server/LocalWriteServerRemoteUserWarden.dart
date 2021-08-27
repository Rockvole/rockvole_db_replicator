import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class LocalWriteServerRemoteUserWarden extends AbstractWarden {
  LocalWriteServerRemoteUserWarden()
      : super(
            localWardenType: WardenType.WRITE_SERVER,
            remoteWardenType: WardenType.USER);

  @override
  Future<void> init(
      SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    await super.init(smd, smdSys, transaction);
    defaultWaterState = WaterState.SERVER_PENDING;
    validWaterStates = {WaterState.SERVER_PENDING, WaterState.CLIENT_STORED};
  }

  @override
  Future<RemoteDto?> write() async {
    checkValidWaterStates();
    WaterLineDto waterLineDto = WaterLineDto.sep(
        0,
        WaterState.SERVER_PENDING,
        WaterError.NONE, tableTransactions.table_id, smd);
    setWaterLineDto(waterLineDto);
    return await super.write();
  }

  @override
  void setStates() {
    waterLine.setWaterState(WaterState.SERVER_PENDING);
  }

  @override
  Future<RemoteDto?> processInsert() async {
    return await super.writeAdd();
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    setStates();
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processDelete() async {
    setStates();
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }
}
