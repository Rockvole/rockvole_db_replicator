import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

enum ChangeSuperType {
  VOTING, // For Like & Dislike
  NUMERALS, // For Increment & Decrement
  CHANGES, // For Notify
  USER // For user settings
}
enum ChangeType { DISLIKE, LIKE, INCREMENT, DECREMENT, NOTIFY, USER_SETTING }
enum NotifyState {
  CLIENT_STORED,
  CLIENT_SENT,
  CLIENT_UP_TO_DATE,
  CLIENT_OUT_OF_DATE
}
enum UiType { VIEWED, IN_LIST }

class WaterLineField {
  bool initialized = false;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  SchemaMetaData smdSys;
  DbTransaction transaction;
  late WaterLineFieldDao waterLineFieldDao;
  late WaterLineFieldDto waterLineFieldDto;

  WaterLineField(this.localWardenType, this.remoteWardenType, this.smdSys, this.transaction) {
    if(!smdSys.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);
  }

  Future<void> init() async {
    initialized = true;
    this.waterLineFieldDao = WaterLineFieldDao.sep(smdSys, transaction);
    await waterLineFieldDao.init(initTable: true);
  }

  WaterLineFieldDto getWaterLineFieldDto() {
    return waterLineFieldDto;
  }

  void setWaterLineFieldDto(WaterLineFieldDto waterLineFieldDto) {
    this.waterLineFieldDto = waterLineFieldDto;
  }

  static List<ChangeType> getChangeListFromSuperType(
      ChangeSuperType changeSuperType) {
    List<ChangeType> changeList = [];
    switch (changeSuperType) {
      case ChangeSuperType.VOTING:
        changeList.add(ChangeType.LIKE);
        changeList.add(ChangeType.DISLIKE);
        break;
      case ChangeSuperType.NUMERALS:
        changeList.add(ChangeType.INCREMENT);
        changeList.add(ChangeType.DECREMENT);
        break;
      case ChangeSuperType.CHANGES:
        changeList.add(ChangeType.NOTIFY);
        break;
      case ChangeSuperType.USER:
        break;
    }
    return changeList;
  }

