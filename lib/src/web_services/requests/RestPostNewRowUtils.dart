import 'dart:io';
import 'dart:convert';
import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class RestPostNewRowUtils extends AbstractRestUtils {

  RestPostNewRowUtils(WardenType? localWardenType,
      WardenType? remoteWardenType,
      SchemaMetaData smd,
      SchemaMetaData smdSys,
      DbTransaction transaction,
      UserTools userTools,
      ConfigurationNameDefaults defaults)
      : super.sep(
      localWardenType,
      remoteWardenType,
      smd,
      smdSys,
      transaction,
      userTools,
      defaults);

  Future<EntryReceivedDto?> sendRemoteDtoToServer(RemoteDto remoteDto,
      int version, {String? serverDatabase, String? testPassword}) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    Map<String, String> params = Map();
    Map<String, dynamic> tableData;
    EntryReceivedDto? entryReceivedDto;
    try {
      tableData = JsonRemoteDtoTools.getJsonObjectFromRemoteDto(remoteDto, defaults);
      // Now send one record at a time
      UserStoreDto? userStoreDto = await userTools.getCurrentUserStoreDto(smd, transaction);
      UserDto? userDto = await userTools.getCurrentUserDto(smd, transaction);
      signedRequestHelper = SignedRequestHelper2(
          userStoreDto!.email!,
          userDto!.pass_key!);
      params["ts"] = TimeUtils.getNowCustomTs().toString();
      params["version"] = version.toString();

      if (serverDatabase != null) params["database"] = serverDatabase;
      if (testPassword != null) params["test_pass"] = testPassword;
      params["user_id"] =
          (await userTools.getCurrentUserId(smd, transaction)).toString();

      String jsonResponseString;
      try {
        jsonResponseString = await writeClient.postBaseURI(jsonEncode(tableData),
            UrlTools.C_NEW_ROW_POST_URL, signedRequestHelper.sign(params));
      } on TransmitStatusException catch (e) {
        print("WS $e");
        throw TransmitStatusException(
            e.transmitStatus, cause: e.cause, sourceName: "Send Rows");
      }
      late RemoteDto returnedRemoteDto;
      try {
        returnedRemoteDto =
            JsonRemoteDtoTools.getRemoteDtoFromJsonString(jsonResponseString, smdSys, defaults);
        if (returnedRemoteDto.water_table_name == "remote_state") {
          RemoteStatusDto remoteState = returnedRemoteDto as RemoteStatusDto;
          print("State=$remoteState");
          throw TransmitStatusException(
              null, remoteStatus: remoteState.status,
              cause: remoteState.message,
              sourceName: "Send Rows");
        }
      } on RemoteStatusException catch (e) {
        WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
        await waterLineDao.init();
        switch (e.remoteStatus) {
          case RemoteStatus.DUPLICATE_ENTRY:
            try {
              await waterLineDao.updateWaterLine(
                  remoteDto.waterLineDto!.water_ts!, null, WaterState.CLIENT_SENT,
                  WaterError.NONE);
            } on SqlException catch (e) {
              throw TransmitStatusException(
                  null, remoteStatus: RemoteStatus.DUPLICATE_ENTRY,
                  cause: e.cause,
                  sourceName: "Send Rows");
            }
            break;
          default:
            throw TransmitStatusException(
                null, remoteStatus: e.remoteStatus,
                cause: e.cause,
                sourceName: "Send Rows");
        }
      }
      if (returnedRemoteDto.water_table_name == "entry_received") {
        entryReceivedDto = returnedRemoteDto as EntryReceivedDto;
      } else {
        throw TransmitStatusException(
            null, cause: "Unknown remoteDto $returnedRemoteDto");
      }
      await updateOriginalRecordsFromEntryReceivedDto(entryReceivedDto);
      sleep(const Duration(seconds: 2));
    } on ArgumentError catch (e) {
      print("WS $e");
    }
    return entryReceivedDto;
  }

  Future<void> updateOriginalRecordsFromEntryReceivedDto(
      EntryReceivedDto entryReceivedDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    try {
      await waterLineDao.setStates(
          entryReceivedDto.original_ts!, WaterState.CLIENT_SENT, null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        print("WS $e");
      }
    }
    if (entryReceivedDto.original_id != entryReceivedDto.new_id) {
      print("Modify: $entryReceivedDto");
      TransactionsFactory transactionsFactory = TransactionsFactory(
          localWardenType, remoteWardenType, smd, smdSys, transaction);
      AbstractTableTransactions tableTransactions = await transactionsFactory
          .getTransactionsFromWaterLineTs(entryReceivedDto.original_ts!);
      await tableTransactions.init(localWardenType, remoteWardenType, smd, smdSys, transaction);
      try {
        await tableTransactions.modifyId(
            entryReceivedDto.original_id!, entryReceivedDto.new_id!);
        await tableTransactions.modifyJoinIds(
            entryReceivedDto.original_id!, entryReceivedDto.new_id!);
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) print(
            "WS $e");
      }
    }
  }
}
