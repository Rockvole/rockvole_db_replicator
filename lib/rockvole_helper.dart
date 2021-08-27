import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

import 'package:rockvole_db_replicator/rockvole_data.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';
import 'package:rockvole_db_replicator/src/web_services/services/MainServer.dart';

const List<String> validCommands = [
  "upgradeuser",
  "addserver",
  "changeint",
  "changestring",
  "backup",
  "restore",
  "addcategory",
  "export",
  "setserverid",
  "import",
  "liststrays",
  "purgestrays",
  "purgelogs",
  "movecat",
  "android",
  "compress",
  "clean",
  "toggleserver",
  "optimize",
  "addentry",
  "fetchfromserver",
  "runserver",
  "setuser"
];
// -------------------------------------------------- X
const int C_UPGRADE_USER = 0;
const int C_ADD_SERVER = 1;
const int C_CHANGE_INT = 2;
const int C_CHANGE_STRING = 3;
const int C_BACKUP = 4;
const int C_RESTORE = 5;
const int C_ADD_CATEGORY = 6;
const int C_EXPORT = 7;
const int C_SET_SERVER_ID = 8;
const int C_IMPORT = 9;
const int C_LIST_STRAYS = 10;
const int C_PURGE_STRAYS = 11;
const int C_PURGE_LOGS = 12;
const int C_MOVE_CATEGORY = 13;
const int C_ANDROID = 14;
const int C_COMPRESS = 15;
const int C_CLEAN = 16;
const int C_TOGGLE_SERVER = 17;
const int C_OPTIMIZE = 18;
const int C_ADD_ENTRY = 19;
const int C_FETCH_SERVER = 20;
const int C_RUN_SERVER = 21;
const int C_SET_USER = 22;

// -------------------------------------------------- Y
const String CMD = "rockvole";
const int C_MIN = 0;
const int C_MAX = 1;
List<List<int>> commandParams = [];