  Future<int?> getMaxTs(ChangeSuperType changeSuperType) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? latestTs = 0;
    List<ChangeType> changeList = getChangeListFromSuperType(changeSuperType);
    try {
      latestTs = (await waterLineFieldDao.getMaxWaterLineFieldDto(changeList))
          .remote_ts;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
      } else
        rethrow;
    }
    return latestTs;
  }

  Future<WaterLineFieldDto> setWaterLineField(
      int id,
      int table_field_id,
      ChangeType changeType,
      int userId,
      NotifyState? notifyState,
      int? valueNumber,
      UiType uiType,
      int? remoteTs) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    await waterLineFieldDao.setWaterLineField(id, table_field_id, changeType, userId,
        notifyState, valueNumber, uiType, TimeUtils.getNowCustomTs(), remoteTs);
    waterLineFieldDto = await waterLineFieldDao.getWaterLineFieldDtoByUnique(
        id, table_field_id, changeType, userId);
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> viewEntry(int id, int table_field_id) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool change = false;
    try {
      waterLineFieldDto = await waterLineFieldDao.getWaterLineFieldDtoByUnique(
          id, table_field_id, ChangeType.NOTIFY, WaterLineFieldDto.C_USER_ID_NONE);
      if (waterLineFieldDto.ui_type != UiType.IN_LIST) {
        if (waterLineFieldDto.ui_type != UiType.VIEWED) change = true;
      }
      if (waterLineFieldDto.notify_state_enum != NotifyState.CLIENT_UP_TO_DATE) {
        if (waterLineFieldDto.notify_state_enum != NotifyState.CLIENT_OUT_OF_DATE)
          change = true;
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        change = true;
      }
    }
    if (change) {
      waterLineFieldDto = await setWaterLineField(
          id,
          table_field_id,
          ChangeType.NOTIFY,
          WaterLineFieldDto.C_USER_ID_NONE,
          NotifyState.CLIENT_OUT_OF_DATE,
          null,
          UiType.VIEWED,
          null);
    }
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> inList(int id, int table_field_id) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      waterLineFieldDto = await waterLineFieldDao.getWaterLineFieldDtoByUnique(
          id, table_field_id, ChangeType.NOTIFY, WaterLineFieldDto.C_USER_ID_NONE);
      if (waterLineFieldDto.ui_type == UiType.VIEWED)
        waterLineFieldDto = await setWaterLineField(
            id,
            table_field_id,
            ChangeType.NOTIFY,
            WaterLineFieldDto.C_USER_ID_NONE,
            waterLineFieldDto.notify_state_enum,
            null,
            UiType.IN_LIST,
            null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLineFieldDto = await setWaterLineField(
            id,
            table_field_id,
            ChangeType.NOTIFY,
            WaterLineFieldDto.C_USER_ID_NONE,
            NotifyState.CLIENT_OUT_OF_DATE,
            null,
            UiType.IN_LIST,
            null);
      }
    }
    return waterLineFieldDto;
  }

  Future<List<WaterLineFieldDto>> getWaterLineFieldListAboveTs(int? localTs,
      ChangeSuperType changeSuperType, bool includeMax, int limit) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    List<ChangeType> changeList = getChangeListFromSuperType(changeSuperType);
    return waterLineFieldDao.getWaterLineFieldListAboveLocalTs(
        changeList, null, localTs, null, includeMax, limit);
  }

  Future<List<WaterLineFieldDto>> getWaterLineFieldListToSend() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    List<ChangeType> changeList = [];
    changeList.add(ChangeType.LIKE);
    changeList.add(ChangeType.DISLIKE);
    if (Warden.isServer(localWardenType)) {
      changeList.add(ChangeType.INCREMENT);
      changeList.add(ChangeType.DECREMENT);
    }
    return waterLineFieldDao.getWaterLineFieldListAboveLocalTs(
        changeList, null, null, null, false, 500);
  }

  Future<List<WaterLineFieldDto>> getOutOfDateNotificationsListToSend() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    List<ChangeType> changeList = [];
    changeList.add(ChangeType.NOTIFY);
    return waterLineFieldDao.getWaterLineFieldListAboveLocalTs(
        changeList, NotifyState.CLIENT_OUT_OF_DATE, null, null, false, 500);
  }

  Future<WaterLineFieldDto> updateNotifyState(NotifyState notifyState) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return waterLineFieldDao.updateNotifyState(
        waterLineFieldDto.id,
        waterLineFieldDto.table_field_id,
        waterLineFieldDto.change_type_enum,
        WaterLineFieldDto.C_USER_ID_NONE,
        notifyState);
  }

  // Reset all WaterLineField records so all records are downloaded
  Future<void> clearAllNotifyStates() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        null,
        null,
        ChangeType.NOTIFY,
        0,
        NotifyState.CLIENT_OUT_OF_DATE,
        null,
        null,
        null,
        0,
        smdSys);
    await waterLineFieldDao.updateWaterLineFieldNotifyState(waterLineFieldDto);
  }

  Future<WaterLineFieldDto> updateTs(int? localTs, int? remoteTs) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineFieldDto tmpWaterLineFieldDto;
    try {
      tmpWaterLineFieldDto =
          await waterLineFieldDao.getWaterLineFieldDtoByUnique(
              waterLineFieldDto.id,
              waterLineFieldDto.table_field_id,
              waterLineFieldDto.change_type_enum,
              waterLineFieldDto.user_id);
      if (localTs != null && tmpWaterLineFieldDto.local_ts != null) {
        if (localTs < tmpWaterLineFieldDto.local_ts!) localTs = null;
      }
      if (remoteTs != null && tmpWaterLineFieldDto.remote_ts != null) {
        if (remoteTs < tmpWaterLineFieldDto.remote_ts!) remoteTs = null;
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }

    waterLineFieldDto = await waterLineFieldDao.setWaterLineField(
        waterLineFieldDto.id,
        waterLineFieldDto.table_field_id,
        waterLineFieldDto.change_type_enum,
        waterLineFieldDto.user_id,
        waterLineFieldDto.notify_state_enum,
        waterLineFieldDto.value_number,
        waterLineFieldDto.ui_type,
        localTs,
        remoteTs);
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> updateMaxTs(
      ChangeType changeType, int? localTs, int? remoteTs) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineFieldDto tmpWaterLineFieldDto;
    try {
      tmpWaterLineFieldDto = await waterLineFieldDao.getMaxDto(changeType);
      if (localTs != null && tmpWaterLineFieldDto.local_ts != null) {
        if (localTs < tmpWaterLineFieldDto.local_ts!) localTs = null;
      }
      if (remoteTs != null && tmpWaterLineFieldDto.remote_ts != null) {
        if (remoteTs < tmpWaterLineFieldDto.remote_ts!) remoteTs = null;
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }

    return waterLineFieldDao.setMaxTs(changeType, localTs, remoteTs);
  }

  Future<void> deleteRow() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    await waterLineFieldDao.deleteWaterLineFieldByUnique(
        waterLineFieldDto.id,
        waterLineFieldDto.table_field_id,
        waterLineFieldDto.change_type_enum,
        waterLineFieldDto.user_id);
  }

  Future<WaterLineFieldDto> fetchWaterLineFieldDto(
      int id, int table_field_id, ChangeType changeType, int userId) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    waterLineFieldDto = await waterLineFieldDao.getWaterLineFieldDtoByUnique(
        id, table_field_id, changeType, userId);
    return waterLineFieldDto;
  }

  Future<bool> isUpToDate(int id, int table_field_id) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool isUpToDate = false;
    if (id != null) {
      try {
        waterLineFieldDto =
            await fetchWaterLineFieldDto(id, table_field_id, ChangeType.NOTIFY, 0);
        if (waterLineFieldDto.notify_state_enum == NotifyState.CLIENT_UP_TO_DATE)
          isUpToDate = true;
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum ==
            SqlExceptionEnum
                .ENTRY_NOT_FOUND) // Do nothing because if not found it is not up-to-date
          ;
        else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
          print("WS $e");
      }
    }
    return isUpToDate;
  }

  static int? getChangeSuperTypeValue(ChangeSuperType? changeSuperType) {
    switch (changeSuperType) {
      case ChangeSuperType.VOTING:
        return 0;
      case ChangeSuperType.NUMERALS:
        return 2;
      case ChangeSuperType.CHANGES:
        return 5;
      case ChangeSuperType.USER:
        return 9;
    }
    return null;
  }

  static ChangeSuperType? getChangeSuperType(int? changeSuperValue) {
    switch (changeSuperValue) {
      case 0:
        return ChangeSuperType.VOTING;
      case 2:
        return ChangeSuperType.NUMERALS;
      case 5:
        return ChangeSuperType.CHANGES;
      case 9:
        return ChangeSuperType.USER;
    }
    return null;
  }

  static int? getChangeTypeValue(ChangeType? changeType) {
    switch (changeType) {
      case ChangeType.DISLIKE:
        return 0;
      case ChangeType.LIKE:
        return 1;
      case ChangeType.INCREMENT:
        return 2;
      case ChangeType.DECREMENT:
        return 3;
      case ChangeType.NOTIFY:
        return 5;
      case ChangeType.USER_SETTING:
        return 9;
    }
    return null;
  }

  static ChangeType? getChangeType(int changeValue) {
    switch (changeValue) {
      case 0:
        return ChangeType.DISLIKE;
      case 1:
        return ChangeType.LIKE;
      case 2:
        return ChangeType.INCREMENT;
      case 3:
        return ChangeType.DECREMENT;
      case 5:
        return ChangeType.NOTIFY;
      case 9:
        return ChangeType.USER_SETTING;
    }
    return null;
  }

  static int? getNotifyStateValue(NotifyState? notifyState) {
    switch (notifyState) {
      case NotifyState.CLIENT_STORED:
        return 0;
      case NotifyState.CLIENT_SENT:
        return 1;
      case NotifyState.CLIENT_UP_TO_DATE:
        return 50;
      case NotifyState.CLIENT_OUT_OF_DATE:
        return 51;
    }
    return null;
  }

  static NotifyState? getNotifyState(int? notifyValue) {
    switch (notifyValue) {
      case 0:
        return NotifyState.CLIENT_STORED;
      case 1:
        return NotifyState.CLIENT_SENT;
      case 50:
        return NotifyState.CLIENT_UP_TO_DATE;
      case 51:
        return NotifyState.CLIENT_OUT_OF_DATE;
    }
    return null;
  }

  static int? getUiTypeValue(UiType? uiType) {
    switch (uiType) {
      case UiType.VIEWED:
        return 0;
      case UiType.IN_LIST:
        return 1;
    }
    return null;
  }

  static UiType? getUiType(int? uiValue) {
    switch (uiValue) {
      case 0:
        return UiType.VIEWED;
      case 1:
        return UiType.IN_LIST;
    }
    return null;
  }
}
