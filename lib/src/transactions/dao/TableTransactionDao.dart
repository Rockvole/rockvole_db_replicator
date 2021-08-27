import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class TableTransactionDao extends AbstractTransactionDao {

  TableTransactionDao(SchemaMetaData smd, DbTransaction transaction) : super.sep(smd, transaction);
  Future<void> deleteById(int id) async {
    WhereData whereData=WhereData();
    whereData.set("id", SqlOperator.EQUAL, id);
    await delete(whereData);
  }

  Future<RawRowData> getById(int id) async {
    FieldData fieldData=smd.getTableByTableId(table_id).getSelectFieldData(table_id);
    WhereData whereData=WhereData();
    whereData.set("id", SqlOperator.EQUAL, id);
    RawTableData rawTableData = await select(fieldData,whereData);
    return rawTableData.getRawRowData(0);
  }

  Future<int> getByUnique(FieldData fieldData) async {
    WhereData whereData=WhereData();
    smd.getTableByName(tableName)!.uniqueKeyMap!.forEach((k,uniqueKeyList) {
      uniqueKeyList.forEach((fieldName) {
        whereData.set(fieldName, SqlOperator.EQUAL, fieldData.get(fieldName));
      });
    });
    RawTableData td=await select(FieldData.field(fieldData),whereData);
    return td.getRawFieldByFieldName(0, "id") as int;
  }

  Future<void> modifyId(Object obj, Object newObj) async {
    await modifyField(obj, newObj, "id");
  }
}