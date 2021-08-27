import 'package:adler32/adler32.dart';

class CrcUtils {
  static int? getCrcFromString(String? str) {
    int? checksum=null;
    if(str!=null) {
      checksum = Adler32.str(str);
    }
    return checksum;
  }
}
