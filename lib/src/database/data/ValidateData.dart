import 'package:rockvole_db_replicator/rockvole_db.dart';

class ValidateData {
  static void validateFieldData(FieldData fieldData, SchemaMetaData smd, {int? table_id}) {
    fieldData.getFieldStructList.forEach((sd) {
      int ti=table_id ?? sd.field_table_id;
      FieldMetaData fmd = smd.getField(ti,sd.fieldName!);
      if(sd.value!=null) {
        switch (fmd.fieldDataType) {
          case FieldDataType.TINYINT:
            if (!(sd.value is int)) throw ArgumentError(
                "${sd.value} must be int");
            if (sd.value as int > 255)
              throw ArgumentError("Tinyint must not be greater than 255");
            break;
          case FieldDataType.SMALLINT:
            if (!(sd.value is int)) throw ArgumentError(
                "${sd.value} must be int");
            if (sd.value as int > 65535)
              throw ArgumentError(
                  "Smallint must not be greater than 65535");
            break;
          case FieldDataType.MEDIUMINT:
            if (!(sd.value is int)) throw ArgumentError(
                "${sd.value} must be int");
            if (sd.value as int > 16777215)
              throw ArgumentError(
                  "Mediumint must not be greater than 16777215");
            break;
          case FieldDataType.INTEGER:
            if (!(sd.value is int)) throw ArgumentError(
                "${sd.value} must be int");
            if (sd.value as int > 4294967295)
              throw ArgumentError(
                  "integer must not be greater than 4294967295");
            break;
          case FieldDataType.BIGINT:
            if (!(sd.value is int)) throw ArgumentError(
                "${sd.value} must be int");
            if (sd.value as int > 9223372036854775807)
              throw ArgumentError(
                  "Bigint must not be greater than 9223372036854775807");
            break;
          case FieldDataType.VARCHAR:
            if (!(sd.value is String)) throw ArgumentError(
                "${sd.value} must be String");
            if ((sd.value as String).length > fmd.fieldSize)
              throw ArgumentError(
                  "String cannot be longer than " + fmd.fieldSize.toString());
        }
      }
    });
  }
}
