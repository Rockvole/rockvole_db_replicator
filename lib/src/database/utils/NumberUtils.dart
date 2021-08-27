import 'dart:math';

class NumberUtils {

  static int randInt(int min, int max) {
    Random rand =Random.secure();
    int randomNum = rand.nextInt((max - min) + 1) + min;
    return randomNum;
  }
}

