import 'package:rockvole_db_replicator/rockvole_web_services.dart';

enum TransmitStatus {
  REMOTE_STATE_ERROR,
  SERVER_NOT_FOUND,
  NO_NEW_RECORDS_FOUND,
  RECORDS_REMAINING,
  DOWNLOAD_STARTED,
  DOWNLOAD_COMPLETE,
  DOWNLOAD_STOPPED,
  USER_NOT_REGISTERED,
  UPLOAD_STARTED,
  UPLOAD_COMPLETE,
  USER_UPDATED,
  WIFI_NOT_FOUND,
  UPDATE_STARTED,
  UPDATE_COMPLETE,
  NO_DATA_CONNECTION,
  SOCKET_TIMEOUT,
  PARSE_ERROR,
  RESOURCE_NOT_FOUND,
  INVALID_SERVER_REQUEST
}

class TransmitStatusDto {
  TransmitStatus? _transmitStatus;
  RemoteStatus? _remoteStatus;
  String? message;
  int? completedRecords;
  int? totalRecords;
  bool? userInitiated;
  late bool isDeterminate;

  TransmitStatusDto(TransmitStatus? status,
      {String? message,
      int? completedRecords,
      int? totalRecords,
      bool? userInitiated}) {
    this._transmitStatus = status;
    if (message == null)
      this.message = getDefaultMessage(status);
    else
      this.message = message;
    this.completedRecords = completedRecords;
    this.totalRecords = totalRecords;
    this.userInitiated = userInitiated;
    this.isDeterminate = true;
  }

  set remoteStatus(RemoteStatus? remoteStatus) {
    _transmitStatus = TransmitStatus.REMOTE_STATE_ERROR;
    _remoteStatus = remoteStatus;
    message = RemoteStatusDto.getDefaultMessage(remoteStatus);
  }

  RemoteStatus? get remoteStatus => _remoteStatus;

  set transmitStatus(TransmitStatus? transmitStatus) {
    _transmitStatus = transmitStatus;
    this.message = getDefaultMessage(transmitStatus);
  }

  TransmitStatus? get transmitStatus => _transmitStatus;

  static TransmitStatus? getTransmitStatusType(int? transmitStatus) {
    switch (transmitStatus) {
      case 0:
        return TransmitStatus.REMOTE_STATE_ERROR;
      case 1:
        return TransmitStatus.SERVER_NOT_FOUND;
      case 2:
        return TransmitStatus.NO_NEW_RECORDS_FOUND;
      case 3:
        return TransmitStatus.RECORDS_REMAINING;
      case 4:
        return TransmitStatus.DOWNLOAD_STARTED;
      case 5:
        return TransmitStatus.DOWNLOAD_COMPLETE;
      case 6:
        return TransmitStatus.DOWNLOAD_STOPPED;
      case 7:
        return TransmitStatus.USER_NOT_REGISTERED;
      case 8:
        return TransmitStatus.UPLOAD_STARTED;
      case 9:
        return TransmitStatus.UPLOAD_COMPLETE;
      case 10:
        return TransmitStatus.USER_UPDATED;
      case 11:
        return TransmitStatus.WIFI_NOT_FOUND;
      case 12:
        return TransmitStatus.UPDATE_STARTED;
      case 13:
        return TransmitStatus.UPDATE_COMPLETE;
      case 14:
        return TransmitStatus.NO_DATA_CONNECTION;
      case 15:
        return TransmitStatus.SOCKET_TIMEOUT;
      case 16:
        return TransmitStatus.PARSE_ERROR;
      case 17:
        return TransmitStatus.RESOURCE_NOT_FOUND;
      case 18:
        return TransmitStatus.INVALID_SERVER_REQUEST;
    }
    return null;
  }

  static int? getTransmitStatusValue(TransmitStatus? status) {
    switch (status) {
      case TransmitStatus.REMOTE_STATE_ERROR:
        return 0;
      case TransmitStatus.SERVER_NOT_FOUND:
        return 1;
      case TransmitStatus.NO_NEW_RECORDS_FOUND:
        return 2;
      case TransmitStatus.RECORDS_REMAINING:
        return 3;
      case TransmitStatus.DOWNLOAD_STARTED:
        return 4;
      case TransmitStatus.DOWNLOAD_COMPLETE:
        return 5;
      case TransmitStatus.DOWNLOAD_STOPPED:
        return 6;
      case TransmitStatus.USER_NOT_REGISTERED:
        return 7;
      case TransmitStatus.UPLOAD_STARTED:
        return 8;
      case TransmitStatus.UPLOAD_COMPLETE:
        return 9;
      case TransmitStatus.USER_UPDATED:
        return 10;
      case TransmitStatus.WIFI_NOT_FOUND:
        return 11;
      case TransmitStatus.UPDATE_STARTED:
        return 12;
      case TransmitStatus.UPDATE_COMPLETE:
        return 13;
      case TransmitStatus.NO_DATA_CONNECTION:
        return 14;
      case TransmitStatus.SOCKET_TIMEOUT:
        return 15;
      case TransmitStatus.PARSE_ERROR:
        return 16;
      case TransmitStatus.RESOURCE_NOT_FOUND:
        return 17;
      case TransmitStatus.INVALID_SERVER_REQUEST:
        return 18;
    }
    return null;
  }

  static String? getDefaultMessage(TransmitStatus? localStatus) {
    switch (localStatus) {
      case TransmitStatus.DOWNLOAD_STARTED:
        return "Download Started ...";
      case TransmitStatus.DOWNLOAD_COMPLETE:
        return "All records downloaded";
      case TransmitStatus.UPLOAD_STARTED:
        return "Sending ...";
      case TransmitStatus.UPLOAD_COMPLETE:
        return "All records sent";
      case TransmitStatus.UPDATE_STARTED:
        return "Updating ...";
      case TransmitStatus.UPDATE_COMPLETE:
        return "Update Complete";
      case TransmitStatus.DOWNLOAD_STOPPED:
        return "Download stopped";
      case TransmitStatus.NO_NEW_RECORDS_FOUND:
        return "No records to download";
      case TransmitStatus.RECORDS_REMAINING:
        return "x records to download";
      case TransmitStatus.REMOTE_STATE_ERROR:
        return "remote state error";
      case TransmitStatus.SERVER_NOT_FOUND:
        return "Server was not found";
      case TransmitStatus.PARSE_ERROR:
        return "Cannot parse remote response";
      case TransmitStatus.USER_NOT_REGISTERED:
        return "User not registered";
      case TransmitStatus.USER_UPDATED:
        return "User Updated";
      case TransmitStatus.WIFI_NOT_FOUND:
        return "Wi-Fi connection was not found";
      case TransmitStatus.NO_DATA_CONNECTION:
        return "No Data Connection available";
      case TransmitStatus.SOCKET_TIMEOUT:
        return "Connection Timeout";
      case TransmitStatus.RESOURCE_NOT_FOUND:
        return "Resource not found";
      case TransmitStatus.INVALID_SERVER_REQUEST:
        return "Invalid server request";
    }
    return null;
  }

  @override
  String toString() {
    return "TransmitStatusDto{" +
        "transmitStatus=$transmitStatus" +
        ", remoteStatus=$remoteStatus" +
        ", message='$message'" +
        ", userInitiated=$userInitiated" +
        ", completedRecords=$completedRecords" +
        ", totalRecords=$totalRecords" +
        ", isDeterminate=$isDeterminate" +
        '}';
  }
}
