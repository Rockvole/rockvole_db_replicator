
class DbConstants {
  static const int C_TINYINT_MAX = 255;
  static const int C_SMALLINT_MAX = 65535;
  static const int C_MEDIUMINT_MAX = 16777215;
  static const int C_INTEGER_MAX = 2147483647;
  static const int C_LONG_MAX = 9223372036854775807;

  static const int C_SMALLINT_USERSPACE_MIN = 60000;
  static const int C_MEDIUMINT_USERSPACE_MIN = 16000000;
  static const int C_INTEGER_USERSPACE_MIN = 2000000000;

  static String getStringOfSize(int size, {String character='Z'}) {
    StringBuffer sb=StringBuffer();
    for(int i=0;i<size;i++) sb.write(character);
    return sb.toString();
  }
}
