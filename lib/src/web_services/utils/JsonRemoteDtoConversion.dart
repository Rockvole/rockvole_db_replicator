import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class JsonRemoteDtoConversion {

// ------------------------------------------------------------------------------------------------- ENTRY RECEIVED
  static EntryReceivedDto getEntryReceivedFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? returnedId, newId;
    if (jo["original_id"] != null) returnedId = jo["original_id"];
    if (jo["new_id"] != null) newId = jo["new_id"];
    EntryReceivedDto entryReceivedDto = EntryReceivedDto.sep(
        jo["original_table_id"], jo["original_ts"], returnedId!, newId, smdSys);
    return entryReceivedDto;
  }

  static Map<String, dynamic> getJsonFromEntryReceived(
      EntryReceivedDto entryReceivedDto) {
    Map<String, dynamic> jo = Map();
    jo["water_table_id"] = EntryReceivedDto.C_TABLE_ID;
    jo["original_table_id"] = entryReceivedDto.original_table_id;
    jo["original_ts"] = entryReceivedDto.original_ts;
    jo["original_id"] = entryReceivedDto.original_id;
    jo["new_id"] = entryReceivedDto.new_id;
    return jo;
  }

// ------------------------------------------------------------------------------------------------- REMOTE STATE
  static RemoteStatusDto getRemoteStateFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    RemoteStatusDto remoteState = RemoteStatusDto.sep(smdSys,
        status: RemoteStatusDto.getRemoteStatusType(jo["condition"]),
        message: jo["message"]);
    return remoteState;
  }

  static Map<String, dynamic> getJsonFromRemoteState(RemoteStatusDto remoteState) {
    Map<String, dynamic> jo = Map();
    jo["water_table_id"] = RemoteStatusDto.C_TABLE_ID;
    jo["condition"] =
        RemoteStatusDto.getRemoteStatusValue(remoteState.status);
    jo["message"] = remoteState.message;
    return jo;
  }

// ------------------------------------------------------------------------------------------------- AUTHENTICATION
  static AuthenticationDto getAuthenticationDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    AuthenticationDto authenticationDto = AuthenticationDto.sep(
        jo["new_records"],
        jo["server_ts"],
        Warden.getWardenType(jo["warden"]),
        smdSys);
    return authenticationDto;
  }

  static Map<String, dynamic> getJsonFromAuthenticationDto(
      AuthenticationDto authenticationDto) {
    Map<String, dynamic> jo = Map();
    jo["water_table_id"] = AuthenticationDto.C_TABLE_ID;
    jo["new_records"] = authenticationDto.newRecords;
    jo["server_ts"] = authenticationDto.serverTs;
    jo["warden"] =
        Warden.getWardenValue(authenticationDto.warden);
    return jo;
  }

// ------------------------------------------------------------------------------------------------- CONFIGURATION
  static RemoteDto getConfigurationTrDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys, ConfigurationNameDefaults defaults) {
    int? id;
    int? valueNumber;
    String? valueString;
    TrDto historicalChangesDto = getTransactionDtoFromJson(jo, ConfigurationMixin.C_TABLE_ID);
    if (jo["id"] != null) id = jo["id"];
    if (jo["value_number"] != null) valueNumber = jo["value_number"];
    if (jo["value_string"] != null) valueString = jo["value_string"];
    print("jo=$jo");
    ConfigurationTrDto configurationTrDto = ConfigurationTrDto.sep(
        id,
        jo["subset"],
        Warden.getWardenType(jo["warden"]),
        defaults
            .getConfigurationNameStructFromName(jo["configuration_name"])!
            .configurationNameEnum,
        jo["ordinal"],
        valueNumber,
        valueString,
        historicalChangesDto,
        defaults);
    WaterLineDto waterLineDto = getWaterLineDtoFromJson(jo, smdSys);
    RemoteDto remoteDto =
        RemoteDto.sep(configurationTrDto, smdSys, waterLineDto: waterLineDto);
    return remoteDto;
  }

  static Map<String, dynamic> getJsonFromTableTrDto(TrDto trDto, WaterLineDto waterLineDto) {
    Map<String, dynamic> jo = getJsonFromTransactionDto(trDto);
    jo = appendJsonFromWaterLineDto(jo, waterLineDto);
    jo["water_table_id"] = waterLineDto.water_table_id;
    FieldData fieldData=trDto.getFieldDataNoTr;
    List<FieldStruct> list=fieldData.getFieldStructList;
    list.forEach((FieldStruct fs) {
      jo[fs.fieldName!]=fs.value;
    });
    return jo;
  }
