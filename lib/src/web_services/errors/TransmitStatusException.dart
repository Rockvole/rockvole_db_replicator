import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class TransmitStatusException implements Exception {
  TransmitStatus? transmitStatus;
  RemoteStatus? remoteStatus;
  String? cause;
  String? sourceName;

  TransmitStatusException(this.transmitStatus, {this.remoteStatus, this.cause, this.sourceName}) {
    if(transmitStatus==null) {
      cause=TransmitStatusDto.getDefaultMessage(TransmitStatus.SERVER_NOT_FOUND);
      transmitStatus=TransmitStatus.SERVER_NOT_FOUND;
    }
    if(remoteStatus!=null) transmitStatus=TransmitStatus.REMOTE_STATE_ERROR;
    if(cause==null) cause=TransmitStatusDto.getDefaultMessage(transmitStatus);
  }

  @override
  String toString() {
    return "TransmitStatusException{" +
        "transmitStatus=$transmitStatus" +
        ", remoteStatus=$remoteStatus" +
        ", sourceName='$sourceName'" +
        '}';
  }
}

