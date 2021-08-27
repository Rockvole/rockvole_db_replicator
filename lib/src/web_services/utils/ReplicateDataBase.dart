import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class ReplicateDataBase {
  static final int C_MAX_ROWS_PER_READ = 10;
  WardenType localWardenType;
  WardenType remoteWardenType;
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  DbTransaction importTransaction;
  DbTransaction exportTransaction;
  bool initializeTables;
  late UserTools userTools;
  late RemoteDtoDbHelper remoteDtoDbHelper;
  late WaterLineDao importWaterLineDao;
  late WaterLineDao exportWaterLineDao;
  late ServerWarden serverWarden;
  late RemoteDtoFactory remoteDtoFactory;
  late TransactionsFactory transactionsFactory;
  late bool minimalSet;
  Set<int>? minimalEnumSet;

  ReplicateDataBase(
      this.localWardenType,
      this.remoteWardenType,
      this.smd,
      this.smdSys,
      this.importTransaction,
      this.exportTransaction,
      this.initializeTables) {
    userTools = UserTools();
    AbstractWarden abstractWarden = WardenFactory.getAbstractWarden(
        localWardenType, remoteWardenType);
    remoteDtoDbHelper = RemoteDtoDbHelper(localWardenType, remoteWardenType,
        smd, smdSys, exportTransaction, abstractWarden);
    importWaterLineDao = WaterLineDao.sep(smdSys, importTransaction);

    serverWarden = ServerWarden(localWardenType, importWaterLineDao);
    remoteDtoFactory = RemoteDtoFactory();
    exportWaterLineDao = WaterLineDao.sep(smdSys, exportTransaction);
    transactionsFactory = TransactionsFactory(
        localWardenType, remoteWardenType, smd, smdSys, exportTransaction);
    minimalSet = false;
    minimalEnumSet = null;
  }

  Future<void> init() async {
    await importWaterLineDao.init(initTable: initializeTables);
  }

  Future<int> reproduceDataBaseAboveTs(int? ts, final int? C_MAX_ROWS) async {
    int? currentTs = ts;
    int writtenCount = 0;
    AbstractTableTransactions abstractTransactions;
    List<WaterLineDto> waterLineList;
    Iterator<WaterLineDto> waterLineIter;
    WaterLineDto waterLineDto;
    RemoteDto remoteDto;
    bool isEmpty;
    try {
      do {
        waterLineList = await serverWarden.getWaterLineListAboveTs(
            currentTs, C_MAX_ROWS_PER_READ);
        isEmpty = waterLineList.length == 0;
        if (!isEmpty) {
          currentTs = waterLineList[waterLineList.length - 1].water_ts!;

          waterLineIter = waterLineList.iterator;
          while (waterLineIter.moveNext()) {
            print(
                "--------------------------------------------------------------------------------------------------------------------------");
            waterLineDto = waterLineIter.current;
            if (!minimalSet ||
                minimalEnumSet!.contains(waterLineDto.water_table_id)) {
              try {
                remoteDto = await RemoteDtoFactory.getRemoteDtoFromWaterLineDto(
                    waterLineDto,
                    localWardenType,
                    smdSys,
                    importTransaction,
                    initializeTables);
                // Process the write to get accurate Dao
                await remoteDtoDbHelper.storeRemoteDto(remoteDto);

                writtenCount++;
                if (C_MAX_ROWS != null && writtenCount >= C_MAX_ROWS) {
                  isEmpty = true;
                  break;
                }
              } on SqlException catch (e) {
                if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
                    e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
                    e.sqlExceptionEnum ==
                        SqlExceptionEnum.PARTITION_NOT_FOUND) {
                  print("WS $e");
                }
              }
            }
          }
        }
      } while (!isEmpty);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    return writtenCount;
  }
}