// ------------------------------------------------------------------------------------------------- USER
  static RemoteDto getTableTrDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? ts;
    int? water_table_id;
    WaterState? waterState;
    WaterError? waterError;
    TrDto trDto=TrDto.wee(jo['water_table_id']);
    jo.forEach((fieldName,fieldValue) {
      switch(fieldName) {
        case "water_ts":
          ts=fieldValue;
          break;
        case "water_table_id":
          water_table_id=fieldValue;
          break;
        case "water_state":
          waterState=WaterStateAccess.getWaterState(fieldValue);
          break;
        case "water_error":
          waterError=WaterErrorAccess.getWaterError(fieldValue);
          break;
        default:
          trDto.set(fieldName, fieldValue);
      }
    });
    WaterLineDto waterLineDto=WaterLineDto.sep(ts, waterState, waterError, water_table_id, smdSys);
    RemoteDto remoteDto=RemoteDto.sep(trDto, smdSys, waterLineDto: waterLineDto);
    return remoteDto;
  }
  static RemoteDto getUserTrDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? id;
    String? passKey;
    TrDto historicalChangesDto = getTransactionDtoFromJson(jo, UserMixin.C_TABLE_ID);
    if (jo["id"] != null) id = jo["id"];
    if (jo["pass_key"] != null) passKey = jo["pass_key"];

    UserTrDto userTrDto = UserTrDto.sep(
        id,
        passKey,
        jo["subset"],
        Warden.getWardenType(jo["warden"]),
        jo["request_offset_secs"],
        jo["registered_ts"],
        historicalChangesDto);
    WaterLineDto waterLineDto = getWaterLineDtoFromJson(jo, smdSys);
    RemoteDto remoteDto =
        RemoteDto.sep(userTrDto, smdSys, waterLineDto: waterLineDto);
    return remoteDto;
  }

  static Map<String, dynamic> getJsonFromUserTrDto(
      UserTrDto userTrDto, WaterLineDto? waterLineDto) {
    Map<String, dynamic> jo;
    if (waterLineDto == null) {
      jo = Map();
    } else {
      jo = getJsonFromTransactionDto(userTrDto.getTrDto);
      jo = appendJsonFromWaterLineDto(jo, waterLineDto);
    }
    jo["water_table_id"] = UserMixin.C_TABLE_ID;
    jo["id"] = userTrDto.id;
    jo["pass_key"] = userTrDto.pass_key;
    jo["subset"] = userTrDto.subset;
    jo["warden"] = Warden.getWardenValue(userTrDto.warden);
    jo["request_offset_secs"] = userTrDto.request_offset_secs;
    jo["registered_ts"] = userTrDto.registered_ts;
    userTrDto.getTrDto;
    return jo;
  }

// ------------------------------------------------------------------------------------------------- USER STORE
  static RemoteDto getUserStoreTrDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? id, lastSeenTs;
    String? email, name, surname;
    TrDto historicalChangesDto = getTransactionDtoFromJson(jo, UserStoreMixin.C_TABLE_ID);
    if (jo["id"] != null) id = jo["id"];
    if (jo["email"] != null) email = jo["email"];
    if (jo["last_seen_ts"] != null) lastSeenTs = jo["last_seen_ts"];
    if (jo["name"] != null) name = jo["name"];
    if (jo["surname"] != null) surname = jo["surname"];

    UserStoreTrDto userStoreTrDto = UserStoreTrDto.sep(
        id,
        email,
        lastSeenTs,
        name,
        surname,
        jo["records_downloaded"],
        jo["changes_approved_count"],
        jo["changes_denied_count"],
        historicalChangesDto);
    WaterLineDto waterLineDto = getWaterLineDtoFromJson(jo, smdSys);
    RemoteDto remoteDto =
        RemoteDto.sep(userStoreTrDto, smdSys, waterLineDto: waterLineDto);
    return remoteDto;
  }

  static Map<String, dynamic> getJsonFromUserStoreTrDto(
      UserStoreTrDto userStoreTrDto, WaterLineDto waterLineDto) {
    Map<String, dynamic> jo;
    if (waterLineDto == null) {
      jo = Map();
    } else {
      jo = getJsonFromTransactionDto(userStoreTrDto.getTrDto);
      jo = appendJsonFromWaterLineDto(jo, waterLineDto);
    }
    jo["water_table_id"] = UserStoreMixin.C_TABLE_ID;
    jo["id"] = userStoreTrDto.id;
    jo["email"] = userStoreTrDto.email;
    jo["last_seen_ts"] = userStoreTrDto.last_seen_ts;
    jo["name"] = userStoreTrDto.name;
    jo["surname"] = userStoreTrDto.surname;
    jo["records_downloaded"] = userStoreTrDto.records_downloaded;
    jo["changes_approved_count"] = userStoreTrDto.changes_approved_count;
    jo["changes_denied_count"] = userStoreTrDto.changes_denied_count;
    userStoreTrDto.getTrDto;
    return jo;
  }

