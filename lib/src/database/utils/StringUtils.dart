import 'dart:math';

class StringUtils {
  static late String alphaNumeric;
  static late String alpha;

  StringUtils() {
    StringBuffer sb = StringBuffer();
    for (int idx = 0; idx < 10; ++idx) sb.write('0' + idx.toString());
    for (int idx = 10; idx < 36; ++idx) sb.write('a' + (idx - 10).toString());
    alphaNumeric = sb.toString();
    sb = StringBuffer();
    for (int idx = 0; idx < 26; ++idx) sb.write('a' + idx.toString());
    alpha = sb.toString();
  }

  final Random random = Random.secure();

  String randomAlphaNumericString(int length) {
    if (length < 1) throw ArgumentError("length < 1: $length");

    StringBuffer sb = StringBuffer();
    for (int idx = 0; idx < length; ++idx)
      sb.write(alphaNumeric[random.nextInt(alphaNumeric.length)]);
    return sb.toString();
  }

  String randomAlphaString(int length) {
    if (length < 1) throw ArgumentError("length < 1: $length");

    StringBuffer sb = StringBuffer();
    for (int idx = 0; idx < length; ++idx)
      sb.write(alpha[random.nextInt(alpha.length)]);
    return sb.toString();
  }

  static String formatSql(String sql) {
    String returnSql = sql.trim();
    returnSql = returnSql.replaceAll(RegExp(r"\s+|\s"), " ");
    return returnSql;
  }
}
