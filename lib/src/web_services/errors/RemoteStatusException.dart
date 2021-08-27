import 'package:rockvole_db/src/web_services/data/RemoteStatusDto.dart';

class RemoteStatusException implements Exception {
  String? cause;
  RemoteStatus remoteStatus;
  RemoteStatusException(this.remoteStatus, {this.cause}) {
    if(cause==null) cause=RemoteStatusDto.getDefaultMessage(remoteStatus);
  }

  @override
  String toString() {
    String SEP="\n";
    StringBuffer sb=StringBuffer();
    sb.write("----------------------------------- $remoteStatus"+SEP);
    sb.write("cause: $cause"+SEP);
    return sb.toString();
  }
}