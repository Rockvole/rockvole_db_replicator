import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

class StrayTables {
  static bool C_INITIALIZE_TABLE = false;
  static bool C_CREATE_IF_NOT_FOUND = false;
  static WardenType C_WARDEN_TYPE = WardenType.WRITE_SERVER;

  static Future<void> strayTrTable(
      int table_id,
      bool purge,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      WaterLineDao waterLineDao) async {
    GenericDao dao = GenericDao(smdSys, transaction);
    await dao.init(table_id: table_id);
    FieldData fieldData =
        smdSys.getTableByTableId(table_id).getSelectFieldData(table_id);
    RawTableData rawTableData;
    try {
      rawTableData = await dao.select(fieldData, WhereData());
      tablePresent(dao.tableName, true);
      List<RawRowData> list = rawTableData.getRawRows();
      Iterator<RawRowData> iter = list.iterator;
      while (iter.moveNext()) {
        RawRowData rawRowData = iter.current;
        int ts = rawRowData.get("ts", null) as int;
        try {
          await waterLineDao.getWaterLineDtoByTs(ts);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
            messageNotFound(dao.tableName, ts, "water_line");
            if (purge) {
              WhereData whereData = WhereData();
              whereData.set("ts", SqlOperator.EQUAL, ts);
              await dao.delete(whereData);
              messageDeleted(dao.tableName,
                  TrDto.field(rawRowData.getFieldData()));
            }
          }
        }
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND) {
        tablePresent(dao.tableName, false);
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
          e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        print("DB $e");
      }
    } finally {
      try {
        //await transaction.getConnection().close();
      } on SqlException catch (e) {
        print("DB $e");
      }
    }
  }

  static Future<void> strayWaterLine(bool purge, SchemaMetaData smdSys,
      DbTransaction transaction, WaterLineDao waterLineDao) async {
    WaterLineDao dao = WaterLineDao.sep(smdSys, transaction);
    await dao.init();
    WaterLineDto? dto;
    List<WaterLineDto>? list;
    try {
      int? currentTs = 0;
      tablePresent(dao.tableName, await dao.doesTableExist());
      do {
        list = null;
        try {
          list = await dao.getWaterLineListAboveTs(
              currentTs, null, null, null, null, 500);
        } on SqlException catch (e) {
          print("DB $e");
        }
        if (list != null) {
          Iterator<WaterLineDto> iter = list.iterator;
          while (iter.moveNext()) {
            dto = iter.current;
            currentTs = dto.water_ts;
            if (dto != null) {
              switch (dto.water_table_name) {
                case "authentication":
                case "entry_received":
                case "last_field_received":
                case "max_int":
                case "product_details":
                case "remote_state":
                case "removed":
                case "water_line":
                case "water_line_field":
                  print("Invalid table " +
                      dto.water_table_name +
                      " (" +
                      dto.water_table_id.toString() +
                      ")");
                  break;
                default:
                  GenericDao genericDao = GenericDao(smdSys, transaction);
                  await genericDao.init(table_id: dto.water_table_id);
                  FieldData fieldData = smdSys
                      .getTableByTableId(dto.water_table_id)
                      .getSelectFieldData(dto.water_table_id);
                  WhereData whereData = WhereData();
                  whereData.set("ts", SqlOperator.EQUAL, dto.water_ts,
                      table_id: dto.water_table_id);
                  try {
                    await genericDao.select(fieldData, whereData);
                  } on SqlException catch (e) {
                    if (e.sqlExceptionEnum ==
                            SqlExceptionEnum.ENTRY_NOT_FOUND ||
                        e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
                      messageNotFound(
                          "water_line", dto.water_ts!, dto.water_table_name);
                      if (purge) {
                        await waterLineDao.deleteWaterLineByTs(dto.water_ts!);
                        waterLineDeleted(dto);
                      }
                    }
                  }
              }
            }
          }
        }
      } while (list != null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.TABLE_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        tablePresent(dao.tableName, false);
      } else {
        print("DB $e");
      }
    } finally {
      await transaction.getConnection().close();
    }
  }

  static Future<void> strayAllTables(
      bool purge, SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();

    Iterator<TableMetaData> iter =
        smdSys.getTableMetaDataList(includeComms: false).iterator;
    while (iter.moveNext()) {
      TableMetaData tmd = iter.current;
      await strayTrTable(
          tmd.table_id, purge, smdSys, transaction, waterLineDao);
    }
  }

  static Future<void> strayAllWaterLine(
      bool purge, SchemaMetaData smdSys, DbTransaction transaction) async {
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    await strayWaterLine(purge, smdSys, transaction, waterLineDao);
  }

  static Future<void> showAllStrays(
      bool purge, SchemaMetaData smdSys, DbTransaction transaction) async {
    await strayAllTables(purge, smdSys, transaction);
    await strayAllWaterLine(purge, smdSys, transaction);
  }

  // --------------------------------------------------- MESSAGES
  static void messageNotFound(
      String sourceTableType, int ts, String destTableType) {
    print(DbConstants.getStringOfSize(10, character: ' ') +
        "$sourceTableType $ts not found in $destTableType");
  }

  static void messageNotFoundTmd(
      String sourceTableType, int ts, TableMetaData tableMd) {
    print(DbConstants.getStringOfSize(10, character: ' ') +
        "$sourceTableType $ts not found in " +
        tableMd.table_name);
  }

  static void messageDeleted(String sourceTableType, TrDto trDto) {
    print("$sourceTableType " + trDto.ts.toString() + " < DELETED");
    print(trDto);
  }

  static void waterLineDeleted(WaterLineDto dto) {
    print("water_line " + dto.water_ts.toString() + " < DELETED");
    print("" + dto.toString());
  }

  static void tablePresent(String tableName, bool present) {
    if (present)
      print(tableName +
          " " +
          DbConstants.getStringOfSize((60 - tableName.length), character: '-'));
    else
      print(tableName +
          " < TABLE NOT FOUND " +
          DbConstants.getStringOfSize((40 - tableName.length), character: '-'));
  }

  static void tablePresentTmd(TableMetaData tableMd, bool present) {
    String tableName = tableMd.table_name;
    if (present)
      print(tableName +
          " " +
          DbConstants.getStringOfSize((60 - tableName.length), character: '-'));
    else
      print(tableName +
          " < TABLE NOT FOUND " +
          DbConstants.getStringOfSize((40 - tableName.length), character: '-'));
  }
}