Future<void> main(List<String> args) async {
  File file = File('ancillary/todo_schema.yaml');
  String yamlString = file.readAsStringSync();
  YamlMap yaml = loadYaml(yamlString);
  SchemaMetaData smd = SchemaMetaData.yaml(yaml);
  smd = SchemaMetaDataTools.createSchemaMetaData(smd);
  SchemaMetaData smdSys = TransactionTools.createTrSchemaMetaData(smd);
  ConfigurationNameDefaults defaults = ConfigurationNameDefaults();
  commandParams.add([1, 2]); // C_UPGRADE_USER
  commandParams.add([1, 3]); // C_ADD_SERVER
  commandParams.add([3, 3]); // C_CHANGE_INT
  commandParams.add([5, 5]); // C_CHANGE_STRING
  commandParams.add([0, 0]); // C_BACKUP
  commandParams.add([0, 0]); // C_RESTORE
  commandParams.add([2, 2]); // C_ADD_CATEGORY
  commandParams.add([1, 3]); // C_EXPORT
  commandParams.add([1, 1]); // C_SET_SERVER_ID
  commandParams.add([1, 2]); // C_IMPORT
  commandParams.add([0, 0]); // C_LIST_STRAYS
  commandParams.add([0, 0]); // C_PURGE_STRAYS
  commandParams.add([0, 0]); // C_PURGE_LOGS
  commandParams.add([2, 2]); // C_MOVE_CATEGORY
  commandParams.add([0, 1]); // C_ANDROID
  commandParams.add([0, 0]); // C_COMPRESS
  commandParams.add([0, 0]); // C_CLEAN
  commandParams.add([0, 0]); // C_TOGGLE_SERVER
  commandParams.add([0, 0]); // C_OPTIMIZE
  commandParams.add([1, 2]); // C_ADD_ENTRY
  commandParams.add([0, 1]); // C_FETCH_SERVER
  commandParams.add([0, 1]); // C_RUN_SERVER
  commandParams.add([0, 4]); // C_SET_USER

  ConfigurationNameStruct? configurationName;
  bool shownSyntax = false;
  DbTransaction transaction;
  WardenType? wardenType;
  int? valueNumber;
  late String location;
  SortOrderType sortOrderType = SortOrderType.PRIMARY_KEY_ASC;
  print('');

  if (args.length > 0) {
    int numArgs = args.length - 1;
    switch (validCommands.indexOf(args[0])) {
      case C_UPGRADE_USER:
        if (!isCorrectParameterCount(C_UPGRADE_USER, args)) {
          showUpgradeUserSyntax();
          shownSyntax = true;
          break;
        }
        if (numArgs == 1) {
          if (!args[1].contains("@")) {
            print("No E-Mail address supplied");
            showUpgradeUserSyntax();
            shownSyntax = true;
            break;
          }
          await DataBaseFunctions.alterUser(args[1], WardenType.ADMIN, smd,
              DataBaseHelper.C_DEFAULT_DATABASE);
        }
        if (numArgs == 2) {
          if (!args[2].contains("@")) {
            print("No E-Mail address supplied");
            showUpgradeUserSyntax();
            shownSyntax = true;
            break;
          }
          await DataBaseFunctions.alterUser(
              args[2], WardenType.ADMIN, smd, args[1]);
        }
        break;
      case C_ADD_SERVER:
        if (!isCorrectParameterCount(C_ADD_SERVER, args) || numArgs<2) {
          showAddServerSyntax();
          shownSyntax = true;
          break;
        }
        wardenType = parseWardenType(args[2]);
        if (wardenType == null) {
          showAddServerSyntax();
          shownSyntax = true;
          break;
        }
        transaction = await DataBaseHelper.getDbTransaction(
            DataBaseHelper.C_DEFAULT_DATABASE);
        await ServerHelper.initializeConfiguration(
            wardenType, smd, smdSys, transaction, defaults);
        if (numArgs == 2) {
          await ServerHelper.addServer(
              args[1], wardenType, smd, smdSys, transaction);
        } else {
          await ServerHelper.addServerByDbName(
              args[1], wardenType, smd, smdSys, args[3]);
        }
        break;
      case C_CHANGE_INT:
        if (!isCorrectParameterCount(C_CHANGE_INT, args)) {
          showChangeIntSyntax();
          shownSyntax = true;
          break;
        }
        wardenType = parseWardenType(args[1]);
        if (wardenType == null) {
          showChangeIntSyntax();
          shownSyntax = true;
          break;
        }
        try {
          configurationName =
              defaults.getConfigurationNameStructFromName(args[2]);
        } on RangeError {
          showChangeIntSyntax();
          showPermittedConfigValues(defaults);
          break;
        }
        try {
          valueNumber = int.parse(args[3]);
        } on FormatException {
          showChangeIntSyntax();
          print("Invalid <number> ${args[3]}");
          break;
        }
        try {
          await DataBaseFunctions.updateConfiguration(
              wardenType,
              configurationName!.configurationNameEnum,
              null,
              valueNumber,
              null,
              true,
              smd,
              smdSys,
              DataBaseHelper.C_DEFAULT_DATABASE,
              defaults);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
            print("Error updating configuration");
        }
        break;
      case C_CHANGE_STRING:
        if (!isCorrectParameterCount(C_CHANGE_STRING, args)) {
          showChangeStringSyntax();
          shownSyntax = true;
          break;
        }
        int ordinal = int.parse(args[2]);
        wardenType = parseWardenType(args[1]);
        if (wardenType == null) {
          showChangeIntSyntax();
          shownSyntax = true;
          break;
        }
        try {
          configurationName =
              defaults.getConfigurationNameStructFromName(args[3]);
        } on RangeError {
          showChangeStringSyntax();
          showPermittedConfigValues(defaults);
          break;
        }
        if (args[4] != "null") {
          try {
            valueNumber = int.parse(args[4]);
          } on FormatException {
            showChangeStringSyntax();
            print("Invalid <number> ${args[4]}");
            break;
          }
        } else
          valueNumber = null;
        try {
          await DataBaseFunctions.updateConfiguration(
              wardenType,
              configurationName!.configurationNameEnum,
              ordinal,
              valueNumber,
              args[5],
              true,
              smd,
              smdSys,
              DataBaseHelper.C_DEFAULT_DATABASE,
              defaults);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
            print("Error updating configuration");
        }
        break;
      case C_BACKUP:
        if (!isCorrectParameterCount(C_BACKUP, args)) {
          showBackupSyntax();
          shownSyntax = true;
          break;
        }
        await BackupHelper.backupSystem(smd, smdSys);
        break;
      case C_RESTORE:
        if (!isCorrectParameterCount(C_RESTORE, args)) {
          showRestoreSyntax();
          shownSyntax = true;
          break;
        }
        await BackupHelper.restoreSystem(smd, smdSys);
        break;
      case C_EXPORT:
        if (!isCorrectParameterCount(C_EXPORT, args)) {
          showExportSyntax();
          shownSyntax = true;
          break;
        }
        if (args[2] == "ALPHA") {
          sortOrderType = SortOrderType.COLUMN_ASC;
        } else if (args[2] == "ID") {
          sortOrderType = SortOrderType.PRIMARY_KEY_ASC;
        } else {
          showExportSyntax();
          shownSyntax = true;
          break;
        }
        if (numArgs == 3) {
          location = args[3];
        }
        bool fullExport;
        if (args[1] == "FULL") {
          if (numArgs == 2) location = BackupHelper.C_EXPORT_LOCATION_FULL;
          fullExport = true;
        } else if (args[1] == "INCREMENTAL") {
          if (numArgs == 2) location = BackupHelper.C_EXPORT_LOCATION_INC;
          fullExport = false;
        } else {
          showExportSyntax();
          shownSyntax = true;
          break;
        }
        await BackupHelper.exportDataBase(
            fullExport, sortOrderType, location, smd, smdSys);
        break;
      case C_IMPORT:
        if (!isCorrectParameterCount(C_IMPORT, args)) {
          showImportSyntax();
          shownSyntax = true;
          break;
        }
        if (numArgs == 2) {
          location = args[2];
        }
        bool fullImport;
        if (args[1] == "FULL") {
          fullImport = true;
        } else if (args[1] == "INCREMENTAL") {
          fullImport = false;
        } else {
          showImportSyntax();
          shownSyntax = true;
          break;
        }
        await BackupHelper.importDataBase(fullImport, location, smd, smdSys);
        break;
      case C_SET_SERVER_ID:
        if (!isCorrectParameterCount(C_SET_SERVER_ID, args)) {
          showSetServerIdSyntax();
          shownSyntax = true;
          break;
        }
        int currentUserId;
        try {
          currentUserId = int.parse(args[1]);
        } on FormatException {
          showSetServerIdSyntax();
          print("Invalid <USER-ID> ${args[1]}");
          break;
        }
        transaction = await DataBaseHelper.getDbTransaction(
            DataBaseHelper.C_DEFAULT_DATABASE);
        await ServerHelper.setServerUserId(currentUserId, smd, transaction);
        await transaction.connection.close();
        await transaction.endTransaction();
        await transaction.closePool();
        break;
      case C_LIST_STRAYS:
        if (!isCorrectParameterCount(C_LIST_STRAYS, args)) {
          showListStraysSyntax();
          shownSyntax = true;
          break;
        }
        await DataBaseFunctions.listStrays(false, smdSys);
        break;
      case C_PURGE_STRAYS:
        if (!isCorrectParameterCount(C_PURGE_STRAYS, args)) {
          showPurgeStraysSyntax();
          shownSyntax = true;
          break;
        }
        await DataBaseFunctions.listStrays(true, smdSys);
        break;
      case C_PURGE_LOGS:
        if (!isCorrectParameterCount(C_PURGE_LOGS, args)) {
          showPurgeLogsSyntax();
          shownSyntax = true;
          break;
        }
        await DataBaseFunctions.purgeLogs(36);
        break;

      case C_ANDROID:
        if (!isCorrectParameterCount(C_ANDROID, args)) {
          showAndroidSyntax();
          shownSyntax = true;
          break;
        }
        if (numArgs == 1) {
          location = args[1];
        }
        await BackupHelper.createAndroidDatabase(
            location, smd, smdSys, defaults);
        break;
      case C_COMPRESS:
        if (!isCorrectParameterCount(C_COMPRESS, args)) {
          showCompressSyntax();
          shownSyntax = true;
          break;
        }
        transaction = await DataBaseHelper.getDbTransaction(
            DataBaseHelper.C_DEFAULT_DATABASE);
        await CompressTimeStamps.compressTimeStamps(smdSys, transaction);
        break;
      case C_CLEAN:
        if (!isCorrectParameterCount(C_CLEAN, args)) {
          showCleanSyntax();
          shownSyntax = true;
          break;
        }
        await DataBaseFunctions.clean(smd, smdSys);
        break;
      case C_TOGGLE_SERVER:
        if (!isCorrectParameterCount(C_TOGGLE_SERVER, args)) {
          showToggleServer();
          shownSyntax = true;
          break;
        }
        await DataBaseFunctions.toggleServer(smd, defaults);
        break;
      /*
      case C_OPTIMIZE:
        if(!isCorrectParameterCount(C_OPTIMIZE, args)) {
          showOptimize();
          shownSyntax=true;
          break;
        }
        OptimizeHelper.optimizeUserStoreTr();
        break;
    */
      case C_ADD_ENTRY:
        if (!isCorrectParameterCount(C_ADD_ENTRY, args)) {
          showAddEntry();
          shownSyntax = true;
          break;
        }
        int table_id;
        try {
          table_id = int.parse(args[1]);
        } on FormatException {
          showAddEntry();
          print("Invalid <TABLE-ID> ${args[1]}");
          break;
        }
        WaterState waterState = WaterState.SERVER_APPROVED;
        if (numArgs == 2) {
          waterState = WaterStateAccess.getWaterStateFromString(args[2]);
        }

        Map<String, String> env = Platform.environment;
        await DataBaseFunctions.addEntry(
            table_id, env['RVH'], waterState, smd, smdSys);
        break;
      case C_FETCH_SERVER:
        if (!isCorrectParameterCount(C_FETCH_SERVER, args)) {
          showFetchServer();
          shownSyntax = true;
          break;
        }
        transaction = await DataBaseHelper.getDbTransaction(
            DataBaseHelper.C_DEFAULT_DATABASE);
        await ServerHelper.initializeConfiguration(
            WardenType.WRITE_SERVER, smd, smdSys, transaction, defaults);
        await transaction.connection.close();
        await transaction.endTransaction();
        await transaction.closePool();
        await MirrorHelper.fetchFromServer(smd, smdSys, defaults);
        break;
      case C_RUN_SERVER:
        if (!isCorrectParameterCount(C_FETCH_SERVER, args)) {
          showRunServer();
          shownSyntax = true;
          break;
        }
        SchemaMetaData schemaMd;
        if (numArgs == 0) {
          schemaMd = SchemaMetaData(false);
        } else {
          var file = File(args[1]);
          String yamlString = await (file.readAsString(encoding: ascii));
          YamlMap yaml = loadYaml(yamlString);
          schemaMd = SchemaMetaData.yaml(yaml);
        }
        schemaMd = SchemaMetaDataTools.createSchemaMetaData(schemaMd);
        start(schemaMd);
        break;
      case C_SET_USER:
        if (!isCorrectParameterCount(C_SET_USER, args)) {
          showSetUser();
          shownSyntax = true;
          break;
        }
        int id;
        try {
          id = int.parse(args[1]);
        } on FormatException {
          showSetUser();
          print("Invalid <ID> ${args[1]}");
          break;
        }
        wardenType = parseWardenType(args[4]);
        if (wardenType == null) {
          showSetUser();
          shownSyntax = true;
          break;
        }
        transaction = await DataBaseHelper.getDbTransaction(
            DataBaseHelper.C_DEFAULT_DATABASE);
        await CrudHelper.insertUser(
            id,
            args[3],
            0,
            wardenType,
            0,
            0,
            transaction,
            WardenType.WRITE_SERVER,
            WardenType.WRITE_SERVER,
            smd,
            smdSys);
        await CrudHelper.insertUserStore(
            id,
            args[2],
            0,
            null,
            null,
            0,
            0,
            0,
            transaction,
            WardenType.WRITE_SERVER,
            WardenType.WRITE_SERVER,
            smd,
            smdSys);
        await transaction.connection.close();
        await transaction.endTransaction();
        break;
    }
  } else {
    print("No arguments supplied");
    showSyntax();
  }
}