// ------------------------------------------------------------------------------------------------- HISTORICAL CHANGES
  static Map<String, dynamic> getJsonFromTransactionDto(
      TrDto historicalChangesDto) {
    Map<String, dynamic> jo = Map();
    jo["ts"] = historicalChangesDto.ts;
    OperationType? operationType = historicalChangesDto.operation;
    jo["operation"] = OperationTypeAccess.getOperationValue(operationType);
    jo["user_id"] = historicalChangesDto.user_id;
    jo["user_ts"] = historicalChangesDto.user_ts;
    jo["comment"] = historicalChangesDto.comment;
    int? crc = historicalChangesDto.crc;
    if (crc != null) jo["crc"] = crc;

    return jo;
  }

  static TrDto getTransactionDtoFromJson(Map<String, dynamic> jo, int table_id) {
    int? crc;
    int? ts, userId, userTs;
    OperationType? operationType;
    String? comment;

    if (jo["ts"] != null) ts = jo["ts"];
    if (jo["operation"] != null)
      operationType =
          OperationTypeAccess.getOperationType(jo["operation"]);
    if (jo["user_id"] != null) userId = jo["user_id"];
    if (jo["user_ts"] != null) userTs = jo["user_ts"];
    if (jo["comment"] != null) comment = jo["comment"];
    if (jo.containsKey("crc")) crc = jo["crc"];

    TrDto historicalChangesDto =
        TrDto.sep(ts, operationType, userId, userTs, comment, crc, table_id);
    return historicalChangesDto;
  }

// ------------------------------------------------------------------------------------------------- WATER LINE
  static Map<String, dynamic> appendJsonFromWaterLineDto(
      Map<String, dynamic> jo, WaterLineDto waterLineDto) {
    jo["water_ts"] = waterLineDto.water_ts;
    jo["water_table_id"] = waterLineDto.water_table_id;
    WaterState? waterState = waterLineDto.water_state;
    if (waterState != null) jo["water_state"] = WaterStateAccess.getWaterStateValue(waterState);
    WaterError? waterError = waterLineDto.water_error;
    if (waterError != null) jo["water_error"] = WaterErrorAccess.getWaterErrorValue(waterError);

    return jo;
  }

  static WaterLineDto getWaterLineDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? ts;
    WaterState? waterState;
    WaterError? waterError;

    if (jo["water_ts"] != null) ts = jo["water_ts"];
    if (jo.containsKey("water_state"))
      waterState = WaterStateAccess.getWaterState(jo["water_state"]);
    if (jo.containsKey("water_error"))
      waterError = WaterErrorAccess.getWaterError(jo["water_error"]);

    WaterLineDto waterLineDto = WaterLineDto.sep(
        ts, waterState, waterError, jo["water_table_id"], smdSys);
    return waterLineDto;
  }

// ------------------------------------------------------------------------------------------------- WATER LINE FIELD
  static RemoteDto getWaterLineFieldDtoFromJson(Map<String, dynamic> jo, SchemaMetaData smdSys) {
    int? value, localTs, remoteTs;
    NotifyState? notifyState;
    if (jo.containsKey("notify_state")) {
      notifyState = WaterLineField.getNotifyState(jo["notify_state"]);
    }
    if (jo.containsKey("value_number")) value = jo["value_number"];
    if (jo.containsKey("local_ts")) localTs = jo["local_ts"];
    if (jo.containsKey("remote_ts")) remoteTs = jo["remote_ts"];
    WaterLineFieldDto waterLineFieldDto = WaterLineFieldDto.sep(
        jo["id"],
        jo["table_field_id"],
        WaterLineField.getChangeType(jo["change_type"]),
        jo["user_id"],
        notifyState,
        value,
        null,
        localTs,
        remoteTs,
        smdSys);
    return RemoteWaterLineFieldDto(waterLineFieldDto, smdSys);
  }

  static Map<String, dynamic> getJsonFromWaterLineFieldDto(
      RemoteWaterLineFieldDto remoteWaterLineFieldDto,
      WaterLineDto waterLineDto) {
    Map<String, dynamic> jo = Map();
    jo = appendJsonFromWaterLineDto(jo, waterLineDto);

    jo["water_table_id"] = WaterLineFieldDto.C_TABLE_ID;
    jo["id"] = remoteWaterLineFieldDto.getWaterLineFieldDto().id;
    jo["table_field_id"] =
        remoteWaterLineFieldDto.getWaterLineFieldDto().table_field_id;
    jo["change_type"] =
        remoteWaterLineFieldDto.getWaterLineFieldDto().change_type;
    jo["user_id"] = remoteWaterLineFieldDto.getWaterLineFieldDto().user_id;

    if (remoteWaterLineFieldDto.getWaterLineFieldDto().notify_state != null)
      jo["notify_state"] =
          remoteWaterLineFieldDto.getWaterLineFieldDto().notify_state;
    jo["value_number"] =
        remoteWaterLineFieldDto.getWaterLineFieldDto().value_number;
    jo["local_ts"] =
        remoteWaterLineFieldDto.getWaterLineFieldDto().local_ts;
    jo["remote_ts"] =
        remoteWaterLineFieldDto.getWaterLineFieldDto().remote_ts;
    return jo;
  }
}
