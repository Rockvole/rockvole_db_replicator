import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class TransactionsFactory {
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  DbTransaction transaction;
  SchemaMetaData? smd;
  SchemaMetaData smdSys;

  TransactionsFactory(this.localWardenType, this.remoteWardenType, this.smd,
      this.smdSys, this.transaction);

  Future<AbstractTableTransactions> getTransactionsFromRemoteDto(
      RemoteDto remoteDto) async {
    AbstractTableTransactions abstractTransactions;
    if (remoteDto.waterLineDto!.water_table_id ==
        WaterLineFieldDto.C_TABLE_ID) {
      abstractTransactions =
          WaterLineFieldTransactions.sep(remoteDto as RemoteWaterLineFieldDto);
    } else {
      abstractTransactions = TableTransactions.sep(remoteDto.trDto);
    }
    await abstractTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    return abstractTransactions;
  }

  Future<AbstractTableTransactions> getTransactionsFromWaterLineTs(
      int waterLineTs) async {
    AbstractTableTransactions abstractTransactions;
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    WaterLineDto waterLineDto =
        await waterLineDao.getWaterLineDtoByTs(waterLineTs);
    TableTransactionTrDao trDao = TableTransactionTrDao(smdSys, transaction);
    await trDao.init(table_id: waterLineDto.water_table_id);
    RawRowData rawRowData =
        await trDao.getRawRowDataByTs(waterLineDto.water_ts!);
    FieldData fieldData =
        FieldData.rawRowData(rawRowData, waterLineDto.water_table_id);

    abstractTransactions = TableTransactions.field(fieldData);

    await abstractTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    return abstractTransactions;
  }

  Future<AbstractTableTransactions> getTransactionsFromWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto) async {
    FieldMetaData? fmd =
        smdSys.getFieldByTableFieldId(waterLineFieldDto.table_field_id!);

    TableTransactionDao dao = TableTransactionDao(smd!, transaction);
    await dao.init(table_id: fmd!.table_id);
    RawRowData rawRowData = await dao.getById(waterLineFieldDto.id!);
    FieldData fieldData = FieldData.rawRowData(rawRowData, fmd.table_id);
    AbstractTableTransactions abstractTransactions =
        TableTransactions.field(fieldData);
    await abstractTransactions.init(
        localWardenType, remoteWardenType, smd, smdSys, transaction);
    return abstractTransactions;
  }

  @override
  String toString() {
    return "TransactionsFactory{" +
        "localWardenType=$localWardenType" +
        ", remoteWardenType=$remoteWardenType" +
        ", transaction=$transaction" +
        '}';
  }
}
