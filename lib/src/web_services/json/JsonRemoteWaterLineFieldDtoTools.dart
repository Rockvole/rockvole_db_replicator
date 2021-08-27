import 'dart:convert';
import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class JsonRemoteWaterLineFieldDtoTools {
  SchemaMetaData smdSys;

  JsonRemoteWaterLineFieldDtoTools(
      this.smdSys) {
  }

  List<RemoteDto> processRemoteWaterLineFieldDtoListJson(String? jsonString) {
    List<RemoteDto> list = [];
    RemoteDto remoteDto;
    List<dynamic> tablesArray;
    Map<String, dynamic> tableData;
    int tableTypeId, wlfTableTypeId;
    String tableType, wlfTableType;

    if (jsonString == null) {
      list.add(RemoteStatusDto.sep(smdSys, status: RemoteStatus.PROCESSED_COMPLETE));
      return list;
    }
    try {
      tablesArray=jsonDecode(jsonString);
    } on Exception {
      list.add(RemoteStatusDto.sep(smdSys, status: RemoteStatus.CLIENT_PARSE_ERROR));
      return list;
    }
    for (int i = 0; i < tablesArray.length; i++) {
      tableData = tablesArray[i];
      tableTypeId = tableData["water_table_id"];
      tableType = smdSys.getTableByTableId(tableTypeId).table_name;

      switch (tableType) {
        case "water_line_field":
          int wlfTableFieldId=tableData["table_field_id"];
          wlfTableTypeId = smdSys.getFieldByTableFieldId(wlfTableFieldId)!.table_id;
          wlfTableType = smdSys
              .getTableByTableId(wlfTableTypeId)
              .table_name;
          tableData['notify_state']=WaterLineField.getNotifyStateValue(NotifyState.CLIENT_UP_TO_DATE);
          if(tableData['remote_ts']==null) tableData['remote_ts']=0;
          remoteDto =
              JsonRemoteDtoConversion.getWaterLineFieldDtoFromJson(tableData, smdSys);
          list.add(remoteDto);
          break;
        case "remote_state":
          RemoteStatusDto remoteState =
              JsonRemoteDtoConversion.getRemoteStateFromJson(tableData, smdSys);
          list.add(remoteState);
          break;
        default:
          throw ArgumentError("Unknown Table Type '" + tableType + "'");
      } // switch

    } // for
    return list;
  }
}