bool isCorrectParameterCount(int command, List<String> args) {
  int numArgs = args.length - 1;
  int min = commandParams[command][C_MIN];
  int max = commandParams[command][C_MAX];

  if (numArgs < min) {
    print("Too few arguments supplied");
    return false;
  }
  if (numArgs > max) {
    print("Too many arguments supplied");
    return false;
  }
  return true;
}

void showSyntax() {
  String pad = "-----------------------------------------------";
  print("$pad CREDENTIAL COMMANDS");
  showAddServerSyntax();
  showSetUser();
  showSetServerIdSyntax();
  showUpgradeUserSyntax();
  print("$pad SERVER COMMANDS");
  showChangeIntSyntax();
  showChangeStringSyntax();
  showToggleServer();
  showFetchServer();
  showRunServer();
  print("$pad BACKUP COMMANDS");
  showPurgeLogsSyntax();
  showListStraysSyntax();
  showPurgeStraysSyntax();
  showBackupSyntax();
  showRestoreSyntax();
  showExportSyntax();
  showImportSyntax();
  print("$pad MAINTENANCE COMMANDS");
  showAndroidSyntax();
  showCompressSyntax();
  showCleanSyntax();
  showOptimize();
  showAddEntry();
}

void showPermittedConfigValues(ConfigurationNameDefaults defaults) {
  print("Invalid <CONFIG-PARAM>");
  print("Permitted values :");
  Map<ConfigurationNameEnum, ConfigurationNameStruct> configurationNameMap =
      defaults.getConfigurationNameMap();
  int count = 1;

  configurationNameMap.values.forEach((ConfigurationNameStruct struct) {
    if (count != 1) print(", ");
    if (count % 6 == 0) print('');
    print(struct.name);
    count++;
  });
  print('');
}
// ----------------------------------------------- CREDENTIAL COMMANDS
void showAddServerSyntax() {
  print("Syntax:");
  print("$CMD addserver <E-MAIL> <TYPE> database");
  print("     (<E-MAIL> - email in user store table");
  print("     (<TYPE> is server type of READ / WRITE)");
  print("     (database is optional - if not supplied default will be used)");
  print("     NOTE: Add the server on your primary WRITE server.");
  print("           Then, insert these device details into the appropriate client by using the setuser command.");
  print("           Then, on this client, use the setserverid to make it the default id.");
}

