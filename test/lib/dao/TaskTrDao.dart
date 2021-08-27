import 'TaskMixin.dart';

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class TaskTrDto extends TrDto with TaskMixin {
  static const String TABLE_NAME='task'+TransactionTools.C_TABLE_EXT;
  TaskTrDto();
  TaskTrDto.field(FieldData fieldData) : super.field(fieldData);
  TaskTrDto.list(List<dynamic> list) {
    super.list(list, 3, TaskMixin.C_TABLE_ID, fieldData: listToFieldData(list));
  }
  TaskTrDto.sep(int? id, String? task_description, bool? task_complete, TrDto trDto) {
    super.clone(trDto);
    this.id = id;
    this.task_description = task_description;
    this.task_complete = task_complete;
  }
  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(TaskMixin.fieldNames, TaskMixin.C_TABLE_ID);
  }
}

class TaskTrDao extends AbstractTransactionTrDao {
  TaskTrDao(SchemaMetaData smd, DbTransaction transaction)
      : super(smd, transaction);
  @override
  Future<void> init({int? table_id, bool initTable = true}) async {
    await super.init(table_id: TaskMixin.C_TABLE_ID, initTable: initTable);
  }

  Future<int?> insertDto(TaskTrDto taskTrDto) async {
    return await insert(taskTrDto);
  }

  @override
  Future<RawTableData> selectTR(
      WhereData whereData, {FieldData? fieldData}) async {
    fieldData ??= TaskTrDto.getSelectFieldData();
    return await super.selectTR(whereData, fieldData: fieldData);
  }

  Future<TaskTrDto> getTaskTrDtoByTs(int ts) async {
    FieldData fieldData=TaskTrDto.getSelectFieldData();
    RawRowData rawRowData = await getRawRowDataByTs(ts, fieldData: fieldData);
    return TaskTrDto.field(rawRowData.getFieldData());
  }
}
