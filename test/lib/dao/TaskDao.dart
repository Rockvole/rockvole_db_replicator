import 'TaskMixin.dart';

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class TaskDto extends Dto with TaskMixin {
  static const String TABLE_NAME='task';
  TaskDto();
  TaskDto.field(FieldData fieldData) : super.field(fieldData);
  TaskDto.list(List<dynamic> list) {
    super.field(listToFieldData(list));
  }
  TaskDto.map(Map<String, dynamic> map) {
    super.field(Dto.mapToFieldData(map, TaskMixin.fieldNames, TaskMixin.C_TABLE_ID));
  }
  TaskDto.wee(int? id, String task_description, bool task_complete) {
    super.wee(TaskMixin.C_TABLE_ID);
    this.id = id;
    this.task_description = task_description;
    this.task_complete = task_complete;
  }

  static SchemaMetaData addSchemaMetaData(SchemaMetaData schemaMetaData) {
    schemaMetaData.addTable(TaskMixin.C_TABLE_ID, TABLE_NAME, uniqueKeysMap: {
      'id': ["id"]
    }, crcFieldNamesList: [
      'task_description',
      'task_complete'
    ], propertiesMap: {
      'min-id-for-user': DbConstants.C_INTEGER_USERSPACE_MIN,
      'index': 'id',
      'is-partition': false
    });
    schemaMetaData.addField(TaskMixin.C_TABLE_ID, 'id', FieldDataType.INTEGER);
    schemaMetaData.addField(TaskMixin.C_TABLE_ID, 'task_description', FieldDataType.VARCHAR,
        fieldSize: 20);
    schemaMetaData.addField(TaskMixin.C_TABLE_ID, 'task_complete', FieldDataType.TINYINT);
    return schemaMetaData;
  }

  static FieldData getSelectFieldData() {
    return Dto.generateSelectFieldData(TaskMixin.fieldNames, TaskMixin.C_TABLE_ID);
  }
}

class TaskDao extends AbstractTransactionDao {
  TaskDao(SchemaMetaData smd, DbTransaction transaction) : super.sep(smd, transaction);
  @override
  Future<bool> init({int? table_id, bool initTable = true}) async {
    return await super.init(table_id: TaskMixin.C_TABLE_ID, initTable: initTable);
  }

  Future<List<TaskDto>> getTaskListByName(String? task_description) async {
    FieldData fieldData = TaskDto.getSelectFieldData();
    WhereData whereData = WhereData();
    whereData.set('task_description', SqlOperator.EQUAL, task_description);
    whereData.addOrder('id',OrderType.ASC);
    RawTableData rawTableData = await super.select(fieldData, whereData);
    List<RawRowData> list=rawTableData.getRawRows();
    List<TaskDto> taskList = [];
    list.forEach((RawRowData rrd) {
      int task_complete = rrd.get('task_complete', null) as int;
      taskList.add(TaskDto.wee(rrd.get('id', null) as int, rrd.get('task_description', null) as String, task_complete==1?true:false));
    });
    return taskList;
  }

  Future<int?> addTaskDto(TaskDto taskDto, WardenType warden) async {
    int id = await getNextId(warden);
    taskDto.id=id;
    return await insertTaskDto(taskDto);
  }

  Future<int?> insertTaskDto(TaskDto taskDto) async {
    return insert(taskDto);
  }

  Future<TaskDto> getTaskDtoById(int id) async {
    RawRowData rawRowData= await getById(id);
    return TaskDto.field(rawRowData.getFieldData());
  }

  Future<TaskDto> getTaskDtoByUnique(String task_description) async {
    WhereData whereData=WhereData();
    whereData.set('task_description', SqlOperator.EQUAL, task_description);
    RawTableData rawTableData = await select(TaskDto.getSelectFieldData(), whereData);
    RawRowData rawRowData = rawTableData.getRawRowData(0);
    return TaskDto.field(rawRowData.getFieldData());
  }

  Future<void> deleteTaskByUnique(int id) async {
    WhereData whereData=WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await delete(whereData);
  }

  Future<void> updateTask(int id, String task_description, bool task_complete) async {
    FieldData fieldData=FieldData.wee(TaskMixin.C_TABLE_ID);
    fieldData.set('task_description', task_description);
    fieldData.set('task_complete', task_complete);
    WhereData whereData=WhereData();
    whereData.set('id', SqlOperator.EQUAL, id);
    await update(fieldData, whereData);
  }
}
