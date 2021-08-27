import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

/**
 * Update the water_line_field (WLF) table and the values in the corresponding tables.
 * <p>
 * Update the WLF table timestamp and Increment/decrement the LIKE/DISLIKE count in the corresponding table<br/>
 * Update the NOTIFY in the WLF table only
 * <p>
 * Update the max water_line_field entry for its change_type
 *
 */
class AbstractFieldWarden {
  bool initialized = false;
  DbTransaction transaction;
  late WaterLineField waterLineField;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late AbstractTableTransactions tableTransactions;
  late WaterLineFieldDto waterLineFieldDto;
  late TransactionsFactory transactionsFactory;

  AbstractFieldWarden(this.localWardenType, this.remoteWardenType,
      SchemaMetaData? smd, SchemaMetaData smdSys, this.transaction) {
    waterLineField =
        WaterLineField(localWardenType, remoteWardenType, smdSys, transaction);
    transactionsFactory = TransactionsFactory(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
  }

  Future<void> init(WaterLineFieldDto waterLineFieldDto) async {
    initialized = true;
    await waterLineField.init();
    this.waterLineFieldDto = waterLineFieldDto;
  }

  void setNotifyState(ChangeSuperType superType) {
    waterLineFieldDto.notify_state = null;
    switch (superType) {
      case ChangeSuperType.VOTING:
        if (Warden.isClient(localWardenType) &&
            Warden.isClient(remoteWardenType)) {
          waterLineFieldDto.notify_state_enum = NotifyState.CLIENT_STORED;
        }
        break;
      case ChangeSuperType.NUMERALS:
        break;
      case ChangeSuperType.CHANGES:
        if (Warden.isClient(localWardenType) &&
            Warden.isServer(remoteWardenType)) {
          waterLineFieldDto.notify_state_enum = NotifyState.CLIENT_UP_TO_DATE;
        }
        break;
      default:
    }
  }

  Future<WaterLineFieldDto?> write() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (waterLineFieldDto.change_type_enum != ChangeType.NOTIFY)
      tableTransactions = await transactionsFactory
          .getTransactionsFromWaterLineFieldDto(waterLineFieldDto);

    WaterLineFieldDto? returnWaterLineFieldDto = null;
    switch (waterLineFieldDto.change_type_enum) {
      case ChangeType.LIKE:
        setNotifyState(ChangeSuperType.VOTING);
        returnWaterLineFieldDto = await processLike();
        break;
      case ChangeType.DISLIKE:
        setNotifyState(ChangeSuperType.VOTING);
        break;
      case ChangeType.INCREMENT:
        setNotifyState(ChangeSuperType.NUMERALS);
        break;
      case ChangeType.DECREMENT:
        setNotifyState(ChangeSuperType.NUMERALS);
        break;
      case ChangeType.NOTIFY:
        setNotifyState(ChangeSuperType.CHANGES);
        returnWaterLineFieldDto = await processNotify();
        break;
      default:
        break;
    }
    return returnWaterLineFieldDto;
  }

  Future<WaterLineFieldDto> processLike() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    tableTransactions.modifyChangeTypeValue(
        ChangeType.LIKE, waterLineFieldDto.value_number);
    return await updateWaterLineField();
  }

  Future<WaterLineFieldDto> processNotify() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return await updateWaterLineField();
  }

  Future<WaterLineFieldDto> updateWaterLineField() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineFieldDto returnWaterLineFieldDto;
    waterLineField.setWaterLineFieldDto(waterLineFieldDto);
    int? now = null;
    int? remoteTs = waterLineFieldDto.remote_ts;
    if (Warden.isServer(localWardenType)) {
      now = TimeUtils.getNowCustomTs();
      remoteTs = null;
    }
    returnWaterLineFieldDto = await waterLineField.updateTs(now, remoteTs);

    if (Warden.isServer(localWardenType) || Warden.isServer(remoteWardenType)) {
      await waterLineField.updateMaxTs(waterLineFieldDto.change_type_enum!, now, remoteTs);
    }
    // Blank out values not needed to validate return
    returnWaterLineFieldDto.notify_state = null;
    returnWaterLineFieldDto.value_number = null;
    returnWaterLineFieldDto.ui_type = null;
    returnWaterLineFieldDto.local_ts = null;
    returnWaterLineFieldDto.remote_ts = null;
    return returnWaterLineFieldDto;
  }
}
