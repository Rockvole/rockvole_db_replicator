import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_db_replicator/rockvole_web_services.dart';

class WardenFilter {

  WardenFilter() {

  }

  bool shouldDiscardConfigurationDto(ConfigurationTrDto configurationTrDto, WardenType remoteWardenType) {
    if(remoteWardenType==WardenType.USER) {
      if(configurationTrDto.warden!=WardenType.USER) return true;
    }
    return false;
  }
}
