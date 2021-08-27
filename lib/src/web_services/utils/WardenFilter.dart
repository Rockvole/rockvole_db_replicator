import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

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
