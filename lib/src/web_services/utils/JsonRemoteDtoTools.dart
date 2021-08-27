import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:rockvole_db_replicator/src/web_services/utils/JsonRemoteDtoConversion.dart';

class JsonRemoteDtoTools {
  static RemoteDto getRemoteDtoFromJsonObject(
      Map<String, dynamic> jo, SchemaMetaData smdSys, ConfigurationNameDefaults defaults, {bool compact=false}) {
    if(!smdSys.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);

    RemoteDto remoteDto;
    String tableName;
    int water_table_id = jo["water_table_id"];
    tableName = smdSys
        .getTableByTableId(water_table_id)
        .table_name;
    switch (tableName) {
      case "authentication":
        remoteDto =
            JsonRemoteDtoConversion.getAuthenticationDtoFromJson(jo, smdSys);
        break;
      case "configuration":
        remoteDto = JsonRemoteDtoConversion.getConfigurationTrDtoFromJson(jo, smdSys, defaults);
        break;
      case "entry_received":
        remoteDto =
            JsonRemoteDtoConversion.getEntryReceivedFromJson(jo, smdSys);
        break;
      case "remote_state":
        remoteDto =
            JsonRemoteDtoConversion.getRemoteStateFromJson(jo, smdSys);
        break;
      case "user":
        remoteDto =
            JsonRemoteDtoConversion.getUserTrDtoFromJson(jo, smdSys);
        break;
      case "user_store":
        remoteDto =
            JsonRemoteDtoConversion.getUserStoreTrDtoFromJson(jo, smdSys);
        break;
      case "water_line_field":
        remoteDto = JsonRemoteDtoConversion.getWaterLineFieldDtoFromJson(
            jo, smdSys);
        break;
      case "last_field_received":
      case "max_int":
      case "water_line":
        throw ArgumentError("$tableName Table cannot be passed");
      default:
        remoteDto = JsonRemoteDtoConversion.getTableTrDtoFromJson(jo, smdSys);
    } // switch

    return remoteDto;
  }

  static RemoteDto getRemoteDtoFromJsonString(
      String? jsonString, SchemaMetaData smdSys, ConfigurationNameDefaults defaults, {bool compact=false}) {
    if(!smdSys.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);
    Map<String, dynamic> jo;
    if (jsonString == null) {
      throw RemoteStatusException(RemoteStatus.PROCESSED_COMPLETE);
    }
    try {
      jo = jsonDecode(jsonString);
    } catch (e) {
      print("$e");
      throw RemoteStatusException(RemoteStatus.CLIENT_PARSE_ERROR);
    }
    return getRemoteDtoFromJsonObject(jo, smdSys, defaults, compact: compact);
  }

  static List<RemoteDto> getRemoteDtoListFromJsonString(
      String jsonString, SchemaMetaData smdSys, ConfigurationNameDefaults defaults, {bool compact=false}) {
    if(!smdSys.isSystem) throw ArgumentError(AbstractDao.C_MUST_SYSTEM);
    List<RemoteDto> remoteDtoList = [];
    List<dynamic> jo;
    Map<String, dynamic> tableData;
    try {
      jo = jsonDecode(jsonString);
    } catch (e) {
      print("EX: $e");
      remoteDtoList.add(
          RemoteStatusDto.sep(smdSys, status: RemoteStatus.CLIENT_PARSE_ERROR));
      return remoteDtoList;
    }

    for (int i = 0; i < jo.length; i++) {
      try {
        tableData = jo[i];
        remoteDtoList.add(getRemoteDtoFromJsonObject(tableData, smdSys, defaults, compact: compact));
      } catch (e) {
        print("WS $e");
      }
    }
    return remoteDtoList;
  }

  static Map<String, dynamic> getJsonObjectFromRemoteDto(
      RemoteDto remoteDto, ConfigurationNameDefaults defaults) {
    WaterLineDto? waterLineDto = remoteDto.waterLineDto;
    Map<String, dynamic> jo;

    switch (waterLineDto!.water_table_name) {
      case "remote_state":
        jo = JsonRemoteDtoConversion.getJsonFromRemoteState(remoteDto as RemoteStatusDto);
        break;
      case "user":
        jo = JsonRemoteDtoConversion.getJsonFromUserTrDto(
            UserTrDto.field(remoteDto.trDto), waterLineDto);
        break;
      case "user_store":
        jo = JsonRemoteDtoConversion.getJsonFromUserStoreTrDto(
            UserStoreTrDto.field(remoteDto.trDto), waterLineDto);
        break;
      case "water_line_field":
        jo = JsonRemoteDtoConversion.getJsonFromWaterLineFieldDto(
            remoteDto as RemoteWaterLineFieldDto, waterLineDto);
        break;
      case "authentication":
      case "entry_received":
      case "last_field_received":
      case "max_int":
      case "water_line":
        throw ArgumentError(
            waterLineDto.water_table_name + " Table cannot be passed");
        break;
      default:
        jo = JsonRemoteDtoConversion.getJsonFromTableTrDto(remoteDto.trDto, waterLineDto);
    } // switch
    return jo;
  }

  static String getJsonStringFromRemoteDtoList(
      List<RemoteDto> remoteDtoList, ConfigurationNameDefaults defaults) {
    List<Map<String, dynamic>> list = [];
    remoteDtoList.forEach((RemoteDto remoteDto) {
      list.add(
          JsonRemoteDtoTools.getJsonObjectFromRemoteDto(remoteDto, defaults));
    });
    String jsonString = jsonEncode(list);
    return jsonString;
  }
}
