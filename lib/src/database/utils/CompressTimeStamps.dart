import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class CompressTimeStamps {
  static Future<void> main(List<String> args) async {
    SchemaMetaData smd = SchemaMetaData(false);
    SchemaMetaData smdSys = TransactionTools.createTrSchemaMetaData(smd);
    DbTransaction dbTransaction = await DataBaseHelper.getDbTransaction(null);

    await compressTimeStamps(smdSys, dbTransaction);

    await dbTransaction.endTransaction();
  }

  static Future<void> compressTimeStamps(
      SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineDto? waterLineDto = null;
    int? nextUsedTs = null;
    int newTs;

    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    try {
      do {
        try {
          newTs = await waterLineDao.getNextId(WardenType.WRITE_SERVER);
          nextUsedTs = await waterLineDao.getNextUsedTs(newTs);
          print("nextUsedTs=$nextUsedTs ||newTs=$newTs");
          if (nextUsedTs != null) {
            waterLineDto = await waterLineDao.getWaterLineDtoByTs(nextUsedTs);
            if (waterLineDto != null) {
              TableTransactionTrDao trDao =
                  TableTransactionTrDao(smdSys, transaction);
              await trDao.init(table_id: waterLineDto.water_table_id);
              await trDao.modifyField(nextUsedTs, newTs, 'ts');
              await waterLineDao.modifyField(nextUsedTs, newTs, 'ts');
            }
          }
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) {
            print(e);
          }
        }
      } while (nextUsedTs != null);
    } finally {
      await transaction.connection.close();
      await transaction.endTransaction();
      await transaction.closePool();
    }
  }
}
