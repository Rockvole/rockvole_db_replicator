import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class BackupHelper {
  static const String C_DATABASE_NAME = "client_db";
  static const String C_BACKUP_LOCATION = "/work/backup_full/";
  static const String C_EXPORT_LOCATION_FULL = "/work/export_full/";
  static const String C_EXPORT_LOCATION_INC = "/work/export_incremental/";
  // ----------------------------------------------------------------------------------------------------------------- BACKUP SYSTEM
  static Future<void> backupSystem(
      SchemaMetaData smd, SchemaMetaData smdSys) async {
    String ext = FileHelper.getDateString();
    DbTransaction sourceTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    DbTransaction destTransaction =
        await DataBaseHelper.getSqlite3DbTransaction(
            "latest", C_BACKUP_LOCATION + ext);
    await FileHelper.createEmptyDirectory(C_BACKUP_LOCATION + ext);

    await copySystem(smd, smdSys, sourceTransaction, destTransaction);

    await FileHelper.createSymbolicDirectory(
        C_BACKUP_LOCATION + "latest", C_BACKUP_LOCATION + ext);
    FileHelper.multipleFileTrim(C_BACKUP_LOCATION + "latest", ".csv");
    print("Backed up to " + C_BACKUP_LOCATION + ext);
    await sourceTransaction.endTransaction();
    await destTransaction.endTransaction();
  }

  // Back-up every table in the system
  static Future<void> copySystem(SchemaMetaData smd, SchemaMetaData smdSys,
      DbTransaction sourceTransaction, DbTransaction destTransaction) async {
    CloneTables cloneDataBase = CloneTables(smd);
    await cloneDataBase.cloneAllTable(sourceTransaction, destTransaction);
    CloneTables cloneDataBaseSys = CloneTables(smdSys);
    await cloneDataBaseSys.cloneAllTable(sourceTransaction, destTransaction);
  }

  // ----------------------------------------------------------------------------------------------------------------- RESTORE SYSTEM
  static Future<void> restoreSystem(
      SchemaMetaData smd, SchemaMetaData smdSys) async {
    MySqlStore poolStore = MySqlStore();
    AbstractPool pool = poolStore.getMySqlPool(C_DATABASE_NAME);
    DbTransaction dbTransaction = DbTransaction(pool);
    String importFileName = C_BACKUP_LOCATION + "latest";

    CloneTables cloneDataBase = CloneTables(smd);
    await cloneDataBase.cloneAllFileToTable(importFileName, dbTransaction);
    CloneTables cloneDataBaseSys = CloneTables(smdSys);
    await cloneDataBaseSys.cloneAllFileToTable(importFileName, dbTransaction);

    print("Restored to " + C_DATABASE_NAME + " mysql");
  }

  //------------------------------------------------------------------------------------------------------------------ IMPORT DATABASE
  // Import the database by processing each water_line entry in the system
  static Future<void> importDataBase(bool fullImport, String location,
      SchemaMetaData smd, SchemaMetaData smdSys) async {
    if (location == null) location = C_EXPORT_LOCATION_FULL;
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    DbTransaction sqliteTransaction =
        await DataBaseHelper.getSqlite3DbTransaction(location + "latest", null);
    ReplicateDataBase replicateDataBase = ReplicateDataBase(
        WardenType.WRITE_SERVER,
        WardenType.WRITE_SERVER,
        smd,
        smdSys,
        sqliteTransaction,
        mysqlTransaction,
        true);
    //replicateDataBase.minimalSet=true;
    await replicateDataBase.reproduceDataBaseAboveTs(0, null);

    print("Imported to " + C_DATABASE_NAME + " mysql");
  }

  //------------------------------------------------------------------------------------------------------------------ EXPORT DATABASE
  // Export the database by processing each water_line entry in the system
  static Future<void> exportDataBase(
      bool fullExport,
      SortOrderType sortOrderType,
      String location,
      SchemaMetaData smd,
      SchemaMetaData smdSys) async {
    int? aboveTs = 0;
    // ------------------------------------------------------------------------------------------------------------- FETCH EXISTING TS
    bool doesLatestExist = await FileHelper.doesFileExist(location + "latest");
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    DbTransaction sqliteTransaction;
    if (!fullExport && doesLatestExist) {
      // INCREMENTAL - check latest ts
      sqliteTransaction = await DataBaseHelper.getSqlite3DbTransaction(
          location + "latest", null);
      WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, sqliteTransaction);
      await waterLineDao.init(initTable: true);
      WaterLineDto waterLineDto;
      try {
        waterLineDto = await waterLineDao.getLatestWaterLineDto(null);
        aboveTs = waterLineDto.water_ts;
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
            e.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT) rethrow;
      }
      await sqliteTransaction.endTransaction();
    }
    // ------------------------------------------------------------------------------------------------------------- SET DIRECTORY NAME
    String dateStr = FileHelper.getDateString();
    String ext = dateStr;
    if (aboveTs == 0) ext = dateStr + "_tmp";
    if (await FileHelper.doesFileExist(location + ext)) {
      print("DIRECTORY ALREADY EXISTS " + location + ext);
      return;
    }
    // ------------------------------------------------------------------------------------------------------------- PERFORM EXPORT
    await FileHelper.createEmptyDirectory(location + ext);
    sqliteTransaction =
        await DataBaseHelper.getSqlite3DbTransaction(location, ext);
    ReplicateDataBase replicateDataBase = ReplicateDataBase(
        WardenType.WRITE_SERVER,
        WardenType.WRITE_SERVER,
        smd,
        smdSys,
        mysqlTransaction,
        sqliteTransaction,
        true);

    int writtenCount =
        await replicateDataBase.reproduceDataBaseAboveTs(aboveTs, null);
    await mysqlTransaction.endTransaction();
    FileHelper.multipleFileTrim(location + ext, ".csv");

    if (writtenCount == 0) {
      // Delete the empty directory we just created
      await FileHelper.deleteDirectory(location + ext);
    } else {
      if (fullExport) {
        await FileHelper.createEmptyDirectory(location + dateStr + "_full");
        DbTransaction destTransaction =
            await DataBaseHelper.getSqlite3DbTransaction(
                location, dateStr + "_full");
        await copySystem(smd, smdSys, sqliteTransaction, destTransaction);
        await sqliteTransaction.endTransaction();
        await destTransaction.endTransaction();
        FileHelper.deleteMultipleEmptyFiles(location + ext);

        await FileHelper.createSymbolicDirectory(
            location + "latest", dateStr + "_full");
        FileHelper.multipleFileTrim(location + "latest", ".csv");
        print("Exported to " + location + dateStr + "_full");
      } else {
        await FileHelper.createSymbolicDirectory(location + "latest", ext);
        FileHelper.multipleFileTrim(location + "latest", ".csv");
        print("Exported to " + location + ext);
      }
    }
    await sqliteTransaction.endTransaction();
  }

  //------------------------------------------------------------------------------------------------------------------ CREATE ANDROID
  static Future<void> createAndroidDatabase(String location, SchemaMetaData smd,
      SchemaMetaData smdSys, ConfigurationNameDefaults defaults) async {
    if (location == null) location = ".";
    WardenType localWardenType = WardenType.USER;
    WardenType remoteWardenType = WardenType.WRITE_SERVER;
    DbTransaction mysqlTransaction =
        await DataBaseHelper.getDbTransaction(C_DATABASE_NAME);
    DbTransaction sqliteTransaction =
        await DataBaseHelper.getSqlite3DbTransaction("food", location);

    // ----------------------------------------------------- REPLICATE DATABASE
    ReplicateDataBase replicateDataBase = ReplicateDataBase(
        WardenType.USER,
        WardenType.WRITE_SERVER,
        smd,
        smdSys,
        mysqlTransaction,
        sqliteTransaction,
        true);
    int writtenCount =
        await replicateDataBase.reproduceDataBaseAboveTs(0, null);

    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, sqliteTransaction);
    await waterLineDao.init();
    Set<WaterError> errorStateEnumSet =
        WaterErrorAccess.getAllOfWaterErrorSet();
    errorStateEnumSet.remove(WaterError.NONE);
    try {
      await waterLineDao.deleteWaterLine(
          null, null, null, null, errorStateEnumSet);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND &&
          e.sqlExceptionEnum != SqlExceptionEnum.TABLE_NOT_FOUND) rethrow;
    }
    ClientWarden clientWarden = ClientWarden(WardenType.USER, waterLineDao);
    await clientWarden.cleanWaterLine();
    // ----------------------------------------------------- NOW DOWNLOAD WATER_LINE_FIELD TABLES
    UserTools userTools = UserTools();
    WaterLineField waterLineField = WaterLineField(
        localWardenType, remoteWardenType, smdSys, sqliteTransaction);
    await waterLineField.init();
    //List<Integer> productIdList = waterLineField.getNotUpToDateProductIdList();
    //Iterator<Integer> iter = productIdList.iterator();
    //Integer id=null;
    //RemoteWaterLineFieldDtoPartitionTools partitionTools = RemoteWaterLineFieldDtoPartitionTools();
    //while(iter.hasNext()) {
    //id = iter.next();
    //try {
    //waterLineField.inList(id, SchemaMetaData.TableType.PRODUCT);
    //if (waterLineField.isDataAvailableToUser(id, userCountryCodeEnumSet, sqliteTransaction)) {
    //List<RemoteDto> remoteDtoList = RestRequestSelectedRowsUtils.getRemoteFieldDtoListToSend(waterLineField);
    //List<RemoteDto> tablesArray = partitionTools.retrieveJoinedRows(remoteDtoList, remoteWardenType, localWardenType, Country.CountryCode.USA, foodCategoryMap, mysqlTransaction);
    //AbstractWarden abstractWarden = ClientWardenFactory.getAbstractWarden(localWardenType, remoteWardenType, sqliteTransaction, foodCategoryMap);
    //RestGetLatestRowsUtils latestRowsUtils= RestGetLatestRowsUtils(abstractWarden, sqliteTransaction, userTools);
    //latestRowsUtils.storeRemoteDtoList(tablesArray);
    //}
    //} catch (EntryNotFoundException | FailedSelectException | FailedUpdateException e) {
    //logger.error("UI", e);
    //}
    //}
    // ------------------------------------------------ NOW UPDATE WATER_LINE_FIELD TS
    ChangeSuperType changeSuperType = ChangeSuperType.CHANGES;
    bool finalEntryReceived = false;
    List<RemoteDto> remoteDtoList;
    AbstractRemoteFieldWarden abstractRemoteFieldWarden =
        AbstractRemoteFieldWarden(
            localWardenType, remoteWardenType, smd, smdSys, mysqlTransaction);
    await abstractRemoteFieldWarden.init();
    try {
      RestGetLatestWaterLineFieldsUtils getFields =
          RestGetLatestWaterLineFieldsUtils(
              WardenType.USER,
              WardenType.READ_SERVER,
              smd,
              smdSys,
              sqliteTransaction,
              userTools,
              defaults);
      do {
        remoteDtoList =
            await abstractRemoteFieldWarden.getRemoteFieldListAboveLocalTs(
                await waterLineField.getMaxTs(changeSuperType),
                changeSuperType,
                100);
        finalEntryReceived =
            await getFields.storeWaterLineFieldsList(remoteDtoList);
      } while (!finalEntryReceived);
    } on RemoteStatusException catch (e) {
      print(e);
    } on SqlException catch (e) {
      //EntryNotFoundException e) {
      print(e);
    }
    // ----------------------------------------------------- ADD DATABASE VERSION
    await CrudHelper.insertConfiguration(
        ConfigurationNameEnum.DATABASE_VERSION,
        AbstractEntries.C_MINIMUM_VERSION,
        null,
        5000000,
        sqliteTransaction,
        WardenType.USER,
        WardenType.READ_SERVER,
        smd,
        smdSys,
        defaults);
    await sqliteTransaction.endTransaction();
    await mysqlTransaction.endTransaction();
  }
}
