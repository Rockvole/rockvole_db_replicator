import 'dart:convert';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

/**
 * Post New Rows created / updated by the user
 *
 */
class PostNewRow extends AbstractEntries {
  final String C_THIS_NAME = " POST ROW ";
  late RemoteDto remoteDto;
  late TransactionsFactory transactionsFactory;
  late AbstractWarden abstractWarden;
  ConfigurationNameDefaults defaults;

  PostNewRow(SchemaMetaData smd, this.defaults) : super(smd);

  Future<void> init() async {}

  Future<String> putEntry(int userId, int ts, int version, String? testPassword,
      String? database, String signature, String? jsonString) async {
    print(
        "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////" +
            C_THIS_NAME +
            "REQUEST");
    print(
        "PARAMS:user_id=$userId||ts=$ts||version=$version||testPassword=$testPassword||database=$database||sig=$signature");
    print("jsonString=$jsonString");
    Map<String, dynamic> tablesArray = Map();
    try {
      await validateRequest(testPassword, database);
      await validateServer();
      if (version < AbstractEntries.C_MINIMUM_VERSION) {
        throw RemoteStatusException(RemoteStatus.VERSION_NOT_MATCH);
      }
      isEmailFresh(userId);
      await validateUser(userId);

      localWardenType = localUserDto!.warden;
      if (localWardenType != WardenType.WRITE_SERVER) {
        print("Can only POST to write server");
        throw RemoteStatusException(RemoteStatus.SERVER_NOT_DEFINED,
            cause: "Can only POST to write server");
      }
      print("remoteUserStoreDto=$remoteUserStoreDto");
      // ------------------------------------------------------------ Validation Complete
      print(
          "--------------------------------------------------------------------------------------------------------------------------------" +
              C_THIS_NAME +
              "VALIDATION");
      if ((remoteUserDto.pass_key == null)) {
        throw RemoteStatusException(RemoteStatus.EXPECTED_PASSKEY);
      }
      SignedRequestHelper2 signedRequestHelper = SignedRequestHelper2(
          remoteUserStoreDto!.email!, remoteUserDto.pass_key!);
      Map<String, String> params = Map();
      params["ts"] = ts.toString();
      params["version"] = version.toString();
      params["user_id"] = remoteUserDto.id.toString();
      if (testMode) {
        if (database != null) params["database"] = database;
        params["test_pass"] = AbstractEntries.C_TEST_PASSWORD;
      }
      String generateSignature = SignedRequestHelper2.percentDecodeRfc3986(
          signedRequestHelper.getHmac(params));
      if (signature == generateSignature) {
        // Authenticated
        remoteDto = JsonRemoteDtoTools.getRemoteDtoFromJsonString(
            jsonString, smdSys, defaults);
        remoteWardenType = remoteUserDto.warden;
        if (remoteDto.water_table_id == UserMixin.C_TABLE_ID) {
          // Cannot Send User Table
          throw RemoteStatusException(RemoteStatus.ILLEGAL_TABLE);
        }
        if (remoteDto.water_table_id == UserStoreMixin.C_TABLE_ID) {
          remoteDto = currentUserUpdate(remoteDto, remoteUserDto,
              remoteUserStoreDto!, userId, transaction);
        }
        WaterLineDto? waterLineDto;
        late AbstractTableTransactions tableTransactions;
        RemoteDto? responseRemoteDto;
        EntryReceivedDto entryReceivedDto = EntryReceivedDto();
        entryReceivedDto.original_ts = remoteDto.waterLineDto!.water_ts!;
        entryReceivedDto.original_id = remoteDto.trDto.id!;
        try {
          remoteDto = autoApprove(remoteDto, remoteWardenType!);
          remoteWardenType = WardenType.WRITE_SERVER;
        } on ArgumentError {}
        print(
            "localWardenType=$localWardenType||remoteWardenType=$remoteWardenType");
        print(
            "--------------------------------------------------------------------------------------------------------------------------------" +
                C_THIS_NAME);
        abstractWarden = WardenFactory.getAbstractWarden(
            localWardenType!, remoteWardenType!);
        await abstractWarden.init(smd, smdSys, transaction);
        transactionsFactory = TransactionsFactory(
            localWardenType, remoteWardenType, smd, smdSys, transaction);

        waterLineDto = remoteDto.waterLineDto;
        if (remoteUserDto.warden == WardenType.USER ||
            waterLineDto!.water_state == WaterState.CLIENT_STORED) {
          remoteDto.trDto.set('user_id', remoteUserDto.id);
        }
        try {
          tableTransactions =
              await transactionsFactory.getTransactionsFromRemoteDto(remoteDto);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
            print("WS $e");
          } else
            rethrow;
        }
        abstractWarden.initialize(tableTransactions,
            passedWaterState: remoteDto.waterLineDto!.water_state);
        try {
          responseRemoteDto = await abstractWarden.write();
          if (responseRemoteDto!.waterLineDto!.water_error != WaterError.NONE) {
            if (responseRemoteDto.waterLineDto!.water_error !=
                WaterError.DUPLICATE_ENTRY) {
              throw RemoteStatusException(RemoteStatus.CLIENT_PARSE_ERROR);
            }
          }
          entryReceivedDto.original_table_id = responseRemoteDto.water_table_id;
          entryReceivedDto.new_id = responseRemoteDto.trDto.id!;
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY) {
            // When an entry has already been approved by an admin ignore duplicate approvals
            if (remoteUserDto.warden == WardenType.ADMIN) {
              entryReceivedDto.original_table_id = remoteDto.water_table_id;
              entryReceivedDto.new_id = remoteDto.trDto.id!;
            } else if (remoteUserDto.warden == WardenType.USER) {
              throw RemoteStatusException(RemoteStatus.DUPLICATE_ENTRY);
            }
          } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
              e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
              e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
              e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
            print("WS $e");
          else
            rethrow;
        }
        tablesArray =
            JsonRemoteDtoConversion.getJsonFromEntryReceived(entryReceivedDto);
      } else {
        // Authentication Failed
        throw RemoteStatusException(RemoteStatus.AUTHENTICATION_FAILED);
      }
      print("returnJson=$tablesArray");
    } on RemoteStatusException catch (e) {
      print(e.cause);
      return jsonEncode(JsonRemoteDtoConversion.getJsonFromRemoteState(
          RemoteStatusDto.sep(smdSys,
              status: e.remoteStatus, message: e.cause)));
    } finally {
      await endTransaction();
    }
    return jsonEncode(tablesArray);
  }

  Set<int> autoApproveTables = {};
  RemoteDto autoApprove(RemoteDto lRemoteDto, WardenType lWardenType) {
    if (lWardenType != WardenType.USER)
      throw ArgumentError("Can only Auto Approve User");
    if (lRemoteDto.trDto.operation != OperationType.INSERT)
      throw ArgumentError("Can only Auto Approve Inserts");

    if (autoApproveTables.contains(lRemoteDto.waterLineDto!.water_table_id)) {
      lRemoteDto.waterLineDto!.water_state = WaterState.SERVER_APPROVED;
      // Change ts to null so that server will use the latest ts
      lRemoteDto.trDto.ts = null;
      // Set id to null so that we generate an Id
      lRemoteDto.trDto.set('id', null);
      return lRemoteDto;
    }
    throw ArgumentError("No tables found to Approve");
  }

  // If user is changing their own user, change to admin for no approval
  RemoteDto currentUserUpdate(RemoteDto pRemoteDto, UserDto pRemoteUserDto,
      UserStoreDto pUserStoreDto, int userId, DbTransaction transaction) {
    if (remoteWardenType == WardenType.USER) {
      UserStoreDto receivedUserStoreDto =
          UserStoreDto.map(pRemoteDto.trDto.toMap());
      if (receivedUserStoreDto.id! < UserStoreMixin.min_id_for_user) {
        receivedUserStoreDto.id = userId;
      } else {
        throw RemoteStatusException(RemoteStatus.WRONG_USER_ID);
      }
      // Ensure user email address is not used by another user
      remoteWardenType = WardenType.WRITE_SERVER;
      pRemoteDto.waterLineDto!.water_state = WaterState.SERVER_APPROVED;
      // Change ts to null so that server will use the latest ts
      pRemoteDto.trDto.ts = null;
      // Force records which user is not allowed to change
      receivedUserStoreDto.email = pUserStoreDto.email;
      receivedUserStoreDto.records_downloaded =
          pUserStoreDto.records_downloaded;
      receivedUserStoreDto.changes_approved_count =
          pUserStoreDto.changes_approved_count;
      receivedUserStoreDto.changes_denied_count =
          pUserStoreDto.changes_denied_count;
      pRemoteDto.trDto.append(receivedUserStoreDto,
          field_table_id: receivedUserStoreDto.table_id);
    }
    return pRemoteDto;
  }
}
