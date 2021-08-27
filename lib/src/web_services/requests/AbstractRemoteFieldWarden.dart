import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

/**
 * Methods to deal with RemoteWaterLineFieldDto<br>
 * This is a water_line_field entry bundled for transfer
 * <p>
 * Server side - retrieve a list of the latest water_line_field entries to send to the user
 * <br>
 * Client side - update the water_line_field table and the values in the corresponding tables.
 */
class AbstractRemoteFieldWarden {
  late WaterLineField waterLineField;
  late TransactionsFactory transactionsFactory;
  //late AbstractPool pool;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late AbstractTableTransactions tableTransactions;
  late WaterLineFieldDto waterLineFieldDto;
  RemoteDto? remoteDto;
  DbTransaction transaction;
  SchemaMetaData smd;
  SchemaMetaData smdSys;

  AbstractRemoteFieldWarden(this.localWardenType, this.remoteWardenType,
      this.smd, this.smdSys, this.transaction) {
    waterLineField =
        WaterLineField(localWardenType, remoteWardenType, smdSys, transaction);
    transactionsFactory = TransactionsFactory(
        localWardenType, remoteWardenType, smd, smdSys, transaction);

    //this.pool = pool;
  }

  Future<void> init() async {
    await waterLineField.init();
  }

  Future<void> setRemoteDto(RemoteDto remoteDto) async {
    this.remoteDto = remoteDto;
    waterLineFieldDto =
        (remoteDto as RemoteWaterLineFieldDto).waterLineFieldDto;
    waterLineField.setWaterLineFieldDto(waterLineFieldDto);
  }

  /**
   * Update the client device with the values returned from the server
   * <p>
   * Values are replaced directly (not incremented/decremented)
   *
   */
  Future<void> updateClient() async {
    if (remoteDto == null)
      throw NullPointerException(
          "Must call initialize() before updateClient()");

    tableTransactions = await transactionsFactory
        .getTransactionsFromWaterLineFieldDto(waterLineFieldDto);
    ChangeType changeType = waterLineFieldDto.change_type_enum!;
    if (waterLineFieldDto.table_id != TransactionTools.C_MAX_INT_TABLE_ID) {
      int value = waterLineFieldDto.value_number!;
      switch (changeType) {
        case ChangeType.LIKE:
          tableTransactions.setChangeTypeValue(changeType, value);
          await waterLineField.updateNotifyState(NotifyState.CLIENT_STORED);
          break;
        case ChangeType.NOTIFY:
          await waterLineField
              .updateNotifyState(NotifyState.CLIENT_OUT_OF_DATE);
          break;
        case ChangeType.DECREMENT:
        case ChangeType.DISLIKE:
        case ChangeType.INCREMENT:
        case ChangeType.USER_SETTING:
      }
    }
  }

  void updateMaxTs() {
    if (remoteDto == null)
      throw NullPointerException(
          "Must call initialize() before updateClient()");

    waterLineField.updateMaxTs(
        waterLineFieldDto.change_type_enum!, null, waterLineFieldDto.remote_ts);
  }

/**
 * Returns the list of water_line_field entries which are above the timestamp provided by the user.
 *
 * @param localTs Timestamp in the water_line_field table which the list will be above
 * @param changeSuperType VOTING / NUMERALS / CHANGES
 * @param limit Maximum number of records returned
 * @return
 * @throws EntryNotFoundException
 * @throws FailedSelectException
 */
  Future<List<RemoteDto>> getRemoteFieldListAboveLocalTs(
      int? localTs, ChangeSuperType changeSuperType, int limit) async {
    WaterLineFieldDto waterLineFieldDto;
    List<RemoteDto> remoteDtoList = [];
    bool noMoreEntries = false;
    try {
      List<WaterLineFieldDto> waterLineFieldDtoList = await waterLineField
          .getWaterLineFieldListAboveTs(localTs, changeSuperType, true, limit);
      Iterator<WaterLineFieldDto> iter = waterLineFieldDtoList.iterator;
      while (iter.moveNext()) {
        waterLineFieldDto = iter.current;
        if (waterLineFieldDto.table_id != WaterLineFieldDto.C_TABLE_ID) {
          tableTransactions = await transactionsFactory
              .getTransactionsFromWaterLineFieldDto(waterLineFieldDto);
          waterLineFieldDto.value_number = await tableTransactions
              .getChangeTypeValue(waterLineFieldDto.change_type_enum!);
          waterLineFieldDto.remote_ts = waterLineFieldDto.local_ts;
          waterLineFieldDto.local_ts = null;
          remoteDtoList.add(RemoteWaterLineFieldDto(waterLineFieldDto, smdSys));
        }
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        noMoreEntries = true;
      else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        print("WS $e");
    }
    if (remoteDtoList == null || remoteDtoList.length == 0 || noMoreEntries) {
      remoteDtoList.add(
          RemoteStatusDto.sep(smdSys, status: RemoteStatus.LAST_ENTRY_REACHED));
    }
    return remoteDtoList;
  }

  RemoteDto? getRemoteDto() {
    return remoteDto;
  }
}
