import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';

abstract class AbstractWarden {
  static const String C_CLASSNAME = "AbstractWarden";
  static const String C_EXCEPTION_STATE_TYPE_NONE =
      "Do not set WaterState for this Warden";
  static const String C_EXCEPTION_STATE_TYPE_MUST =
      "WaterState must be set for this Warden";
  bool has_init=false;
  bool initialized = false;
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  late DbTransaction transaction;
  bool writeHistoricalChanges = true;
  late AbstractTableTransactions tableTransactions;
  late WaterLineDao waterLineDao;
  late WaterLine waterLine;
  WaterState? passedWaterState;
  late WaterLineDto waterLineDto;
  int? startTs;
  WardenType? localWardenType;
  WardenType? remoteWardenType;
  late bool wroteDto;
  Set<WaterState>? validWaterStates;
  WaterState? defaultWaterState = null;
  late bool generateSnapshot;
  late bool writeWaterLine;

  AbstractWarden({this.localWardenType, this.remoteWardenType});
  Future<void> init(SchemaMetaData smd, SchemaMetaData smdSys, DbTransaction transaction) async {
    has_init=true;
    writeWaterLine = true;
    this.smd = smd;
    this.smdSys = smdSys;
    this.transaction = transaction;
    await setWaterLine(smdSys, transaction);
    wroteDto = false;
  }

  void initialize(AbstractTableTransactions tableTransactions,
      {WaterState? passedWaterState}) {
    if (!has_init) throw ArgumentError(AbstractDao.C_MUST_INIT);
    initialized=true;
    passedWaterState ??= defaultWaterState;
    this.tableTransactions = tableTransactions;
    startTs = tableTransactions.getTrDto().ts;
    this.passedWaterState = passedWaterState;
    this.generateSnapshot = false;
  }

