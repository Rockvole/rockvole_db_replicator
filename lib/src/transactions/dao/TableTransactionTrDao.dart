import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

class TableTransactionTrDao extends AbstractTransactionTrDao {

  TableTransactionTrDao(SchemaMetaData smd, DbTransaction transaction) : super(smd, transaction);
  int getMinIdForUser() {
    return smdSys.getTableByName(dao.tableName)!.getProperty('min-id-for-user') as int;
  }

  Future<void> deleteByTs(int ts) async {
    WhereData whereData = WhereData();
    whereData.set("ts", SqlOperator.EQUAL, ts);
    await deleteTR(whereData);
  }

  Future<RawTableData> getTrList(
      int? ts,
      OperationType? operationType,
      int? userId,
      int? userTs,
      String? comment,
      int? crc,
      SortOrderType? sortOrderType,
      bool? oldestTs,
      SqlOperator? sqlOperator) {
    WhereData whereData=setWhereValues(ts, operationType, userId, userTs, comment, crc, null);
    return selectTR(whereData);
  }

  Future<void> modifyId(Object obj, Object newObj) async {
    await modifyField(obj, newObj, "id");
  }
}
