import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class WaterLineFieldDao extends AbstractTransactionDao {
  WaterLineFieldDao() {
    if(!smd.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);
  }
  WaterLineFieldDao.sep(SchemaMetaData smdSys, DbTransaction transaction)
      : super.sep(smdSys, transaction);

  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super
        .init(table_id: WaterLineFieldDto.C_TABLE_ID, initTable: initTable);
  }

  void checkUniqueFieldsArePresent(
      int? id, int? table_field_id, ChangeType? changeType, int? userId) {
    if (id == null)
      throw SqlException(SqlExceptionEnum.FAILED_SELECT,
          cause: "id must not be null");
    if (table_field_id == null)
      throw SqlException(SqlExceptionEnum.FAILED_SELECT,
          cause: "table_field_id must not be null");
    if (changeType == null)
      throw SqlException(SqlExceptionEnum.FAILED_SELECT,
          cause: "change_type must not be null");
    if (userId == null)
      throw SqlException(SqlExceptionEnum.FAILED_SELECT,
          cause: "user_id must not be null");
  }

  void checkStatesAreValid(
      ChangeType? changeType, NotifyState? notifyState, UiType? uiType) {
    if (uiType != null) {
      if (changeType != ChangeType.NOTIFY)
        throw SqlException(SqlExceptionEnum.FAILED_SELECT,
            cause: "ui_type can only contain values when change_type=NOTIFY");
    }
    if (notifyState == null) return;
    if (changeType == ChangeType.NOTIFY) {
      if (notifyState != NotifyState.CLIENT_UP_TO_DATE &&
          notifyState != NotifyState.CLIENT_OUT_OF_DATE) {
        throw SqlException(SqlExceptionEnum.FAILED_SELECT,
            cause:
                "Invalid combination of change_type: $changeType and notify_state: $notifyState");
      }
    } else {
      // Not NOTIFY
      if (notifyState != NotifyState.CLIENT_STORED &&
          notifyState != NotifyState.CLIENT_SENT) {
        throw SqlException(SqlExceptionEnum.FAILED_SELECT,
            cause:
                "Invalid combination of change_type: $changeType and notify_state: $notifyState");
      }
    }
  }

  void checkValueNumberIsValid(ChangeType? changeType, int? valueNumber) {
    switch (changeType) {
      case ChangeType.INCREMENT:
      case ChangeType.DECREMENT:
      case ChangeType.USER_SETTING:
        if (valueNumber == null)
          throw SqlException(SqlExceptionEnum.FAILED_SELECT,
              cause: "value_number must not be null when change_type is " +
                  changeType.toString());
        break;
      case ChangeType.DISLIKE:
      case ChangeType.LIKE:
      case ChangeType.NOTIFY:
        if (valueNumber != null)
          throw SqlException(SqlExceptionEnum.FAILED_SELECT,
              cause: "value_number must be null when change_type is " +
                  changeType.toString());
        break;
    }
  }

  Future<WaterLineFieldDto> insertWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      checkUniqueFieldsArePresent(
          waterLineFieldDto.id,
          waterLineFieldDto.table_field_id,
          waterLineFieldDto.change_type_enum,
          waterLineFieldDto.user_id);
      checkStatesAreValid(waterLineFieldDto.change_type_enum,
          waterLineFieldDto.notify_state_enum, waterLineFieldDto.ui_type);
      checkValueNumberIsValid(
          waterLineFieldDto.change_type_enum, waterLineFieldDto.value_number);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        throw SqlException(SqlExceptionEnum.FAILED_UPDATE, cause: e.cause);
    }
    await insert(waterLineFieldDto);
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> insertWaterLineField(
      int id,
      int table_field_id,
      ChangeType changeType,
      int userId,
      NotifyState notifyState,
      int valueNumber,
      UiType uiType,
      int localTs,
      int remoteTs) async {
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        changeType,
        userId,
        notifyState,
        valueNumber,
        uiType,
        localTs,
        remoteTs,
        smd);
    return await insertWaterLineFieldDto(waterLineFieldDto);
  }

  Future<WaterLineFieldDto> updateWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      checkUniqueFieldsArePresent(
          waterLineFieldDto.id,
          waterLineFieldDto.table_field_id,
          waterLineFieldDto.change_type_enum,
          waterLineFieldDto.user_id);
      checkStatesAreValid(waterLineFieldDto.change_type_enum,
          waterLineFieldDto.notify_state_enum, waterLineFieldDto.ui_type);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        throw SqlException(SqlExceptionEnum.FAILED_UPDATE);
    }
    WhereData whereData = generateWaterLineFieldWhere(waterLineFieldDto);
    whereData.addWhereFindNull("id", waterLineFieldDto.id);
    if (waterLineFieldDto.table_field_id == null)
      whereData.set("table_field_id", SqlOperator.IS, SqlKeyword("NULL"));
    else
      whereData.set("table_field_id", SqlOperator.EQUAL,
          waterLineFieldDto.table_field_id);
    await update(waterLineFieldDto, whereData);
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> updateWaterLineField(
      int id,
      int table_field_id,
      ChangeType changeType,
      int userId,
      NotifyState notifyState,
      int valueNumber,
      UiType uiType,
      int localTs,
      int remoteTs) async {
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        changeType,
        userId,
        notifyState,
        valueNumber,
        uiType,
        localTs,
        remoteTs,
        smd);
    return await updateWaterLineFieldDto(waterLineFieldDto);
  }

  WhereData generateWaterLineFieldWhere(WaterLineFieldDto waterLineFieldDto) {
    WhereData whereData = WhereData();
    if (waterLineFieldDto.change_type != null)
      whereData.set(
          "change_type", SqlOperator.EQUAL, waterLineFieldDto.change_type);
    return whereData;
  }

  Future<WaterLineFieldDto> updateNotifyState(int? id, int? table_field_id,
      ChangeType? changeType, int userId, NotifyState notifyState) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        changeType,
        userId,
        notifyState,
        null,
        null,
        null,
        null,
        smd);
    WaterLineFieldDto tmpWaterLineFieldDto = await getWaterLineFieldDtoByUnique(
        id, table_field_id, changeType, userId);
    checkStatesAreValid(
        tmpWaterLineFieldDto.change_type_enum, notifyState, null);
    return updateWaterLineFieldDto(waterLineFieldDto);
  }

  Future<WaterLineFieldDto> updateWaterLineFieldNotifyState(
      WaterLineFieldDto waterLineFieldDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WhereData whereData = generateWaterLineFieldWhere(waterLineFieldDto);
    await update(waterLineFieldDto, whereData);
    return waterLineFieldDto;
  }

  Future<WaterLineFieldDto> setWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    late WaterLineFieldDto returnWaterLineFieldDto;
    bool entryFound = true;
    try {
      returnWaterLineFieldDto = await getWaterLineFieldDtoByUnique(
          waterLineFieldDto.id,
          waterLineFieldDto.table_field_id,
          waterLineFieldDto.change_type_enum,
          waterLineFieldDto.user_id);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        entryFound = false;
        returnWaterLineFieldDto =
            await insertWaterLineFieldDto(waterLineFieldDto);
      }
    }
    if (entryFound) {
      try {
        returnWaterLineFieldDto =
            await updateWaterLineFieldDto(waterLineFieldDto);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum != SqlExceptionEnum.FAILED_UPDATE) rethrow;
      }
    }
    return returnWaterLineFieldDto;
  }

  Future<WaterLineFieldDto> setWaterLineField(
      int? id,
      int? table_field_id,
      ChangeType? changeType,
      int? userId,
      NotifyState? notifyState,
      int? valueNumber,
      UiType? uiType,
      int? localTs,
      int? remoteTs) async {
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        changeType,
        userId,
        notifyState,
        valueNumber,
        uiType,
        localTs,
        remoteTs,
        smd);
    return setWaterLineFieldDto(waterLineFieldDto);
  }

  Future<WaterLineFieldDto> setMaxTs(
      ChangeType changeType, int? localTs, int? remoteTs) async {
    return await setWaterLineField(
        DbConstants.C_MEDIUMINT_MAX,
        TransactionTools.C_MAX_INT_TABLE_ID,
        changeType,
        WaterLineFieldDto.C_USER_ID_NONE,
        null,
        null,
        null,
        localTs,
        remoteTs);
  }

  Future<WaterLineFieldDto> getWaterLineFieldDtoByUnique(
      int? id, int? table_field_id, ChangeType? changeType, int? userId) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    checkUniqueFieldsArePresent(id, table_field_id, changeType, userId);
    List<ChangeType> changeList = [];
    if(changeType!=null) changeList.add(changeType);
    return (await getWaterLineFieldList(id, table_field_id, changeList, userId,
        null, null, null, null, null, true, null))[0];
  }

  Future<WaterLineFieldDto> getMaxDto(ChangeType changeType) async {
    return await getWaterLineFieldDtoByUnique(
        DbConstants.C_MEDIUMINT_MAX,
        TransactionTools.C_MAX_INT_TABLE_ID,
        changeType,
        WaterLineFieldDto.C_USER_ID_NONE);
  }

  Future<List<WaterLineFieldDto>> getWaterLineFieldList(
      int? id,
      int? table_field_id,
      List<ChangeType> changeList,
      int? userId,
      NotifyState? notifyState,
      UiType? uiType,
      int? localTs,
      SqlOperator? tsOperator,
      SortOrderType? sortOrderType,
      bool? includeMax,
      int? limit) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if(tsOperator==null) tsOperator=SqlOperator.EQUAL;
    WhereData whereData = getWaterLineFieldWhere(id, table_field_id, changeList,
        uiType, notifyState, localTs, tsOperator, includeMax);
    whereData.limit = limit;
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        id,
        table_field_id,
        null,
        userId,
        notifyState,
        null,
        uiType,
        localTs,
        null,
        smd);
    RawTableData rawTableData =
        await select(waterLineFieldDto, whereData);
    List<WaterLineFieldDto> list = [];
    List<RawRowData> rawRows = rawTableData.getRawRows();
    if (rawRows.length == 0 &&
        (tsOperator == SqlOperator.EQUAL || tsOperator == SqlOperator.MAX))
      throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND);
    rawRows.forEach((RawRowData rrd) {
      list.add(WaterLineFieldDto.field(rrd.getFieldData(), smd));
    });
    return list;
  }

  Future<WaterLineFieldDto> getOldestWaterLineFieldDto(
      List<ChangeType> changeList) async {
    List<WaterLineFieldDto> list = await getWaterLineFieldList(
        null, null, changeList, null, null, null, null, null, null, null, null);
    return list[0];
  }

  Future<List<WaterLineFieldDto>> getWaterLineFieldListAboveLocalTs(
      List<ChangeType> changeList,
      NotifyState? notifyState,
      int? localTs,
      SortOrderType? sortOrderType,
      bool includeMax,
      int limit) async {
    return await getWaterLineFieldList(
        null,
        null,
        changeList,
        null,
        notifyState,
        null,
        localTs,
        SqlOperator.GREATER,
        sortOrderType,
        includeMax,
        limit);
  }

  WhereData getWaterLineFieldWhere(
      int? id,
      int? table_field_id,
      List<ChangeType>? changeTypeList,
      UiType? uiType,
      NotifyState? notifyState,
      int? localTs,
      SqlOperator tsOperator,
      bool? includeMax) {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WhereData whereData = WhereData();
    whereData.set("id", SqlOperator.EQUAL, id);
    if (includeMax == null) includeMax = false;

    if (table_field_id != null)
      whereData.set("table_field_id", SqlOperator.EQUAL, table_field_id);

    if (changeTypeList != null) {
      String inString = "";
      bool firstPass = true;
      for (ChangeType ct in changeTypeList) {
        if (!firstPass) inString += ",";
        inString += "" + WaterLineField.getChangeTypeValue(ct).toString();
        firstPass = false;
      }
      whereData.set("change_type", SqlOperator.IN, inString);
    }
    if (uiType != null)
      whereData.set(
          "ui_type", SqlOperator.EQUAL, WaterLineField.getUiTypeValue(uiType));
    if (notifyState != null)
      whereData.set("notify_state", SqlOperator.EQUAL,
          WaterLineField.getNotifyStateValue(notifyState));
    whereData.set("local_ts", tsOperator, localTs);
    if (!includeMax)
      whereData.set("id", SqlOperator.LESS, DbConstants.C_MEDIUMINT_MAX);
    return whereData;
  }

  Future<int> getWaterLineFieldCountAboveLocalTs(
      List<ChangeType> changeTypeList, int localTs) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    FieldData fieldData = FieldData.wee(table_id);
    fieldData.addFieldSql("count(*) as ts_count");
    WhereData whereData = getWaterLineFieldWhere(null, null, changeTypeList,
        null, null, localTs, SqlOperator.GREATER, null);
    try {
      RawTableData rawTableData = await select(fieldData, whereData);
      return await rawTableData.getRawField(0, 0) as int;
    } on SqlException {
      rethrow;
    }
  }

  Future<WaterLineFieldDto> getMaxWaterLineFieldDto(
      List<ChangeType> changeList) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    List<WaterLineFieldDto> list = await getWaterLineFieldList(
        DbConstants.C_MEDIUMINT_MAX,
        TransactionTools.C_MAX_INT_TABLE_ID,
        changeList,
        WaterLineFieldDto.C_USER_ID_NONE,
        null,
        null,
        null,
        SqlOperator.MAX,
        null,
        true,
        null);
    return list[0];
  }

  Future<void> deleteWaterLineFieldByUnique(
      int? id, int? table_field_id, ChangeType? changeType, int? userId) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    try {
      checkUniqueFieldsArePresent(id, table_field_id, changeType, userId);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        throw SqlException(SqlExceptionEnum.ENTRY_NOT_FOUND, cause: e.cause);
    }
    WhereData whereData = WhereData();
    whereData.set("id", SqlOperator.EQUAL, id);
    whereData.set("table_field_id", SqlOperator.EQUAL, table_field_id);
    whereData.set("change_type", SqlOperator.EQUAL, WaterLineField.getChangeTypeValue(changeType));
    whereData.set("user_id", SqlOperator.EQUAL, userId);

    WhereGenerator whereGenerator = WhereGenerator(DBType.Mysql, smd);
    String sql = "   DELETE " +
        "     FROM " +
        tableName +
        whereGenerator.getWhereString(whereData);
    print(sql);
    try {
      await transaction
          .getConnection()
          .query(sql, FieldData.wee(table_field_id!));
    } on SqlException catch (e) {
      print("WS $e");
    }
  }
}