  void checkValidWaterStates() {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (validWaterStates == null) return;
    if (passedWaterState == null)
      throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
          cause: C_EXCEPTION_STATE_TYPE_MUST);
    if (!validWaterStates!.contains(passedWaterState))
      throw SqlException(SqlExceptionEnum.FAILED_UPDATE,
          cause: "$passedWaterState is an invalid state");
  }

  void setWaterLineDto(WaterLineDto waterLineDto) {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    this.waterLineDto = waterLineDto;
    waterLine.setWaterLineDto(waterLineDto);
  }

  WaterLineDto getWaterLineDto() => waterLine.getWaterLineDto();

  Future<void> setWaterLine(SchemaMetaData lSmdSys, DbTransaction ltr) async {
    if (!has_init) throw ArgumentError(AbstractDao.C_MUST_INIT);
    waterLineDao = WaterLineDao.sep(lSmdSys, ltr);
    await waterLineDao.init();
    waterLine = WaterLine(waterLineDao, lSmdSys, ltr);
  }

  Future<RemoteDto?> processInsert();
  Future<RemoteDto?> processUpdate();
  Future<RemoteDto?> processDelete();

  Future<void> _insertWaterLinePlaceholder() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? ts = tableTransactions.getTs();

    print("commitchanges start ts=$ts||lwt=$localWardenType||rwt=$remoteWardenType");
    try {
      print("wldto=$waterLineDto||writeWaterLine=$writeWaterLine");
      if (Warden.isServer(remoteWardenType!) && ts != null) {
        // insert row by timestamp supplied by remote write server
        try {
          if (writeWaterLine) {
            await waterLine.setRow(ts, WaterState.SERVER_PLACEHOLDER);
          }
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
            writeHistoricalChanges = false;
            waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
            try {
              await waterLine.setRow(ts, WaterState.SERVER_PLACEHOLDER);
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND)
                rethrow;
            }
          }
        }
      } else if (Warden.isServer(localWardenType!)) {
        // add row and generate system ts
        try {
          ts = await waterLine.addRow(WaterState.SERVER_PLACEHOLDER);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
            writeHistoricalChanges = false;
            waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
            try {
              ts = await waterLine.addRow(WaterState.SERVER_PLACEHOLDER);
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND)
                rethrow;
            }
          } else rethrow;
        }
        print("commitchanges ar");
      } else {
        try {
          generateSnapshot = true;
          ts = await waterLine.addRowByUserTs(
              WaterState.SERVER_PLACEHOLDER, WaterError.NONE);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
            writeHistoricalChanges = false;
            waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
            try {
              ts = await waterLine.addRowByUserTs(
                  WaterState.SERVER_PLACEHOLDER, WaterError.NONE);
            } on SqlException catch (e) {
              if (e.sqlExceptionEnum != SqlExceptionEnum.PARTITION_NOT_FOUND)
                rethrow;
            }
          }
          print("commitchanges arbut");
        }
        print("commitchanges ts=$ts");
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE) {
        print("WS $e");
      }
    }
    tableTransactions.setTs(ts!);
  }

  Future<RemoteDto?> write() async {
    if (!initialized)
      throw ArgumentError("Must call initialize() before write()");
    late RemoteDto? remoteDto;
    await _insertWaterLinePlaceholder();
    switch (tableTransactions.getOperationType()) {
      case OperationType.INSERT:
        remoteDto = await processInsert();
        break;
      case OperationType.UPDATE:
        remoteDto = await processUpdate();
        break;
      case OperationType.DELETE:
        remoteDto = await processDelete();
        break;
      default:
    }
    return remoteDto;
  }

  void setStates() {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    waterLine.setWaterState(WaterState.CLIENT_STORED);
  }

  Future<RemoteDto> writeAdd() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? id = null;
    bool success = false;

    try {
      id = await tableTransactions.add();
      success = true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.JOIN_FAILURE) {
        waterLine.setWaterError(WaterError.JOIN_FAILURE);
        print("$C_CLASSNAME:writeAdd(JOIN_FAILURE):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY) {
        waterLine.setWaterError(WaterError.DUPLICATE_ENTRY);
        print("$C_CLASSNAME:writeAdd(DUPLICATE_ENTRY):$e");
        try {
          id = await tableTransactions.findId();
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
            print(e);
          }
        }
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
        waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
        print("$C_CLASSNAME:writeAdd(PARTITION_NOT_FOUND):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.INVALID_ENTRY) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        print("$C_CLASSNAME:writeAdd(INVALID_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        waterLine.setWaterError(WaterError.ENTRY_NOT_FOUND);
        print("$C_CLASSNAME:writeAdd(ENTRY_NOT_FOUND):$e");
      } else {
        waterLine.setWaterError(WaterError.FAILED_UPDATE);
        print("$C_CLASSNAME:writeAdd(FAILED_UPDATE):$e");
      }
    }
    if (success) {
      tableTransactions.setId(id!);
      setStates();
      wroteDto = true;
    } else {
      if (id == null) id = await tableTransactions.nextId();
      tableTransactions.setId(id!);
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  Future<RemoteDto> writeInsert() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool success = false;

    try {
      await tableTransactions.insert();
      tableTransactions.setCrc(null);
      success = true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY) {
        waterLine.setWaterError(WaterError.DUPLICATE_ENTRY);
        print("$C_CLASSNAME:writeInsert(DUPLICATE_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        print("$C_CLASSNAME:writeInsert(INVALID_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
        waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
        print("$C_CLASSNAME:writeInsert(PARTITION_NOT_FOUND):$e");
      } else {
        waterLine.setWaterError(WaterError.FAILED_UPDATE);
        print("$C_CLASSNAME:writeInsert(FAILED_UPDATE):$e");
      }
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  Future<RemoteDto> writeOverWrite() async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool success = false;

    try {
      await tableTransactions.forced_overwrite();
      success = true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY) {
        waterLine.setWaterError(WaterError.DUPLICATE_ENTRY);
        print("$C_CLASSNAME:writeOverWrite(DUPLICATE_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
        waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
        print("$C_CLASSNAME:writeOverWrite(PARTITION_NOT_FOUND):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        print("$C_CLASSNAME:writeOverWrite(INVALID_ENTRY):$e");
      } else {
        waterLine.setWaterError(WaterError.FAILED_UPDATE);
        print("$C_CLASSNAME:writeOverWrite(FAILED_UPDATE):$e");
      }
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  Future<RemoteDto> writeUpdate(FieldData? originalDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool success = false;

    try {
      await tableTransactions.update();
      success = true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.DUPLICATE_ENTRY) {
        waterLine.setWaterError(WaterError.DUPLICATE_ENTRY);
        print("$C_CLASSNAME:writeUpdate(DUPLICATE_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        print("$C_CLASSNAME:writeUpdate(INVALID_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
        waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
        print("$C_CLASSNAME:writeUpdate(PARTITION_NOT_FOUND):$e");
      } else {
        waterLine.setWaterError(WaterError.FAILED_UPDATE);
        print("$C_CLASSNAME:writeUpdate(FAILED_UPDATE):$e");
      }
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(originalDto);
    return remoteDto;
  }

  Future<RemoteDto> writeDelete(FieldData? originalDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    bool success = false;

    try {
      await tableTransactions.delete(originalDto);
      success = true;
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        waterLine.setWaterError(WaterError.ENTRY_NOT_FOUND);
        print("$C_CLASSNAME:writeDelete(ENTRY_NOT_FOUND):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
        waterLine.setWaterError(WaterError.INVALID_ENTRY);
        print("$C_CLASSNAME:writeDelete(INVALID_ENTRY):$e");
      } else if (e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND) {
        waterLine.setWaterError(WaterError.PARTITION_NOT_FOUND);
        print("$C_CLASSNAME:writeDelete(PARTITION_NOT_FOUND):$e");
      }
    }
    if (success) {
      setStates();
      wroteDto = true;
    }
    RemoteDto remoteDto = await commitChanges(null);
    return remoteDto;
  }

  bool doesCrcMatch(String? crcString) {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    if (crcString == null) {
      tableTransactions.setCrc(null);
      return true;
    }
    int? crc = tableTransactions.getTrDto().crc;
    print("crc=$crc==" +
        CrcUtils.getCrcFromString(crcString).toString() +
        " '" +
        crcString +
        "'");
    return CrcUtils.getCrcFromString(crcString) == crc;
  }

  Future<RemoteDto> commitChanges(FieldData? originalDto) async {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    int? ts = tableTransactions.getTs();
    int? userTs = tableTransactions.getTrDto().user_ts;
    TrDto? trDto = null;
    try {
      // Update Placeholder with final value
      if (writeWaterLine) {
        await waterLine.updatePlaceholder();
      }
      if (generateSnapshot) {
        if (userTs != null) {
          print(
              "WARNING: UserTs should not be passed except for testing purposes");
        } else userTs=TimeUtils.getNowCustomTs();
        if (originalDto != null) {
          int snapShotTs = await waterLine.addRowByUserTs(
              WaterState.CLIENT_SNAPSHOT, WaterError.NONE);
          await tableTransactions.snapshot(originalDto, snapShotTs, userTs);
        }
      }
      if (writeHistoricalChanges) {
        try {
          trDto = await tableTransactions.writeHistoricalChanges(ts!, userTs);
        } on SqlException catch (e) {
          if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) {
            waterLine.setWaterError(WaterError.INVALID_ENTRY);
          } else rethrow;
        }
      }
      if (trDto == null) trDto = tableTransactions.getTrDto();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        print(e);
      } else rethrow;
    }
    RemoteDto remoteDto = RemoteDto.sep(trDto!, smd, waterLineDto: waterLine.getWaterLineDto());
    return remoteDto;
  }

  @override
  String toString() {
    if (!initialized) throw ArgumentError(AbstractDao.C_MUST_INIT);
    return "AbstractWarden [localWardenType=$localWardenType" +
        ", remoteWardenType=$remoteWardenType" +
        ", tableTransactions=$tableTransactions" +
        "]\n";
  }
}
