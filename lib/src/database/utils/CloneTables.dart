import 'dart:io';
import 'package:csv/csv.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';

class CloneTables {
  SchemaMetaData smd;

  CloneTables(this.smd) {
    if(smd==null) throw ArgumentError("SchemaMetaData must not be null");
  }

  Future<void> cloneTable(int table_id, DbTransaction importDatabase, DbTransaction exportDatabase) async {
    if(importDatabase==null) throw ArgumentError("importDatabase must not be null");
    if(exportDatabase==null) throw ArgumentError("exportDatabase must not be null");
    AbstractDao importDao = GenericDao(smd, importDatabase);
    await importDao.init(table_id: table_id);
    AbstractDao exportDao = GenericDao(smd, exportDatabase);
    await exportDao.init(table_id: table_id);

    FieldData fieldData=smd.getTableByTableId(table_id).getSelectFieldData(table_id);
    RawTableData rtd=await importDao.select(fieldData, WhereData());
    List<RawRowData> list=rtd.getRawRows();
    list.forEach((RawRowData rrd) async {
      await exportDao.insert(rrd.getFieldData(field_table_id: table_id));
    });
  }

  Future<void> cloneTableToFile(int table_id, DbTransaction importDatabase, String exportFileName) async {
    if(importDatabase==null) throw ArgumentError("importDatabase must not be null");
    AbstractDao importDao = GenericDao(smd, importDatabase);
    await importDao.init(table_id: table_id);

    FieldData fieldData=smd.getTableByTableId(table_id).getSelectFieldData(table_id);
    RawTableData rtd=await importDao.select(fieldData, WhereData());
    List<RawRowData> list=rtd.getRawRows();
    List<List<dynamic>> csvList=[];
    list.forEach((RawRowData rrd) async {
      csvList.add(rrd.getFieldData(field_table_id: table_id).toList());
    });
    String csv = ListToCsvConverter().convert(csvList);
    File file=File(exportFileName);
    file.writeAsStringSync('$csv');
  }

  Future<void> cloneFileToTable(int table_id, String importFileName, DbTransaction exportDatabase ) async {
    if(exportDatabase==null) throw ArgumentError("exportDatabase must not be null");
    AbstractDao importDao = GenericDao(smd, exportDatabase);
    await importDao.init(table_id: table_id);

    File file = File(importFileName);
    if (await file.exists()) {
      String content = file.readAsStringSync();
      List<List<dynamic>> rowList = const CsvToListConverter()
          .convert(content, fieldDelimiter: '|', eol: '\n');
      Iterator<dynamic> rowIter = rowList.iterator;
      GenericDao genericDao=GenericDao(smd, exportDatabase);
      await genericDao.init(table_id: table_id, initTable: true);
      while (rowIter.moveNext()) {
        List<dynamic> list = rowIter.current;
        TableMetaData tmd = smd.getTableByTableId(table_id);
        FieldData fieldData=tmd.getSelectFieldData(table_id);
        fieldData.setFieldDataValuesList=list;
        await genericDao.insert(fieldData);
      }
    }
  }

  Future<void> cloneAllTable(DbTransaction importDatabase, DbTransaction exportDatabase) async {
    List<TableMetaData> list = smd.getTableMetaDataList();
    Iterator<TableMetaData> iter = list.iterator;
    while(iter.moveNext()) {
      TableMetaData tmd = iter.current;
      await cloneTable(tmd.table_id, importDatabase, exportDatabase);
    }
  }

  Future<void> cloneAllTableToFile(DbTransaction importDatabase, String exportFileName) async {
    List<TableMetaData> list = smd.getTableMetaDataList();
    Iterator<TableMetaData> iter = list.iterator;
    while(iter.moveNext()) {
      TableMetaData tmd = iter.current;
      await cloneTableToFile(tmd.table_id, importDatabase, exportFileName);
    }
  }

  Future<void> cloneAllFileToTable(String importFileName, DbTransaction exportDatabase) async {
    List<TableMetaData> list = smd.getTableMetaDataList();
    Iterator<TableMetaData> iter = list.iterator;
    while(iter.moveNext()) {
      TableMetaData tmd = iter.current;
      await cloneFileToTable(tmd.table_id, importFileName, exportDatabase);
    }
  }

}