
int getErrorCode(String errorString) {
  String regex = "^Error (\\d+) (.*)\$";
  RegExp regexp= RegExp(regex);
  var matches = regexp.allMatches(errorString);
  int retVal=0;
  try {
    retVal = int.parse(matches.elementAt(0).group(1).toString());
  } on RangeError {
  }
  return retVal;
}