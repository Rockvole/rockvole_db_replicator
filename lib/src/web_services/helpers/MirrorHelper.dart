import 'dart:io';

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class MirrorHelper {
  static final WardenType C_LOCAL_WARDEN = WardenType.WRITE_SERVER;
  static final WardenType C_REMOTE_WARDEN = WardenType.WRITE_SERVER;
  static final int C_RETRY_ATTEMPTS = 3;
  static final int C_RETRY_WAIT_MS = 120000;

  static Future<void> fetchFromServer(SchemaMetaData smd, SchemaMetaData smdSys,
      ConfigurationNameDefaults defaults,
      {String dbName: 'default_db'}) async {
    DbTransaction transaction;
    ConfigurationDao configurationDao;
    UserTools userTools;
    AbstractWarden warden;

    int attempts = 0;
    bool complete = false;
    UserDto? currentUserDto;
    int start_ts;
    transaction = await DataBaseHelper.getDbTransaction(dbName);
    configurationDao = ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: true);
    userTools = UserTools();
    try {
      currentUserDto = await userTools.getCurrentUserDto(smd, transaction);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("This server is not defined in the user table");
      else
        rethrow;
    }
    if (currentUserDto != null) {
      do {
        start_ts = DateTime.now().millisecondsSinceEpoch;
        // Initialize configuration table
        try {
          AuthenticationDto? authenticationDto;
          try {
            authenticationDto = await authenticateUser(
                currentUserDto.warden,
                C_REMOTE_WARDEN,
                currentUserDto.pass_key,
                WaterState.SERVER_APPROVED,
                AbstractEntries.C_MINIMUM_VERSION,
                smd,
                smdSys,
                transaction,
                userTools,
                defaults);
          } on TransmitStatusException catch (e) {
            print("WS $e");
          }
          if (authenticationDto != null) {
            warden = WardenFactory.getAbstractWarden(
                currentUserDto.warden!, authenticationDto.warden!);

            FetchLatestRows fetchRows = FetchLatestRows(
                C_LOCAL_WARDEN,
                C_REMOTE_WARDEN,
                smd,
                smdSys,
                transaction,
                userTools,
                warden,
                defaults);
            await fetchRows.downloadRows(WaterState.SERVER_APPROVED);
          }
          complete = true;
        } on Exception catch (e) {
          if (e.runtimeType == TransmitStatusException ||
              (e.runtimeType == SqlException)) {
            if (e.runtimeType == SqlExceptionEnum) {
              SqlException ex = e as SqlException;
              if (ex.sqlExceptionEnum != SqlExceptionEnum.FAILED_SELECT)
                continue;
            }
            // If we had a successful run for 20s, reset attempts back to 0
            if ((start_ts + C_RETRY_WAIT_MS + 20000) >
                DateTime.now().millisecondsSinceEpoch) attempts = 0;
            attempts++;
            print(StackTrace.current);
            if (attempts < C_RETRY_ATTEMPTS) {
              complete = false;
              print(
                  "Connection error, retrying $attempts of $C_RETRY_ATTEMPTS");
              try {
                sleep(Duration(milliseconds: C_RETRY_WAIT_MS));
              } on Exception catch (e1) {
                print("WS $e1");
              }
            } else {
              complete = true;
              print("Giving up connecting after $C_RETRY_ATTEMPTS attempts");
            }
          }
        }
      } while (!complete);
    }
    await transaction.connection.close();
    await transaction.endTransaction();
    await transaction.closePool();
  }

  static Future<AuthenticationDto?> authenticateUser(
      WardenType? localWardenType,
      WardenType remoteWardenType,
      String? passKey,
      WaterState stateType,
      int version,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults) async {
    late RemoteDto remoteDto;

    RestGetAuthenticationUtils informationUtils = RestGetAuthenticationUtils(
        localWardenType,
        remoteWardenType,
        smd,
        smdSys,
        transaction,
        userTools,
        defaults,
        null);
    await informationUtils.init();
    try {
      remoteDto =
          await informationUtils.requestAuthenticationFromServer(version);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        print("WS $e");
      else
        rethrow;
    }

    AuthenticationDto? authenticationDto;
    switch (remoteDto.water_table_id) {
      case RemoteStatusDto.C_TABLE_ID:
        RemoteStatusDto remoteStatusDto = remoteDto as RemoteStatusDto;

        print("jj=" + remoteStatusDto.toString());
        break;
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        print("ww=" + authenticationDto.toString());
        break;
      default:
        print("UNKNOWN=" + remoteDto.water_table_name);
    }
    return authenticationDto;
  }
}
