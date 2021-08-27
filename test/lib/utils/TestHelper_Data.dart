import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import '../../rockvole_test.dart';

class TestTrDataStruct {
  int? ts;
  OperationType? operation;
  int? user_id;
  int? user_ts;
  String? comment;
  int? crc;
  IdentSpace? idSpace;
  IdentSpace? tsSpace;
  bool ensureExists;
  int min_id_for_user;

  TestTrDataStruct(
      {this.ts,
      this.operation,
      this.user_id,
      this.user_ts,
      this.comment,
      this.crc,
      this.idSpace=IdentSpace.USER_SPACE,
      this.tsSpace=IdentSpace.USER_SPACE,
      this.ensureExists=true,
      this.min_id_for_user=DbConstants.C_INTEGER_USERSPACE_MIN});

  TrDto getTrDto(int table_id) {
    FieldData fieldData = FieldData.wee(table_id);
    return TrDto.sep(ts, operation, user_id, user_ts, comment, crc, table_id,
        fieldData: fieldData);
  }
}

class TestUserDataStruct {
  int? id;
  String? pass_key;
  int? subset;
  WardenType? warden;
  int? request_offset_secs;
  int? registered_ts;
  int min_id_for_user = UserMixin.min_id_for_user;

  TestUserDataStruct(
      {this.id,
      this.pass_key,
      this.subset,
      this.warden,
      this.request_offset_secs = 0,
      this.registered_ts = 0});
}

class TestUserStoreDataStruct {
  int? id;
  String? email;
  int? last_seen_ts;
  String? name;
  String? surname;
  int? records_downloaded;
  int? changes_approved_count;
  int? changes_denied_count;
  int min_id_for_user = UserStoreMixin.min_id_for_user;

  TestUserStoreDataStruct(
      {this.id,
      this.email,
      this.last_seen_ts,
      this.name,
      this.surname,
      this.records_downloaded = 0,
      this.changes_approved_count = 0,
      this.changes_denied_count = 0});
}

class TestWaterLineDataStruct {
  int? water_ts;
  int? water_table_id;
  WaterState? water_state;
  WaterError? water_error;
  IdentSpace? tsSpace;

  TestWaterLineDataStruct(
      {this.water_ts,
      this.water_table_id,
      this.water_state = WaterState.CLIENT_SENT,
      this.water_error = WaterError.NONE,
      this.tsSpace = IdentSpace.USER_SPACE});
}

class TestTaskDataStruct {
  int? id;
  String? task_description;
  bool? task_complete;
  IdentSpace? idSpace;
  int min_id_for_user = TaskMixin.min_id_for_user;
  bool ensureExists;

  TestTaskDataStruct(
      {this.id,
      this.task_description,
      this.task_complete,
      this.idSpace,
      this.ensureExists=true});

  @override
  String toString() {
    return "TestTaskDataStruct [id:$id, task_description:$task_description, " +
        "task_complete:$task_complete, idSpace:$idSpace, min_id_for_user:$min_id_for_user, " +
        "ensureExists:$ensureExists]";
  }
}

class TestTaskItemDataStruct {
  int? id;
  int? task_id;
  String? item_description;
  bool? item_complete;
  IdentSpace? idSpace;
  int min_id_for_user = TaskItemMixin.min_id_for_user;
  bool ensureExists;

  TestTaskItemDataStruct(
      {this.id,
        this.task_id,
        this.item_description,
        this.item_complete,
        this.idSpace=IdentSpace.USER_SPACE,
        this.ensureExists=true});

  @override
  String toString() {
    return "TestTaskItemDataStruct [id:$id, task_id:$task_id, item_description:$item_description, " +
        "item_complete:$item_complete, idSpace:$idSpace, min_id_for_user:$min_id_for_user, " +
        "ensureExists:$ensureExists]";
  }
}