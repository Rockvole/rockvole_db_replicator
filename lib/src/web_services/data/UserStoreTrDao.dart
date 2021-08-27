import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class UserStoreTrDto extends TrDto with UserStoreMixin {
  static const String TABLE_NAME='user_store'+TransactionTools.C_TABLE_EXT;
  UserStoreTrDto();
  UserStoreTrDto.field(FieldData fieldData) : super.field(fieldData);
  UserStoreTrDto.list(List<dynamic> list) {
    super.list(list,8,UserStoreMixin.C_TABLE_ID,fieldData: listToFieldData(list));
  }
  UserStoreTrDto.wee(UserStoreDto userStoreDto, TrDto trDto) {
    super.clone(trDto);
    this.id = userStoreDto.id;
    this.email = userStoreDto.email;
    this.last_seen_ts = userStoreDto.last_seen_ts;
    this.name = userStoreDto.name;
    this.surname = userStoreDto.surname;
    this.records_downloaded = userStoreDto.records_downloaded;
    this.changes_approved_count = userStoreDto.changes_approved_count;
    this.changes_denied_count = userStoreDto.changes_denied_count;
  }
  UserStoreTrDto.sep(
      int? id,
      String? email,
      int? last_seen_ts,
      String? name,
      String? surname,
      int records_downloaded,
      int changes_approved_count,
      int changes_denied_count,
      TrDto trDto) {
    super.clone(trDto);
    this.id = id;
    this.email = email;
    this.last_seen_ts = last_seen_ts;
    this.name = name;
    this.surname = surname;
    this.records_downloaded = records_downloaded;
    this.changes_approved_count = changes_approved_count;
    this.changes_denied_count = changes_denied_count;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(UserStoreMixin.fieldNames, UserStoreMixin.C_TABLE_ID);
  }
}

class UserStoreTrDao extends AbstractTransactionTrDao {
  UserStoreTrDao(SchemaMetaData smdSys, DbTransaction transaction) : super(smdSys, transaction);
  @override
  Future<void> init({int? table_id, bool initTable = true}) async {
    await super.init(table_id: UserStoreMixin.C_TABLE_ID, initTable: initTable);
  }

  Future<int?> insertDto(UserStoreTrDto userStoreTrDto) async {
    return insert(userStoreTrDto);
  }

  Future<UserStoreTrDto> getUserStoreTrDtoByTs(int ts) async {
    FieldData fieldData=UserStoreTrDto.getSelectFieldData();
    RawRowData rawRowData = await getRawRowDataByTs(ts, fieldData: fieldData);
    return UserStoreTrDto.field(rawRowData.getFieldData());
  }

  Future<void> modifyTs(int originalTs, int newTs) async {
    await modifyField(originalTs, newTs, 'ts');
  }
}
