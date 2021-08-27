import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_transactions.dart';

enum RemoteStatus {
  AUTHENTICATION_FAILED,
  EMAIL_MANDATORY,
  EMAIL_ALREADY_EXISTS,
  EMAIL_ADDRESS_INVALID,
  USER_ID_MANDATORY,
  TS_MANDATORY,
  USER_NOT_FOUND,
  INVALID_TEST_MODE,
  VERSION_NOT_MATCH,
  CRC_MANDATORY,
  SERVER_NOT_DEFINED,
  INVALID_SERVER_TYPE,
  FRESH_PASSKEY,
  EXPECTED_PASSKEY,
  CLIENT_PARSE_ERROR,
  WATER_LINE_MANDATORY,
  WATER_LINE_FIELD_MANDATORY,
  CHANGE_SUPER_TYPE_MANDATORY,
  COUNTRY_MANDATORY,
  INVALID_COUNTRY,
  STATE_MANDATORY,
  INVALID_STATE,
  STATE_OUT_OF_BOUNDS,
  WRONG_USER_ID,
  ILLEGAL_TABLE,
  DUPLICATE_ENTRY,
  CUSTOM_ERROR,
  DATABASE_ACCESS_ERROR,

  PROCESSED_OK,
  PROCESSED_COMPLETE,
  LAST_ENTRY_REACHED
}

class RemoteStatusDto extends RemoteDto {
  static const int C_TABLE_ID = 30;
  static const String TABLE_NAME='remote_state';
  RemoteStatus? status;
  String? message;

  RemoteStatusDto.sep(SchemaMetaData smdSys, {RemoteStatus? status, String? message}) {
    this.smdSys = smdSys;
    trDto = TrDto.wee(C_TABLE_ID);

    waterLineDto = WaterLineDto.sep(null, null, null, C_TABLE_ID, smdSys);
    if (status == null) status = RemoteStatus.PROCESSED_OK;
    this.status = status;
    if (message == null)
      _setDefaultMessage(status);
    else
      this.message = message;
    super.sep(trDto, smdSys, waterLineDto: waterLineDto, water_table_id: C_TABLE_ID);
  }

  void _setDefaultMessage(RemoteStatus status) {
    message = getDefaultMessage(status);
  }

  @override
  String get water_table_name => "remote_state";

  void setStatus(RemoteStatus? status) {
    this.status = status;
  }

  RemoteStatus? getStatus() {
    return status;
  }

  void setMessage(String? message) {
    this.message = message;
  }

  String? getMessage() {
    return message;
  }

  bool isError() {
    if (getRemoteStatusValue(status)! < 500) return true;
    return false;
  }

  bool isInformation() {
    if (getRemoteStatusValue(status)! >= 500) return true;
    return false;
  }

  static RemoteStatus? getRemoteStatusType(int? status) {
    switch (status) {
      case 0:
        return RemoteStatus.AUTHENTICATION_FAILED;
      case 2:
        return RemoteStatus.EMAIL_MANDATORY;
      case 3:
        return RemoteStatus.EMAIL_ALREADY_EXISTS;
      case 4:
        return RemoteStatus.EMAIL_ADDRESS_INVALID;
      case 5:
        return RemoteStatus.USER_ID_MANDATORY;
      case 6:
        return RemoteStatus.TS_MANDATORY;
      case 7:
        return RemoteStatus.USER_NOT_FOUND;
      case 8:
        return RemoteStatus.INVALID_TEST_MODE;
      case 9:
        return RemoteStatus.VERSION_NOT_MATCH;
      case 10:
        return RemoteStatus.CRC_MANDATORY;
      case 11:
        return RemoteStatus.SERVER_NOT_DEFINED;
      case 12:
        return RemoteStatus.INVALID_SERVER_TYPE;
      case 13:
        return RemoteStatus.FRESH_PASSKEY;
      case 14:
        return RemoteStatus.EXPECTED_PASSKEY;
      case 15:
        return RemoteStatus.CLIENT_PARSE_ERROR;
      case 16:
        return RemoteStatus.WATER_LINE_MANDATORY;
      case 17:
        return RemoteStatus.WATER_LINE_FIELD_MANDATORY;
      case 18:
        return RemoteStatus.CHANGE_SUPER_TYPE_MANDATORY;
      case 19:
        return RemoteStatus.COUNTRY_MANDATORY;
      case 20:
        return RemoteStatus.INVALID_COUNTRY;
      case 21:
        return RemoteStatus.STATE_MANDATORY;
      case 22:
        return RemoteStatus.INVALID_STATE;
      case 23:
        return RemoteStatus.STATE_OUT_OF_BOUNDS;
      case 24:
        return RemoteStatus.WRONG_USER_ID;
      case 25:
        return RemoteStatus.ILLEGAL_TABLE;
      case 26:
        return RemoteStatus.DUPLICATE_ENTRY;
      case 27:
        return RemoteStatus.CUSTOM_ERROR;
      case 28:
        return RemoteStatus.DATABASE_ACCESS_ERROR;
      case 500:
        return RemoteStatus.PROCESSED_OK;
      case 501:
        return RemoteStatus.PROCESSED_COMPLETE;
      case 502:
        return RemoteStatus.LAST_ENTRY_REACHED;
    }
    return null;
  }

