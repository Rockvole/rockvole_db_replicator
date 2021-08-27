import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class RemoteWaterLineFieldDto extends RemoteDto {
  static const String TABLE_NAME = 'water_line_field';
  late WaterLineFieldDto waterLineFieldDto;

  RemoteWaterLineFieldDto(
      WaterLineFieldDto waterLineFieldDto, SchemaMetaData smdSys,
      {WaterLineDto? waterLineDto}) {
    if (waterLineDto == null)
      waterLineDto =
          WaterLineDto.sep(1, null, null, WaterLineFieldDto.C_TABLE_ID, smdSys);
    super.sep(
        TrDto.sep(1, OperationType.UPDATE, 0, null, null, null,
            WaterLineFieldDto.C_TABLE_ID),
        smdSys,
        waterLineDto: waterLineDto,
        water_table_id: WaterLineFieldDto.C_TABLE_ID);
    this.waterLineFieldDto = waterLineFieldDto;
  }

  WaterLineFieldDto getWaterLineFieldDto() {
    return waterLineFieldDto;
  }

  void setWaterLineFieldDto(WaterLineFieldDto waterLineFieldDto) {
    this.waterLineFieldDto = waterLineFieldDto;
  }

  int get getTableId => waterLineFieldDto.table_id;

  @override
  String toString() {
    String SEP = "\n";
    return "RemoteWaterLineFieldDto{" +
        "waterLineDto=$waterLineDto" +
        ", waterLineFieldDto=$waterLineFieldDto" + SEP +
        ", TrDto=$trDto" +
        '}';
  }
}