void showSetUser() {
  print("Syntax:");
  print("$CMD setuser <ID> <E-MAIL> <PASS-KEY> <WARDEN>");
  print("     (Set user details in the user table)");
  print("     (<ID> - id in user table");
  print("     (<E-MAIL> - email in user store table");
  print("     (<PASS-KEY> - pass key in user table");
  print("     (<WARDEN> - warden in user table USER / ADMIN / WRITE / READ");
}

void showSetServerIdSyntax() {
  print("Syntax:");
  print("$CMD setserverid <USER-ID>");
  print(
      "     (<USER-ID> is the ID from the user table representing this server)");
}

void showUpgradeUserSyntax() {
  print("Syntax:");
  print("$CMD upgradeuser database email@email.com");
  print("     (database is optional - if not supplied default will be used)");
  print("     (Upgrades the user with the specified email to administrator)");
}
// ----------------------------------------------- SERVER COMMANDS
void showChangeIntSyntax() {
  print("Syntax:");
  print("$CMD changeint <TYPE> <CONFIG-PARAM> <number>");
  print("     (<TYPE> is server type of USER / ADMIN / WRITE / READ)");
  print(
      "     (<CONFIG-PARAM> is the database string corresponding to the entry)");
  print("     (changes the integer value of a configuration table entry)");
}

