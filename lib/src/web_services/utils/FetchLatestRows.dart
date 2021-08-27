import 'dart:io';

import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class FetchLatestRows {
  WardenType _localWardenType;
  WardenType _remoteWardenType;
  SchemaMetaData _smd;
  SchemaMetaData _smdSys;
  DbTransaction _transaction;
  UserTools _userTools;
  AbstractWarden _warden;
  ConfigurationNameDefaults _defaults;

  FetchLatestRows(
      this._localWardenType,
      this._remoteWardenType,
      this._smd,
      this._smdSys,
      this._transaction,
      this._userTools,
      this._warden,
      this._defaults);

  static final int C_RETRY_ATTEMPTS = 3;
  static final int C_RETRY_WAIT_SECS = 120;

  Future<void> downloadRows(WaterState waterState) async {
    RestGetLatestRowsUtils getRows = RestGetLatestRowsUtils(
        _warden.localWardenType,
        _warden.remoteWardenType,
        _smd,
        _smdSys,
        _transaction,
        _userTools,
        _defaults);
    await getRows.init();
    List<RemoteDto> remoteDtoList;
    RemoteStatusDto remoteStatusDto;
    bool finalEntryReceived = false;
    int attempts = 0;
    try {
      do {
        remoteDtoList =
            await getRows.requestRemoteDtoListFromServer();

        remoteStatusDto = await getRows.storeRemoteDtoList(remoteDtoList);
        switch (remoteStatusDto.getStatus()) {
          case RemoteStatus.PROCESSED_OK:
            attempts = 0;
            break;
          case RemoteStatus.DATABASE_ACCESS_ERROR:
          case RemoteStatus.CLIENT_PARSE_ERROR:
            print(
                "Error communicating with server, retrying $attempts of $C_RETRY_ATTEMPTS");
            try {
              sleep(Duration(seconds: C_RETRY_WAIT_SECS));
            } on Exception catch (e1) {
              print("WS $e1");
            }
            attempts++;
            break;
          default:
            finalEntryReceived = true;
            break;
        }
        if (attempts > C_RETRY_ATTEMPTS) {
          print(
              "Giving up fetching from server after (${attempts - 1}) attempts");
          break;
        }
      } while (finalEntryReceived == false);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("WS $e");
      else
        rethrow;
    }
  }
}
