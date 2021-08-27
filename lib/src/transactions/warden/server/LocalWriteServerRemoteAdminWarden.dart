import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class LocalWriteServerRemoteAdminWarden extends AbstractWarden {
  LocalWriteServerRemoteAdminWarden()
      : super(
            localWardenType: WardenType.WRITE_SERVER,
            remoteWardenType: WardenType.ADMIN);

  @override
  Future<void> init(
      SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    await super.init(smd, smdSys, transaction);
    defaultWaterState = WaterState.CLIENT_STORED;
    validWaterStates = {
      WaterState.CLIENT_STORED,
      WaterState.CLIENT_REJECTED,
      WaterState.CLIENT_APPROVED
    };
  }

  @override
  Future<RemoteDto?> write() async {
    checkValidWaterStates();
    WaterLineDto waterLineDto = WaterLineDto.sep(
        0, passedWaterState, WaterError.NONE, tableTransactions.table_id, smd);
    setWaterLineDto(waterLineDto);
    return await super.write();
  }

  @override
  void setStates() {
    waterLine.setWaterState(WaterState.SERVER_APPROVED);
  }

  @override
  Future<RemoteDto?> processInsert() async {
    RemoteDto? remoteDto = null;
    bool doesCrcMatch = false;

    await _preProcessing();
    try {
      doesCrcMatch = super.doesCrcMatch(tableTransactions.getJoinCrcString());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
          e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT) rethrow;
    }

    if (!doesCrcMatch && passedWaterState != WaterState.CLIENT_REJECTED) {
      waterLine.setWaterError(WaterError.CRC_NOT_MATCH);
      tableTransactions.getTrDto().id=-1;
      remoteDto = await commitChanges(null);
    } else {
      switch (passedWaterState) {
        case WaterState.CLIENT_STORED: // This is a item entered by ADMIN
          remoteDto = await super.writeAdd();
          try {
            await tableTransactions.updateWaterLineField();
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
          }
          break;
        case WaterState.CLIENT_APPROVED: // Approved by ADMIN
          try {
            await tableTransactions.getChangesFromDto();
            await tableTransactions.updateWaterLineField();
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
          }
          waterLine.setWaterState(WaterState.SERVER_APPROVED);
          remoteDto = await commitChanges(null);
          break;
        case WaterState.CLIENT_REJECTED: // Rejected by ADMIN, so remove
          try {
            await tableTransactions.delete(null);
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
              print("WS $e");
            } else rethrow;
          }
          waterLine.setWaterState(WaterState.SERVER_REJECTED);
          remoteDto = await commitChanges(null);
          break;
        default:
      }
    }
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processUpdate() async {
    FieldData? originalDto;
    RemoteDto? remoteDto = null;
    bool entryFound = true;
    bool doesCrcMatch = false;

    await _preProcessing();
    try {
      originalDto = await tableTransactions.find();
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
      doesCrcMatch = super.doesCrcMatch(originalDto!.get("crc") as String);

      if (!doesCrcMatch && passedWaterState != WaterState.CLIENT_REJECTED) {
        waterLine.setWaterError(WaterError.CRC_NOT_MATCH);
        remoteDto = await commitChanges(null);
      } else {
        switch (passedWaterState) {
          case WaterState.CLIENT_STORED: // This is a item entered by ADMIN
            remoteDto = await super.writeUpdate(originalDto);
            try {
              await tableTransactions.updateWaterLineField();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND)
                rethrow;
            }
            break;
          case WaterState.CLIENT_APPROVED: // Approved by ADMIN
            remoteDto = await super.writeUpdate(originalDto);
            try {
              await tableTransactions.updateWaterLineField();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND)
                rethrow;
            }
            break;
          case WaterState.CLIENT_REJECTED: // Rejected by ADMIN
            waterLine.setWaterState(WaterState.SERVER_REJECTED);
            remoteDto = await commitChanges(null);
            break;
          default:
        }
      }
    }
    return remoteDto;
  }

  @override
  Future<RemoteDto?> processDelete() async {
    FieldData? originalDto = null;
    RemoteDto? remoteDto = null;
    bool entryFound = true;
    bool doesCrcMatch = false;

    await _preProcessing();
    try {
      originalDto = await tableTransactions.find();
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
      doesCrcMatch = super.doesCrcMatch(originalDto!.get("crc") as String);

      if (!doesCrcMatch && passedWaterState != WaterState.CLIENT_REJECTED) {
        waterLine.setWaterError(WaterError.CRC_NOT_MATCH);
        remoteDto = await commitChanges(null);
      } else {
        switch (passedWaterState) {
          case WaterState.CLIENT_STORED: // This is a item entered by ADMIN
            try {
              await tableTransactions.deleteChildren();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
                  e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT &&
                  e.sqlExceptionEnum != SqlExceptionEnum.FAILED_UPDATE &&
                  e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND)
                rethrow;
            }
            remoteDto = await super.writeDelete(originalDto);
            break;
          case WaterState.CLIENT_APPROVED: // Approved by ADMIN
            try {
              await tableTransactions.deleteChildren();
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
                  e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT &&
                  e.sqlExceptionEnum != SqlExceptionEnum.FAILED_UPDATE &&
                  e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND)
                rethrow;
            }
            remoteDto = await super.writeDelete(originalDto);
            break;
          case WaterState.CLIENT_REJECTED: // Rejected by ADMIN
            waterLine.setWaterState(WaterState.SERVER_REJECTED);
            remoteDto = await commitChanges(null);
            break;
          default:
        }
      }
    }
    return remoteDto;
  }

  Future<void> _preProcessing() async {
    // Remove original entries because we have a entry with up-to-date timestamp
    if (passedWaterState == WaterState.CLIENT_APPROVED ||
        passedWaterState == WaterState.CLIENT_REJECTED) {
      try {
        if (startTs != null && startTs! < waterLine.getMinTsForUser()) {
          await waterLine.deleteByTs(startTs!);
          await tableTransactions.deleteTrRowByTs(startTs!);
        }
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
          print("WS $e");
          waterLine.setWaterError(WaterError.DUPLICATE_APPROVAL);
        } else rethrow;
      }
    }
  }
}