void showChangeStringSyntax() {
  print("Syntax:");
  print("$CMD changestring <TYPE> <ORDINAL> <CONFIG-PARAM> <number> <string>");
  print("     (<TYPE> is server type of USER / ADMIN / WRITE / READ)");
  print("     (<ORDINAL> is a number below 10)");
  print(
      "     (<CONFIG-PARAM> is the database string corresponding to the entry)");
  print("     (<number> is a number or may be null)");
  print(
      "     (changes the number and string values of a configuration table entry)");
}

void showToggleServer() {
  print("Syntax:");
  print("$CMD toggleserver");
  print("     (toggle ip address of server)");
}

void showFetchServer() {
  print("Syntax:");
  print("$CMD fetchfromserver <DATABASE>");
  print("     (Fetches data from a remote write server)");
  print(
      "     (<DATABASE> is optional - if not supplied defaults to default_db");
}

void showRunServer() {
  print("Syntax:");
  print("$CMD runserver <YAML-FILE>");
  print("     (Runs server to wait for connections)");
  print(
      "     (<YAML-FILE> points to location of yaml file for database description.");
}
// ----------------------------------------------- BACKUP COMMANDS
void showPurgeLogsSyntax() {
  print("Syntax:");
  print("$CMD purgelogs");
  print("     (purge logs in the system)");
}

