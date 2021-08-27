import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class WaterLine {
  static const int C_RETRY_TIMESTAMP_ATTEMPTS = 2;
  SchemaMetaData smdSys;
  DbTransaction transaction;
  String tableName = "water_line";
  WaterLineDao waterLineDao;
  late WaterLineDto waterLineDto;

  WaterLine(this.waterLineDao, this.smdSys, this.transaction);

  int getMinTsForUser() {
    return DbConstants.C_INTEGER_USERSPACE_MIN;
  }

  Future<int> getNextUserTs() async {
    int latestTs = 0;
    latestTs = await waterLineDao.getNextId(WardenType.USER);
    return latestTs;
  }

  Future<WaterLineDto> retrieveByTs(int ts) async {
    WhereData whereData = WhereData();
    whereData.set("water_ts", SqlOperator.EQUAL, ts);
    waterLineDto = await waterLineDao.selectWaterLineDto(whereData);
    return waterLineDto;
  }

  Future<List<WaterLineDto>> getWaterLineListAboveTs(
      int ts, List<int> excludeTableIdList, int limit) async {
    List<WaterState> stateList = [];
    stateList.add(WaterState.SERVER_APPROVED);
    return await waterLineDao.getWaterLineListAboveTs(
        ts, excludeTableIdList, stateList, null, null, limit);
  }

  Future<int> updateRow() async {
    int ts = waterLineDto.water_ts!;
    if (waterLineDto.water_error == WaterError.NONE)
      await waterLineDao.setStates(ts, waterLineDto.water_state, null);
    else
      await waterLineDao.setStates(ts, null, waterLineDto.water_error);
    return ts;
  }

  Future<void> setRow(int ts, WaterState? waterState) async {
    if (waterState == null) waterState = waterLineDto.water_state;
    WaterLineDto wDto = WaterLineDto.sep(ts, waterState,
        waterLineDto.water_error, waterLineDto.water_table_id, smdSys);
    await waterLineDao.setWaterLine(ts, wDto);
    waterLineDto.water_ts = ts;
  }

  Future<int> addRowByUserTs(
      WaterState? waterState, WaterError? waterError) async {
    int ts = await getNextUserTs();
    if (waterState == null) waterState = waterLineDto.water_state;
    if (waterError == null) waterError = waterLineDto.water_error;

    await waterLineDao.insertWaterLine(
        waterLineDto.water_table_id, waterState, waterError,
        ts: ts);
    if (waterState != WaterState.CLIENT_SNAPSHOT) waterLineDto.water_ts = ts;
    return ts;
  }

  Future<int?> addRow(WaterState? waterState) async {
    waterState ??= waterLineDto.water_state;
    int? nextTs;
    try {
      nextTs = (await waterLineDao.getLatestWaterLineDto(null)).water_ts;
    } on SqlException {}
    if (nextTs == null) nextTs = 0;
    nextTs = nextTs + 1;

    waterLineDto.water_ts = await waterLineDao.insertWaterLine(
        waterLineDto.water_table_id, waterState, waterLineDto.water_error,
        ts: nextTs);
    return waterLineDto.water_ts;
  }

  Future<void> updatePlaceholder() async {
    await waterLineDao.setStates(waterLineDto.water_ts!,
        waterLineDto.water_state, waterLineDto.water_error);
  }

  void setWaterState(WaterState? waterState) {
    waterLineDto.water_state = waterState;
  }

  void setWaterError(WaterError waterError) {
    waterLineDto.water_error = waterError;
  }

  WaterLineDto getWaterLineDto() {
    return waterLineDto;
  }

  void setWaterLineDto(WaterLineDto waterLineDto) {
    this.waterLineDto = waterLineDto;
  }

  Future<void> deleteByTs(int ts) async {
    await waterLineDao.deleteWaterLineByTs(ts);
  }

  bool getWriteUserWaterLine(int tableType) {
    bool isPartition =
        smdSys.getTableByTableId(tableType).getProperty("is-partition") as bool;
    if (isPartition) return false;
    return true;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("WaterLine [waterLineDto=" + waterLineDto.toString() + "]");
    return sb.toString();
  }
}
