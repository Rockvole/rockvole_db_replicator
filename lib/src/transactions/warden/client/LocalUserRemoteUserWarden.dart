import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class LocalUserRemoteUserWarden extends AbstractWarden {
  LocalUserRemoteUserWarden({WardenType localWardenType = WardenType.USER,
      WardenType remoteWardenType = WardenType.USER}) :
    super(localWardenType: localWardenType, remoteWardenType: remoteWardenType);

  @override
  Future<RemoteDto?> write() async {
    checkValidWaterStates();
    WaterLineDto waterLineDto = WaterLineDto.sep(
        0,
        WaterState.CLIENT_STORED,
        WaterError.NONE, tableTransactions.table_id, smd);
    setWaterLineDto(waterLineDto);
    return await super.write();
  }

  @override
  Future<RemoteDto> processInsert() async {
    if (tableTransactions.getTrDto().id !=
        null) throw IllegalStateException("Id must be null.");
    tableTransactions.setCrc(tableTransactions.getJoinCrcString());
    return await super.writeAdd();
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    FieldData? originalDto = null;
    RemoteDto? remoteDto;
    bool entryFound = true;
    try {
      originalDto = await tableTransactions.find();
      String crc=DataTools.getCrcFromTable(tableTransactions.table_id, originalDto, smdSys);
      tableTransactions.setCrc(crc);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        entryFound = false;
        waterLine.setWaterError(WaterError.ID_NOT_FOUND);
        remoteDto = await commitChanges(null);
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        remoteDto = await commitChanges(null);
      } else rethrow;
    }
    if (entryFound) {
      remoteDto = await super.writeUpdate(originalDto);
    }
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processDelete() async {
    FieldData? originalDto=null;
    late RemoteDto remoteDto;
    bool entryFound = true;
    try {
      originalDto = await tableTransactions.find();
      String crc=DataTools.getCrcFromTable(tableTransactions.table_id, originalDto, smdSys);
      tableTransactions.setCrc(crc);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        entryFound = false;
        waterLine.setWaterError(WaterError.ID_NOT_FOUND);
        remoteDto = await commitChanges(null);
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        remoteDto = await commitChanges(null);
      } else rethrow;
    }
    if (entryFound) {
      remoteDto = await super.writeDelete(originalDto);
    }
    return remoteDto;
  }
}
