import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class UserTrDto extends TrDto with UserMixin {
  static const String TABLE_NAME='user'+TransactionTools.C_TABLE_EXT;

  UserTrDto();
  UserTrDto.field(FieldData fieldData) : super.field(fieldData);
  UserTrDto.list(List<dynamic> list) {
    super.list(list,6,UserMixin.C_TABLE_ID,fieldData: listToFieldData(list));
  }
  UserTrDto.wee(UserDto userDto, TrDto? trDto) {
    super.clone(trDto, table_id: UserMixin.C_TABLE_ID);
    this.id = userDto.id;
    this.pass_key = userDto.pass_key;
    this.subset = userDto.subset;
    this.warden = userDto.warden;
    this.request_offset_secs = userDto.request_offset_secs;
    this.registered_ts = userDto.registered_ts;
  }
  UserTrDto.sep(
      int? id,
      String? pass_key,
      int? subset,
      WardenType warden,
      int? request_offset_secs,
      int? registered_ts,
      TrDto trDto) {
    super.clone(trDto);
    this.id = id;
    this.pass_key = pass_key;
    this.subset = subset;
    this.warden = warden;
    this.request_offset_secs = request_offset_secs;
    this.registered_ts = registered_ts;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(UserMixin.fieldNames, UserMixin.C_TABLE_ID);
  }
}

class UserTrDao extends AbstractTransactionTrDao {
  UserTrDao(SchemaMetaData smdSys, DbTransaction transaction) : super(smdSys, transaction);
  @override
  Future<void> init({int? table_id, bool initTable = true}) async {
    await super.init(table_id: UserMixin.C_TABLE_ID, initTable: initTable);
  }

  Future<int?> insertDto(UserTrDto userTrDto) async {
    return insert(userTrDto);
  }

  Future<UserTrDto> upsertDto(UserTrDto usertrDto) async {
    WhereData whereData = WhereData();
    whereData.set('ts', SqlOperator.EQUAL, usertrDto.ts);
    await upsertTR(usertrDto, usertrDto.getFieldDataNoTr, whereData);
    return usertrDto;
  }
  
  Future<UserTrDto> getUserTrDtoByTs(ts) async {
    RawRowData rawRowData = await getRawRowDataByTs(ts);
    return UserTrDto.field(rawRowData.getFieldData());
  }
}