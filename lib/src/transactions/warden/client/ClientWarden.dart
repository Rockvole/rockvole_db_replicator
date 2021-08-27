import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class ClientWarden {
  WardenType? localWardenType;
  WaterLineDao waterLineDao;

  ClientWarden(this.localWardenType, this.waterLineDao) {
    if(!waterLineDao.initialized) throw ArgumentError("WaterLineDao must be initialised");
  }

  static List<WaterState> getWaterStateListByWardenType(WardenType? warden) {
    List<WaterState> waterStateList=[];
    switch(warden) {
      case WardenType.WRITE_SERVER:
        waterStateList.add(WaterState.SERVER_PENDING);
        waterStateList.add(WaterState.SERVER_APPROVED);
        waterStateList.add(WaterState.SERVER_REJECTED);
        break;
      case WardenType.READ_SERVER:
        waterStateList.add(WaterState.SERVER_APPROVED);
        break;
      case WardenType.ADMIN:
        waterStateList.add(WaterState.SERVER_PENDING);
        waterStateList.add(WaterState.SERVER_APPROVED);
        break;
      case WardenType.USER:
        waterStateList.add(WaterState.SERVER_APPROVED);
        break;
      default:
        throw IllegalStateException("Invalid WardenType $warden");
    }
    return waterStateList;
  }

  List<WaterState> _getWaterStateList() {
    List<WaterState> waterStateList=[];
    waterStateList.add(WaterState.CLIENT_STORED);
    switch(localWardenType) {
      case WardenType.READ_SERVER:
        throw IllegalStateException("Cannot send list from Read Server");
      case WardenType.USER:
        break;
      case WardenType.ADMIN:
        waterStateList.add(WaterState.CLIENT_APPROVED);
        waterStateList.add(WaterState.CLIENT_REJECTED);
        break;
      case WardenType.WRITE_SERVER:
        break;
    }
    return waterStateList;
  }

  List<int> getExcludeTableTypeList() {
    List<int> excludeTableTypeList = [];
    switch(localWardenType) {
      case WardenType.USER:
        // List here
        break;
      case WardenType.WRITE_SERVER:
      case WardenType.READ_SERVER:
      case WardenType.ADMIN:
        break;
    }
    return excludeTableTypeList;
  }

  Set<WaterError> getWaterErrorSet() {
    Set<WaterError> waterErrorSet={WaterError.NONE};
    return waterErrorSet;
  }

  Future<List<WaterLineDto>> getWaterLineListToSend() async {
    int minId=WaterLineDto.min_id_for_user-1;
    if(localWardenType==WardenType.ADMIN) minId=0;
    return waterLineDao.getWaterLineListAboveTs(minId, getExcludeTableTypeList(), _getWaterStateList(), getWaterErrorSet(), null, null);
  }

  Future<WaterLineDto> getNextWaterLineToSend() async {
    int minId=WaterLineDto.min_id_for_user-1;
    if(localWardenType==WardenType.ADMIN) minId=0;
    List<int> excludeTableTypeList=getExcludeTableTypeList();
    List<WaterState> waterStateList=_getWaterStateList();
    return waterLineDao.getNextWaterLineDtoAboveTs(minId, excludeTableTypeList, waterStateList, getWaterErrorSet());
  }

  Future<int> getWaterLineToSendCount(List<int> excludeTableIdList) async {
    List<WaterState> stateList=[];
    stateList.add(WaterState.CLIENT_STORED);
    List<int> currentTableIdList=getExcludeTableTypeList();
    if(excludeTableIdList!=null) {
      excludeTableIdList.forEach((int tableId) {
        currentTableIdList.add(tableId);
      });
    }
    List<WaterLineDto>? waterLineList=null;
    int minWaterLineId=WaterLineDto.min_id_for_user;
    try {
      waterLineList=await waterLineDao.getWaterLineListAboveTs(minWaterLineId, currentTableIdList, stateList, getWaterErrorSet(), SortOrderType.PRIMARY_KEY_ASC, 100);
    } on SqlException catch(e) {
      if(e.sqlExceptionEnum==SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      } else if(e.sqlExceptionEnum==SqlExceptionEnum.ENTRY_NOT_FOUND);
      else rethrow;
    }
    if(waterLineList==null) return 0;
    return waterLineList.length;
  }

  Future<int> getLatestTs() async {
    List<WaterState> stateList=getWaterStateListByWardenType(localWardenType);
    int latestTs=0;
    try {
      WaterLineDto waterLineDto=await waterLineDao.getLatestWaterLineDto(stateList);
      latestTs=waterLineDto.water_ts!;
    } on SqlException {
    }
    return latestTs;
  }

  Future<void> cleanWaterLine() async {
    if(Warden.isClient(localWardenType)) {
      try {
        await waterLineDao.deleteBelowLatestTs(WaterState.SERVER_APPROVED);
      } on SqlException catch(e) {
        if(e.sqlExceptionEnum==SqlExceptionEnum.ENTRY_NOT_FOUND) {
          print("WS $e");
        }
      }
    }
  }
}
