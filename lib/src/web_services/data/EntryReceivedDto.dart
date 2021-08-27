import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class EntryReceivedDto extends RemoteDto {
  static const int C_TABLE_ID = 15;
  int? original_table_id;
  int? original_ts;
  int? original_id;
  int? new_id;

  EntryReceivedDto();
  EntryReceivedDto.sep(
      this.original_table_id, this.original_ts, this.original_id, this.new_id, SchemaMetaData smdSys) {
    this.smdSys = smdSys;
    trDto = TrDto.wee(C_TABLE_ID);
    waterLineDto =
        WaterLineDto.sep(null, null, null, C_TABLE_ID, smdSys);
  }

  @override
  String toString() {
    return "EntryReceivedDto [" +
        "original_table_id=$original_table_id" +
        ", original_ts=$original_ts" +
        ", original_id=$original_id" +
        ", new_id=$new_id" +
        "]";
  }
}
