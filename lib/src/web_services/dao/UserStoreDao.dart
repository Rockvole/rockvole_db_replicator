import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class UserStoreDao extends AbstractTransactionDao {
  UserStoreDao(SchemaMetaData smd, DbTransaction transaction) : super.sep(smd, transaction);
  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super.init(table_id: UserStoreMixin.C_TABLE_ID, initTable: initTable);
  }

  @override
  Future<RawTableData> select(FieldData fieldData, WhereData whereData) async {
    //fieldData ??= UserStoreDto.getSelectFieldData();
    return await super.select(fieldData, whereData);
  }

  UserStoreDto updateUserStoreDto(UserStoreDto userStoreDto) {
    return userStoreDto;
  }

  Future<UserStoreDto> updateUserStoreByUnique(
      String email,
      int? last_seen_ts,
      String? name,
      String? surname,
      int? records_downloaded,
      int? changes_approved_count,
      int? changes_denied_count) async {
    UserStoreDto userStoreDto = await getUserStoreDtoByUnique(email);
    UserStoreDto newUserStoreDto = UserStoreDto.sep(
        userStoreDto.id!,
        email,
        last_seen_ts,
        name,
        surname,
        records_downloaded,
        changes_approved_count,
        changes_denied_count);
    WhereData whereData=WhereData();
    whereData.set('email', SqlOperator.EQUAL, email);
    await update(newUserStoreDto, whereData);
    return newUserStoreDto;
  }

  Future<UserStoreDto> updateUserStoreDtoByUnique(
      UserStoreDto userStoreDto) async {
    return await updateUserStoreByUnique(
        userStoreDto.email!,
        userStoreDto.last_seen_ts,
        userStoreDto.name,
        userStoreDto.surname,
        userStoreDto.records_downloaded,
        userStoreDto.changes_approved_count,
        userStoreDto.changes_denied_count);
  }

  Future<List<UserStoreDto>> getUserStoreList(int? id, String? email, String? name,
      String? surname, SortOrderType? sortOrderType) async {
    WhereData whereData=WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    whereData.set('email', SqlOperator.EQUAL, email);
    whereData.set('name', SqlOperator.EQUAL, name);
    whereData.set('surname', SqlOperator.EQUAL, surname);
    RawTableData rawTableData = await select(UserStoreDto.getSelectFieldData(), whereData);
    List<UserStoreDto> list = [];
    rawTableData.getRawRows().forEach((rrd) {
      list.add(UserStoreDto.field(rrd.getFieldData()));
    });
    return list;
  }

  Future<UserStoreDto> getUserStoreDtoById(int id) async {
    List<UserStoreDto> list =
    await getUserStoreList(id, null, null, null, null);
    return list[0];
  }

  Future<UserStoreDto> getUserStoreDtoByUnique(String email) async {
    List<UserStoreDto> list =
    await getUserStoreList(null, email, null, null, null);
    return list[0];
  }

  Future<UserStoreDto> setUserStoreDto(UserStoreDto userStoreDto) async {
    WhereData whereData=WhereData();
    whereData.set('id', SqlOperator.EQUAL, userStoreDto.id);
    await upsert(userStoreDto, whereData);
    return userStoreDto;
  }

  Future<int?> insertDto(UserStoreDto userStoreDto) async {
    return insert(userStoreDto);
  }

  Future<void> deleteUserStoreById(int id) async {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await delete(whereData);
  }

  Future<void> modifyId(int originalId, int newId) async {
    await modifyField(originalId, newId, 'id');
  }
}
