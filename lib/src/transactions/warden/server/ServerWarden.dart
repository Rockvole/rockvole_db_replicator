import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class ServerWarden {
  WardenType? _otherWarden;
  WaterLineDao _waterLineDao;

  ServerWarden(this._otherWarden, this._waterLineDao);

  List<int> getExcludeTableTypeList() {
    List<int> excludeTableTypeList=[];
    if(Warden.isClient(_otherWarden)) {
      //if(waterState==WaterState.SERVER_APPROVED) {
        //excludeTableTypeList.add(TableType.PARTITION_GROUP);
        //excludeTableTypeList.add(TableType.PARTITION_INGREDIENT);
      //}
      if(_otherWarden==WardenType.USER) {
        excludeTableTypeList.add(UserMixin.C_TABLE_ID);
        excludeTableTypeList.add(UserStoreMixin.C_TABLE_ID);
      }
    }
    return excludeTableTypeList;
  }

  Set<WaterError> getWaterErrorSet() {
    Set<WaterError> waterErrorSet = {WaterError.NONE};
    return waterErrorSet;
  }

  Future<List<WaterLineDto>> getWaterLineListAboveTs(int? ts, int limit) async {
    List<WaterState>? stateList=ClientWarden.getWaterStateListByWardenType(_otherWarden);
    return _waterLineDao.getWaterLineListAboveTs(ts, getExcludeTableTypeList(), stateList, getWaterErrorSet(), null, limit);
  }

  Future<int> getWaterLineRecordCount(int? ts) async {
    List<WaterState>? stateList=ClientWarden.getWaterStateListByWardenType(_otherWarden);
    return _waterLineDao.getWaterLineCountAboveTs(ts, null, getExcludeTableTypeList(), stateList, getWaterErrorSet());
  }
}
