import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class UserDao extends AbstractTransactionDao {
  UserDao(SchemaMetaData smd, DbTransaction transaction)
      : super.sep(smd, transaction);
  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super
        .init(table_id: UserMixin.C_TABLE_ID, initTable: initTable);
  }

  @override
  Future<RawTableData> select(FieldData fieldData,
      WhereData whereData) async {
    //fieldData ??= UserDto.getSelectFieldData();
    return await super.select(fieldData, whereData);
  }

  Future<List<UserDto>> getUserDtoList(int? id, String? passKey, int? subset,
      WardenType? wardenType, SortOrderType? sortOrderType) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    FieldData fieldData=UserDto.getSelectFieldData();
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    whereData.set('pass_key', SqlOperator.EQUAL, passKey);
    whereData.set('subset', SqlOperator.EQUAL, subset);
    whereData.set(
        'warden', SqlOperator.EQUAL, Warden.getWardenValue(wardenType));
    String sql = sqlCommands.select(fieldData, whereData);
    sql += getSortOrderString(sortOrderType, 'registered_ts');
    print(sql);
    RawTableData rawTableData = await bareSelect(sql, fieldData);
    List<UserDto> list = [];
    rawTableData.getRawRows().forEach((rrd) {
      list.add(UserDto.field(rrd.getFieldData()));
    });
    return list;
  }

  Future<UserDto> getUserDtoById(int id) async {
    List<UserDto> list = await getUserDtoList(id, null, null, null, null);
    return list[0];
  }

  Future<UserDto> setUserDto(UserDto userDto) async {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, userDto.id);
    await upsert(userDto, whereData);
    return userDto;
  }

  Future<int?> insertDto(UserDto userDto) async {
    return insert(userDto);
  }

  Future<int?> addDto(UserDto userDto, WardenType localWardenType) async {
    userDto.id = await getNextId(localWardenType);
    return await insertDto(userDto);
  }

  Future<void> deleteUserById(int id) async {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await delete(whereData);
  }

  Future<UserDto> updateUserById(int id, String? passKey, int subset,
      WardenType? wardenType, int requestOffsetSecs, int registeredTs) async {
    WhereData whereData = WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    UserDto userDto = UserDto.sep(
        null, passKey, subset, wardenType, requestOffsetSecs, registeredTs);
    await super.update(userDto, whereData);
    return userDto;
  }

  Future<void> modifyId(int originalId, int newId) async {
    await modifyField(originalId, newId, 'id');
  }
}
