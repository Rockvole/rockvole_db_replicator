import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class AuthenticationDto extends RemoteDto {
  static const int C_TABLE_ID = 10;

  AuthenticationDto.sep(int? newRecords, int? serverTs, WardenType? warden, SchemaMetaData smdSys) {
    trDto = TrDto.wee(C_TABLE_ID);
    waterLineDto=WaterLineDto.sep(null, null, null, C_TABLE_ID, smdSys);
    this.newRecords = newRecords;
    this.serverTs = serverTs;
    this.warden = warden;
    super.sep(trDto, smdSys, waterLineDto: waterLineDto, water_table_id: C_TABLE_ID);
  }

  int? get newRecords => trDto.get('new_records') as int;
  set newRecords(int? newRecords) => trDto.set('new_records', newRecords);

  int? get serverTs => trDto.get('server_ts') as int;
  set serverTs(int? serverTs) => trDto.set('server_ts', serverTs);

  WardenType? get warden {
    int wardenInt = trDto.get('warden') as int;
    if (wardenInt == null) return null;
    return Warden.getWardenType(wardenInt);
  }

  set warden(WardenType? wardenType) =>
      trDto.set('warden', Warden.getWardenValue(wardenType));

  @override
  String toString() {
    return "AuthenticationDto [new_records=$newRecords" +
        ",server_ts=$serverTs" +
        ",warden=$warden" +
        "]";
  }

}
