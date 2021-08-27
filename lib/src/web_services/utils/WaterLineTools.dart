import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class WaterLineTools {
  WardenFilter? wardenFilter;
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  ConfigurationNameDefaults defaults;
  WaterLineTools(this.smd, this.smdSys, this.defaults) {
    wardenFilter = WardenFilter();
  }

  /**
   * Processes a list of WaterLineDto entries
   * Uses the water_line table timestamp and table_type to find the entry
   * in the corresponding table and returns a JSONArray of those various
   * table entries
   *
   * @param waterLineList - a list of water_line table entries
   * @param noMoreEntries
   * @param remoteWardenType - Type of Warden on the remote device
   * @return
   */
  Future<List<RemoteDto>> processWaterLineList(
      List<WaterLineDto>? waterLineList,
      WaterLineDao waterLineDao,
      bool noMoreEntries,
      WardenType? localWardenType,
      UserDto remoteUserDto,
      DbTransaction transaction) async {
    List<RemoteDto> remoteDtoList = [];
    RemoteDto? remoteDto;
    if (noMoreEntries) {
      remoteDtoList
          .add(RemoteStatusDto.sep(smdSys, status: RemoteStatus.LAST_ENTRY_REACHED));
      print("No entries found=$remoteDtoList");
    } else {
      WaterError? waterError;

      for (WaterLineDto waterLineDto in waterLineList!) {
        TableTransactionTrDao trDao = TableTransactionTrDao(smdSys, transaction);
        await trDao.init(table_id:waterLineDto.water_table_id, initTable: true);
        waterError = null;

        print("WaterLineDto=$waterLineDto");

        try {
          remoteDto = await processWaterLine(
              waterLineDto, trDao, transaction, localWardenType, remoteUserDto);
          if (remoteDto != null) {
            remoteDtoList.add(remoteDto);
          }
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
            waterError = WaterError.INVALID_ENTRY;
          else if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
            waterError = WaterError.ENTRY_NOT_FOUND;
          else if (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND)
            waterError = WaterError.INVALID_TABLE;
          else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
            waterError = WaterError.PARTITION_NOT_FOUND;
        }
        if (waterError != null) {
          try {
            await waterLineDao.setStates(waterLineDto.water_ts!, null, waterError);
          } on SqlException catch (e) {
            if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
                e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE)
              print("WS $e");
          }
        }
      }
    } // No More Entries
    return remoteDtoList;
  }

  Future<RemoteDto> processWaterLine(
      WaterLineDto waterLineDto,
      AbstractTransactionTrDao trDao,
      DbTransaction transaction,
      WardenType? localWardenType,
      UserDto remoteUserDto) async {
    RawRowData rawRowData;
    switch (waterLineDto.water_table_id) {
      case UserMixin.C_TABLE_ID:
        UserTrDao userTrDao = UserTrDao(smdSys, transaction);
        await userTrDao.init();
        FieldData fieldData=UserTrDto.getSelectFieldData();
        rawRowData = await userTrDao.getRawRowDataByTs(waterLineDto.water_ts!, fieldData: fieldData);
        if (Warden.isClient(remoteUserDto.warden) && (rawRowData.get('id',null) as int)!=remoteUserDto.id) {
          rawRowData.set("pass_key", null);
        }
        break;
      case AuthenticationDto.C_TABLE_ID:
      case EntryReceivedDto.C_TABLE_ID:
      case RemoteStatusDto.C_TABLE_ID:
      case WaterLineDto.C_TABLE_ID:
      case WaterLineFieldDto.C_TABLE_ID:
      case TransactionTools.C_LAST_FIELD_RECEIVED_TABLE_ID:
      case TransactionTools.C_MAX_INT_TABLE_ID:
        throw UnsupportedError("Error invalid table '" +
            waterLineDto.water_table_name +
            "'");
      default:
        TableTransactionTrDao trDao=TableTransactionTrDao(smdSys, transaction);
        await trDao.init(table_id:waterLineDto.water_table_id);
        rawRowData = await trDao.getRawRowDataByTs(waterLineDto.water_ts!);
    }
    RemoteDto remoteDto = RemoteDto.sep(TrDto.field(rawRowData.getFieldData()), smd,
        waterLineDto: waterLineDto, water_table_id: waterLineDto.water_table_id);
    return remoteDto;
  }
}