  static int? getRemoteStatusValue(RemoteStatus? status) {
    switch (status) {
      case RemoteStatus.AUTHENTICATION_FAILED:
        return 0;
      case RemoteStatus.EMAIL_MANDATORY:
        return 2;
      case RemoteStatus.EMAIL_ALREADY_EXISTS:
        return 3;
      case RemoteStatus.EMAIL_ADDRESS_INVALID:
        return 4;
      case RemoteStatus.USER_ID_MANDATORY:
        return 5;
      case RemoteStatus.TS_MANDATORY:
        return 6;
      case RemoteStatus.USER_NOT_FOUND:
        return 7;
      case RemoteStatus.INVALID_TEST_MODE:
        return 8;
      case RemoteStatus.VERSION_NOT_MATCH:
        return 9;
      case RemoteStatus.CRC_MANDATORY:
        return 10;
      case RemoteStatus.SERVER_NOT_DEFINED:
        return 11;
      case RemoteStatus.INVALID_SERVER_TYPE:
        return 12;
      case RemoteStatus.FRESH_PASSKEY:
        return 13;
      case RemoteStatus.EXPECTED_PASSKEY:
        return 14;
      case RemoteStatus.CLIENT_PARSE_ERROR:
        return 15;
      case RemoteStatus.WATER_LINE_MANDATORY:
        return 16;
      case RemoteStatus.WATER_LINE_FIELD_MANDATORY:
        return 17;
      case RemoteStatus.CHANGE_SUPER_TYPE_MANDATORY:
        return 18;
      case RemoteStatus.COUNTRY_MANDATORY:
        return 19;
      case RemoteStatus.INVALID_COUNTRY:
        return 20;
      case RemoteStatus.STATE_MANDATORY:
        return 21;
      case RemoteStatus.INVALID_STATE:
        return 22;
      case RemoteStatus.STATE_OUT_OF_BOUNDS:
        return 23;
      case RemoteStatus.WRONG_USER_ID:
        return 24;
      case RemoteStatus.ILLEGAL_TABLE:
        return 25;
      case RemoteStatus.DUPLICATE_ENTRY:
        return 26;
      case RemoteStatus.CUSTOM_ERROR:
        return 27;
      case RemoteStatus.DATABASE_ACCESS_ERROR:
        return 28;
      case RemoteStatus.PROCESSED_OK:
        return 500;
      case RemoteStatus.PROCESSED_COMPLETE:
        return 501;
      case RemoteStatus.LAST_ENTRY_REACHED:
        return 502;
    }
    return null;
  }

