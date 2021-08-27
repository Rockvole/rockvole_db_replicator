import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

import '../../rockvole_test.dart';

class TaskItemDto extends Dto with TaskItemMixin {
  static const String TABLE_NAME = 'task_item';

  TaskItemDto();
  TaskItemDto.field(FieldData fieldData) : super.field(fieldData);
  TaskItemDto.list(List<dynamic> list) {
    super.field(listToFieldData(list));
  }
  TaskItemDto.map(Map<String, dynamic> map) {
    super.field(Dto.mapToFieldData(map, TaskItemMixin.fieldNames, TaskItemMixin.C_TABLE_ID));
  }
  TaskItemDto.sep(int id, int task_id, String item_description, bool item_complete) {
    super.wee(TaskItemMixin.C_TABLE_ID);
    this.id = id;
    this.task_id = task_id;
    this.item_description = item_description;
    this.item_complete = item_complete;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(TaskItemMixin.C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id"], 'task_id' : ["task_id", "item_description"]
    }, crcFieldNamesList: [
      'item_description',
      'item_complete'
    ], propertiesMap: {
      'min-id-for-user': DbConstants.C_INTEGER_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(TaskItemMixin.C_TABLE_ID, 'id', FieldDataType.INTEGER);
    schemaMetaData.addField(TaskItemMixin.C_TABLE_ID, 'task_id', FieldDataType.INTEGER);
    schemaMetaData.addField(
        TaskItemMixin.C_TABLE_ID, 'item_description', FieldDataType.VARCHAR,
        fieldSize: 30);
    schemaMetaData.addField(TaskItemMixin.C_TABLE_ID, 'item_complete', FieldDataType.TINYINT);
    return schemaMetaData;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(TaskItemMixin.fieldNames, TaskItemMixin.C_TABLE_ID);
  }
}

class TaskItemDao extends AbstractTransactionDao {
  TaskItemDao(SchemaMetaData smd, DbTransaction transaction)
      : super.sep(smd, transaction);
  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super.init(table_id: TaskItemMixin.C_TABLE_ID, initTable: initTable);
  }

  Future<int> getTotalCount() async {
    FieldData fieldData = FieldData.wee(TaskItemMixin.C_TABLE_ID);
    fieldData.addFieldSql("count(*) as row_count");
    WhereData whereData = WhereData();
    whereData.set('item_complete', SqlOperator.EQUAL, 0);
    try {
      RawTableData rawTableData = await select(fieldData, whereData);
      return rawTableData.getRawField(0, 0) as int;
    } on SqlException {
      rethrow;
    }
  }

  Future<int?> insertDto(TaskItemDto taskItemDto) async {
    return insert(taskItemDto);
  }

  Future<TaskItemDto> getTaskItemDtoById(int id) async {
    RawRowData rawRowData = await getById(id);
    return TaskItemDto.field(rawRowData.getFieldData());
  }

  Future<TaskItemDto> getTaskItemDtoByUnique(int task_id, String item_description) async {
    WhereData whereData=WhereData();
    whereData.set('task_id', SqlOperator.EQUAL, task_id);
    whereData.set('item_description', SqlOperator.EQUAL, item_description);
    RawTableData rawTableData = await select(TaskItemDto.getSelectFieldData(), whereData);
    RawRowData rawRowData = rawTableData.getRawRowData(0);
    return TaskItemDto.field(rawRowData.getFieldData());
  }

  Future<void> deleteTaskItemByUnique(int id) async {
    WhereData whereData=WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await delete(whereData);
  }
}
