import 'package:test/test.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';

void main() {
  String tableName="my_table";

  group("mysql tests", () {
    AbstractSqlStrings abstractSqlStrings=AbstractSqlStrings(tableName, DBType.Mysql);
    test('create table', () {
      String sql=abstractSqlStrings.getCreateTableString(tableName);
      expect(sql, 'CREATE TABLE $tableName ');
    });
    test("tinyint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.TINYINT, null);
      expect(sql, 'TINYINT(1) UNSIGNED ');
    });
    test("smallint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.SMALLINT, null);
      expect(sql, 'SMALLINT UNSIGNED ');
    });
    test("mediumint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.MEDIUMINT, null);
      expect(sql, 'MEDIUMINT UNSIGNED ');
    });
    test("integer", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.INTEGER, null);
      expect(sql, 'INTEGER UNSIGNED ');
    });
    test("bigint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.BIGINT, null);
      expect(sql, 'BIGINT UNSIGNED ');
    });
    test("varchar", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.VARCHAR, 20);
      expect(sql, 'VARCHAR(20) CHARACTER SET ascii ');
    });
  });

  group("sqflite tests", () {
    AbstractSqlStrings abstractSqlStrings=AbstractSqlStrings(tableName, DBType.Sqflite);
    test('create table', () {
      String sql=abstractSqlStrings.getCreateTableString(tableName,true);
      expect(sql, 'CREATE VIRTUAL TABLE $tableName USING fts4 ');
    });
    test("tinyint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.TINYINT, null);
      expect(sql, 'TINYINT UNSIGNED ');
    });
    test("smallint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.SMALLINT, null);
      expect(sql, 'SMALLINT UNSIGNED ');
    });
    test("mediumint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.MEDIUMINT, null);
      expect(sql, 'MEDIUMINT UNSIGNED ');
    });
    test("integer", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.INTEGER, null);
      expect(sql, 'INTEGER UNSIGNED ');
    });
    test("bigint", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.BIGINT, null);
      expect(sql, 'BIGINT UNSIGNED ');
    });
    test("varchar", () {
      String sql=abstractSqlStrings.getDataTypeString(FieldDataType.VARCHAR, 20);
      expect(sql, 'VARCHAR(20) ');
    });
  });
}