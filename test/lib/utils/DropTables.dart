import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

import '../../rockvole_test.dart';

class DropTables {
  DbTransaction transaction;

  DropTables(this.transaction);

  Future<void> dropTable(int table_id, SchemaMetaData smd) async {
    try {
      GenericDao genericDao = GenericDao(smd, transaction);
      await genericDao.init(table_id: table_id, initTable: false);
      await genericDao.dropTable();
    } on SqlException catch(e) {
      if(e.sqlExceptionEnum!=SqlExceptionEnum.TABLE_NOT_FOUND) rethrow;
    }
  }

  Future<void> dropAll(SchemaMetaData smd) async {
    await dropSome(true, smd);
  }

  Future<void> dropTrAll(SchemaMetaData smdSys) async {
    await dropTrSome(true, smdSys);
  }

  Future<void> dropSome(bool dropUser, SchemaMetaData smd) async {
    await dropTable(ConfigurationMixin.C_TABLE_ID, smd);
    await dropTable(TaskMixin.C_TABLE_ID, smd);
    await dropTable(TaskItemMixin.C_TABLE_ID, smd);
    if (dropUser) {
      await dropTable(UserMixin.C_TABLE_ID, smd);
      await dropTable(UserStoreMixin.C_TABLE_ID, smd);
    }
  }

  Future<void> dropTrSome(bool dropUser, SchemaMetaData smdSys) async {
    await dropTable(ConfigurationMixin.C_TABLE_ID, smdSys);
    await dropTable(TaskMixin.C_TABLE_ID, smdSys);
    await dropTable(TaskItemMixin.C_TABLE_ID, smdSys);
    if (dropUser) {
      await dropTable(UserMixin.C_TABLE_ID, smdSys);
      await dropTable(UserStoreMixin.C_TABLE_ID, smdSys);
    }
    await dropTable(WaterLineDto.C_TABLE_ID, smdSys);
    await dropTable(WaterLineFieldDto.C_TABLE_ID, smdSys);
  }
}
