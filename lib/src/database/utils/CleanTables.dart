import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class CleanTables {
  bool initialized = false;
  DbTransaction transaction;
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  late WaterLineDao waterLineDao;
  //TableTransactions tableTransactions;
  late TransactionsFactory transactionsFactory;

  CleanTables(this.smd, this.smdSys, this.transaction) {
    transactionsFactory = TransactionsFactory(WardenType.WRITE_SERVER, WardenType.WRITE_SERVER, smd, smdSys, transaction);
  }
  Future<void> init() async {
    initialized = true;
    waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
  }

  Future<void> deleteRow(WaterLineDto waterLineDto, bool deleteDto, bool deleteTrDto,
      bool deleteWaterLine) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    AbstractTableTransactions tableTransactions = await transactionsFactory.getTransactionsFromWaterLineTs(waterLineDto.water_ts!);
    if (deleteDto) {
      if (waterLineDto.water_error == WaterError.NONE) {
        try {
          await tableTransactions.delete(tableTransactions.trDto);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
              e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
            print("DB $e");
        }
      }
    }
    if (deleteTrDto) {
      try {
        await tableTransactions.deleteTrRowByTs(waterLineDto.water_ts!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
          print("DB $e");
      }
    }
    if (deleteWaterLine) {
      try {
        await waterLineDao.deleteWaterLineByTs(waterLineDto.water_ts!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          print("DB $e");
      }
    }
  }

  Future<void> deleteDuplicates() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    List<WaterLineDto>? list = null;
    Set<WaterError> errorSet = {WaterError.DUPLICATE_ENTRY};
    try {
      list = await waterLineDao.getWaterLineListAboveTs(
          0, null, null, errorSet, SortOrderType.PRIMARY_KEY_ASC, null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print("$e");
    }
    if(list!=null) {
      Iterator<WaterLineDto> iter = list.iterator;
      while (iter.moveNext()) {
        WaterLineDto waterLineDto = iter.current;
        await deleteRow(waterLineDto, true, true, true);
      }
    }
  }
}