void showListStraysSyntax() {
  print("Syntax:");
  print("$CMD liststrays");
  print("     (show all stray ts in the system)");
}

void showPurgeStraysSyntax() {
  print("Syntax:");
  print("$CMD purgestrays");
  print("     (purge all stray ts in the system)");
}

void showBackupSyntax() {
  print("Syntax:");
  print("$CMD backup");
  print("     (backup the database - copy each table individually)");
}

void showRestoreSyntax() {
  print("Syntax:");
  print("$CMD restore");
  print(
      "     (restore the database from backup - copy each table individually)");
}

void showExportSyntax() {
  print("Syntax:");
  print("$CMD export <TYPE> <SORT_ORDER> <DIRECTORY>");
  print("     (<TYPE> is the export type FULL / INCREMENTAL)");
  print("     (<SORT_ORDER> ID or ALPHA for alphabetic sort");
  print("     (optional <DIRECTORY> location to store files");
  print("     (export the database to csv - walk through water_line table)");
}

void showImportSyntax() {
  print("Syntax:");
  print("$CMD import <TYPE> <LOCATION>");
  print("     (<TYPE> is the import type FULL / INCREMENTAL)");
  print("     (optional <LOCATION> is the directory to import from)");
  print("     (import the database to csv - walk through water_line table)");
}
// ----------------------------------------------- MAINTENANCE COMMANDS
void showAndroidSyntax() {
  print("Syntax:");
  print("$CMD android <LOCATION>");
  print("     (optional <LOCATION> is the directory to put food.db -");
  print("      if not supplied writes to the current directory)");
}

void showCompressSyntax() {
  print("Syntax:");
  print("$CMD compress");
  print("     (compress the database timestamps to small values)");
}

void showCleanSyntax() {
  print("Syntax:");
  print("$CMD clean");
  print("     (clean the database of duplicate errors)");
}

void showOptimize() {
  print("Syntax:");
  print("$CMD optimize");
  print("     (optimize database HC tables)");
}

void showAddEntry() {
  print("Syntax:");
  print("$CMD addentry <TABLE_ID> \"<CSV>\" <WATER_STATE>");
  print("     (Add an entry to the database)");
  print(
      "     (Optional <WATER_STATE> is the water_line_state to insert, e.g. SERVER_PENDING");
}

WardenType? parseWardenType(String wardenString) {
  WardenType? wardenType;

  if (wardenString.toLowerCase() == "write") {
    wardenType = WardenType.WRITE_SERVER;
  } else if (wardenString.toLowerCase() == "read") {
    wardenType = WardenType.READ_SERVER;
  } else if (wardenString.toLowerCase() == "admin") {
    wardenType = WardenType.ADMIN;
  } else if (wardenString.toLowerCase() == "user") {
    wardenType = WardenType.USER;
  }
  return wardenType;
}
