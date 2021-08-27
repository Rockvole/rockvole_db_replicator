
class TimeUtils {
  static final int C_CUSTOM_TS_OFFSET = 1350000000;
  static final int C_SECS_IN_HOUR=(60*60);
  static final int C_SECS_IN_DAY=(24*C_SECS_IN_HOUR);

  static int getCustomTsFromMillis(int currTimeMillis) {
    double time = currTimeMillis/1000;
    time -= C_CUSTOM_TS_OFFSET;
    return time.toInt();
  }

  static int getNowCustomTs() {
    return getCustomTsFromMillis(DateTime.now().millisecondsSinceEpoch);
  }

  static int getCustomTsInMillis(int customTs) {
    int time = (customTs + C_CUSTOM_TS_OFFSET) * 1000;
    return time;
  }
}