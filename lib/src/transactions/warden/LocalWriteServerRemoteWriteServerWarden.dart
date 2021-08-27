import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class LocalWriteServerRemoteWriteServerWarden extends AbstractWarden {
  LocalWriteServerRemoteWriteServerWarden() :
    super(localWardenType: WardenType.WRITE_SERVER,
        remoteWardenType: WardenType.WRITE_SERVER);

  @override
  Future<void> init(SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    await super.init(smd, smdSys, transaction);
    defaultWaterState = WaterState.SERVER_APPROVED;
    validWaterStates = {WaterState.SERVER_APPROVED, WaterState.SERVER_PENDING, WaterState.SERVER_REJECTED};
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
    RemoteDto? remoteDto = null;
    switch (passedWaterState) {
      case WaterState.SERVER_APPROVED:
        if (tableTransactions.getTrDto().id == null) {
          remoteDto = await super.writeAdd();
        } else {
          remoteDto = await super.writeOverWrite();
        }
        try {
          await tableTransactions.updateWaterLineField();
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
        }
        break;
      case WaterState.SERVER_REJECTED:
        try {
          await tableTransactions.delete(null);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
            print("WS $e");
          } else rethrow;
        }
        remoteDto = await commitChanges(null);
        break;
      case WaterState.SERVER_PENDING:
        remoteDto = await super.writeOverWrite();
        break;
      default:
    }
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    RemoteDto? remoteDto = null;
    switch (passedWaterState) {
      case WaterState.SERVER_REJECTED:
        remoteDto = await commitChanges(null);
        break;
      default:
        remoteDto = await super.writeOverWrite();
    }
    return remoteDto;
  }

  @override
  Future<RemoteDto> processDelete() async {
    RemoteDto? remoteDto = null;
    switch (passedWaterState) {
      case WaterState.SERVER_REJECTED:
        remoteDto = await commitChanges(null);
        break;
      default:
        remoteDto = await super.writeDelete(null);
    }
    return remoteDto;
  }
}
