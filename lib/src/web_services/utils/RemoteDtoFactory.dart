import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class RemoteDtoFactory {
  static Future<RemoteDto> getRemoteDtoFromWaterLineDto(
      WaterLineDto waterLineDto,
      WardenType? wardenType,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      bool initializeTable) async {
    RemoteDto remoteDto;

    switch (waterLineDto.water_table_name) {
      case 'authentication':
      case 'entry_received':
      case 'last_field_received':
      case 'max_int':
      case 'product_details':
      case 'remote_state':
      case 'removed':
      case 'water_line':
      case 'water_line_field':
        throw ArgumentError(
            "getRemoteDtoFromWaterLineDto: Unknown TableType " +
                waterLineDto.water_table_name);
      default:
        GenericTrDao genericTrDao = GenericTrDao(smdSys, transaction);
        await genericTrDao.init(
            table_id: waterLineDto.water_table_id, initTable: true);
        FieldData fieldData = smdSys
            .getTableByTableId(waterLineDto.water_table_id)
            .getSelectFieldData(waterLineDto.water_table_id);
        WhereData whereData=WhereData();
        whereData.set(
            'ts', SqlOperator.EQUAL, waterLineDto.water_ts);
        RawTableData rawTableData = await genericTrDao.select(fieldData, whereData);
        RawRowData rawRowData = rawTableData.getRawRowData(0);
        remoteDto = RemoteDto.sep(TrDto.field(rawRowData.getFieldData()), smdSys,
            waterLineDto: waterLineDto);
    }
    return remoteDto;
  }
}
