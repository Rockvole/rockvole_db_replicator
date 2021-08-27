
class SimpleEntry {
  int? intValue;
  String? stringValue;
  SimpleEntry(this.intValue,this.stringValue);

  @override
  String toString() {
    return "intValue: $intValue || stringValue: $stringValue";
  }
}