  static String? getDefaultMessage(RemoteStatus? status) {
    String? message;
    switch (status) {
      case RemoteStatus.AUTHENTICATION_FAILED:
        message = "Authentication Failed";
        break;
      case RemoteStatus.CHANGE_SUPER_TYPE_MANDATORY:
        message = "Change Super Type field parameter is mandatory";
        break;
      case RemoteStatus.CLIENT_PARSE_ERROR:
        message = "Error Server cannot parse data from client";
        break;
      case RemoteStatus.COUNTRY_MANDATORY:
        message = "Country parameter is mandatory";
        break;
      case RemoteStatus.CRC_MANDATORY:
        message = "Crc parameter is mandatory";
        break;
      case RemoteStatus.CUSTOM_ERROR:
        message = "Custom Error";
        break;
      case RemoteStatus.DATABASE_ACCESS_ERROR:
        message = "Database Access Error";
        break;
      case RemoteStatus.DUPLICATE_ENTRY:
        message = "Duplicate Entry";
        break;
      case RemoteStatus.EMAIL_ADDRESS_INVALID:
        message = "E-mail address is invalid";
        break;
      case RemoteStatus.EMAIL_ALREADY_EXISTS:
        message = "E-mail address already exists";
        break;
      case RemoteStatus.EMAIL_MANDATORY:
        message = "E-mail parameter is mandatory";
        break;
      case RemoteStatus.EXPECTED_PASSKEY:
        message = "Pass Key is required";
        break;
      case RemoteStatus.FRESH_PASSKEY:
        message = "Pass Key is fresh";
        break;
      case RemoteStatus.ILLEGAL_TABLE:
        message = "Table cannot be sent";
        break;
      case RemoteStatus.INVALID_COUNTRY:
        message = "Country parameter is invalid";
        break;
      case RemoteStatus.INVALID_SERVER_TYPE:
        message = "Invalid server type";
        break;
      case RemoteStatus.INVALID_STATE:
        message = "State parameter is invalid";
        break;
      case RemoteStatus.INVALID_TEST_MODE:
        message = "Invalid Test Mode";
        break;
      case RemoteStatus.LAST_ENTRY_REACHED:
        message = "Last entry reached";
        break;
      case RemoteStatus.PROCESSED_COMPLETE:
        message = "Processing Complete";
        break;
      case RemoteStatus.PROCESSED_OK:
        message = "Processed OK";
        break;
      case RemoteStatus.SERVER_NOT_DEFINED:
        message = "Server not defined";
        break;
      case RemoteStatus.STATE_MANDATORY:
        message = "State parameter is mandatory";
        break;
      case RemoteStatus.STATE_OUT_OF_BOUNDS:
        message = "State parameter is out of bounds";
        break;
      case RemoteStatus.TS_MANDATORY:
        message = "ts parameter is mandatory";
        break;
      case RemoteStatus.USER_NOT_FOUND:
        message = "User not found";
        break;
      case RemoteStatus.USER_ID_MANDATORY:
        message = "User Id parameter is mandatory";
        break;
      case RemoteStatus.VERSION_NOT_MATCH:
        message = "Please Upgrade in the App Store.";
        break;
      case RemoteStatus.WATER_LINE_FIELD_MANDATORY:
        message = "Water Line Field parameter is mandatory";
        break;
      case RemoteStatus.WATER_LINE_MANDATORY:
        message = "Water Line parameter is mandatory";
        break;
      case RemoteStatus.WRONG_USER_ID:
        message = "User cannot change entry for another user.";
        break;
    }
    return message;
  }

  @override
  String toString() {
    return "RemoteState [status=" +
        getDefaultMessage(status).toString() +
        ", tableName=$water_table_name" +
        ", message=$message" +
        ", isError=" +
        isError().toString() +
        ", isInformation=" +
        isInformation().toString() +
        "]\n";
  }

  @override
  Map<String, dynamic> toMap({bool fullEnum=false}) {
    Map<String, dynamic> map=Map();
    map["status"]=getRemoteStatusValue(status);
    map["table_id"]=smdSys.getTableByName(water_table_name)!.table_id;
    map["message"]="'$message'";
    map["is_error"]=isError();
    map["is_information"]=isInformation();
    return map;
  }
}
