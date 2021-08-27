import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_db.dart';

import '../../rockvole_test.dart';

class TaskItemTrDto extends TrDto with TaskItemMixin {
  static const String TABLE_NAME='task_item'+TransactionTools.C_TABLE_EXT;
  TaskItemTrDto.field(FieldData fieldData) : super.field(fieldData);
  TaskItemTrDto.list(List<dynamic> list) {
    super.list(list, 4, TaskItemMixin.C_TABLE_ID, fieldData: listToFieldData(list));
  }
  TaskItemTrDto.sep(int? id, int task_id, String item_description, bool item_complete, TrDto trDto) {
    super.clone(trDto);
    this.id = id;
    this.task_id = task_id;
    this.item_description = item_description;
    this.item_complete = item_complete;
  }
  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(TaskItemMixin.fieldNames, TaskItemMixin.C_TABLE_ID);
  }
}

class TaskItemTrDao extends AbstractTransactionTrDao {

  TaskItemTrDao(SchemaMetaData smd, DbTransaction transaction) : super(smd, transaction);
  @override
  Future<void> init({int? table_id, bool initTable = true}) async {
    await super.init(table_id: TaskItemMixin.C_TABLE_ID, initTable: initTable);
  }

  @override
  Future<RawTableData> selectTR(WhereData whereData, {FieldData? fieldData}) async {
    fieldData ??= TaskItemTrDto.getSelectFieldData();
    return await super.selectTR(whereData, fieldData: fieldData);
  }

  Future<int> getTotalCount() async {
    FieldData fieldData=FieldData.wee(TaskItemMixin.C_TABLE_ID);
    fieldData.addFieldSql("count(*) as row_count");
    WhereData whereData=WhereData();
    whereData.set('item_complete', SqlOperator.EQUAL, 0);
    try {
      RawTableData rawTableData = await dao.select(fieldData,whereData);
      return rawTableData.getRawField(0, 0) as int;
    } on SqlException {
      rethrow;
    }
  }

  Future<TaskItemTrDto> getTaskItemTrDtoByTs(int ts) async {
    FieldData fieldData=TaskItemTrDto.getSelectFieldData();
    RawRowData rawRowData = await getRawRowDataByTs(ts, fieldData: fieldData);
    return TaskItemTrDto.field(rawRowData.getFieldData());
  }

  Future<int?> insertDto(TaskItemTrDto taskItemTrDto) async {
    return insert(taskItemTrDto);
  }

  Future<void> updateTaskItemHC(int? id, String itemDescription, bool itemComplete, TrDto trDto) async {
    FieldData fieldData=FieldData.wee(TaskItemMixin.C_TABLE_ID);
    fieldData.set('id', id);
    fieldData.set('item_description', itemDescription);
    fieldData.set('item_complete', itemComplete?1:0);
    WhereData whereData=WhereData();
    whereData.set('ts', SqlOperator.EQUAL, trDto.ts);
    await super.updateTR(trDto,fieldData,whereData);
  }
}
