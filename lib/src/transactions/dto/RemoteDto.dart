import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class RemoteDto {
  late TrDto trDto;
  WaterLineDto? waterLineDto;
  late SchemaMetaData smdSys;

  RemoteDto();
  RemoteDto.sep(this.trDto, this.smdSys, {this.waterLineDto, int? water_table_id}) {
    sep(trDto,smdSys,waterLineDto: waterLineDto,water_table_id: water_table_id);
  }

  void sep(TrDto trDto, SchemaMetaData smdSys, {WaterLineDto? waterLineDto, int? water_table_id}) {
    this.trDto = trDto;
    this.smdSys = smdSys;
    this.waterLineDto=waterLineDto;
    if(waterLineDto==null) this.waterLineDto=WaterLineDto.sep(0, null, null, water_table_id, smdSys);
  }

  String get water_table_name => waterLineDto!.water_table_name;
  int get water_table_id => waterLineDto!.water_table_id;

  @override
  String toString() {
    return "RemoteDto [\n" +
        trDto.toString() + "\n" + waterLineDto.toString() + "]\n";
  }

  Map<String, dynamic> toMap({bool fullEnum=false}) {
    Map<String, dynamic> map=Map();
    map.addAll(trDto.toMap(fullEnum: fullEnum));
    map.addAll(waterLineDto!.toMap(fullEnum: fullEnum));
    return map;
  }

}
