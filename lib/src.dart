// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Be {
  static BluetoothDevice? savedDevice;
  static BluetoothService? service;
  static BluetoothCharacteristic? readCharacteristics;
  static BluetoothCharacteristic? writeCharacteristics;
  static StreamSubscription<BluetoothConnectionState>? savedSubscription;
  static bool wake = true;
  static int times = 0;
  static int readTimes = 0;
  static Function? updater;
  static bool _communicatingNow = false;

  Be() {}

  static Future<bool> init() async {
    bool status = false;
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return false;
    }
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        status = true;
      } else {
        status = false;
      }
    });
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    subscription.cancel();
    return status;
  }

  static scan(Function(String, BluetoothDevice) onFound) async {
    for (var device in FlutterBluePlus.connectedDevices) {
      await device.disconnect();
    }
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) async {
        if (results.isNotEmpty) {
          ScanResult r = results.last;
          onFound(
              (r.advertisementData.advName.length > 1)
                  ? r.advertisementData.advName
                  : "${r.device.remoteId}",
              r.device);
        }
      },
      onError: (e) => print(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  static Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  static Future<Map<String, dynamic>> connect(BluetoothDevice device) async {
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("Device Disconnected : ${device.disconnectReason}");
      }
    });
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    // Connect to the device
    String? error;
    try {
      await device.connect();
    } catch (e) {
      error = "failed to connect";
      return {"error": error};
    }

    try {
      //get service
      List<BluetoothService> services = await device.discoverServices();
      for (var s in services) {
        if (s.serviceUuid == Guid("FF00")) {
          service = s;
        }
      }
      //get write charac
      var characteristics = service!.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.characteristicUuid == Guid("FF01")) {
          readCharacteristics = c;
        }
      }
      //get read charac
      characteristics = service!.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.characteristicUuid == Guid("FF02")) {
          writeCharacteristics = c;
        }
      }
    } catch (e) {
      return {"error": "imcompatible device"};
    }

    try {
      //getting first basic info
      var readSuccessFully = await read(Data.BASIC_INFO_PAYLOAD);
      readSuccessFully = await read(Data.CELL_INFO_PAYLOAD);
      readSuccessFully = await read(Data.STATS_PAYLOAD);

      if (readSuccessFully) {
        return {"error": null, "sub": subscription};
      }
      return {"error": "could not read device"};
    } catch (e) {
      return {"error": "failed to read device"};
    }
  }

  static void setCharge(bool charge) {
    //changeBit(bitIndex: bitIndex, bitValue: bitValue, byteToChange: byteToChange)
  }

  static Future<bool> getBasicInfo() async {
    var readSuccessFully = await read(Data.BASIC_INFO_PAYLOAD);
    if (readSuccessFully) {
      Data.setAvailableData(true);
      if (updater != null) {
        updater!();
      }
    }

    return readSuccessFully;
  }

  static Future<bool> getCellInfo() async {
    var readSuccessFully = await read(Data.CELL_INFO_PAYLOAD);
    if (readSuccessFully) {
      Data.setAvailableData(true);
      if (updater != null) {
        updater!();
      }
    }

    return readSuccessFully;
  }

  static Future<bool> getStatsReport() async {
    var readSuccesFully = await read(Data.STATS_PAYLOAD);
    return readSuccesFully;
  }

  static Future<void> disconnect(BluetoothDevice device,
      StreamSubscription<BluetoothConnectionState> sub) async {
    // Disconnect from device
    await device.disconnect();
    await sub.cancel();
  }

  static List<int> checksumtoRead(List<int> payload) {
    int sum = 0;
    for (var i in payload) {
      sum += i;
    }
    int check = 0x10000 - sum;
    List<int> result = [];
    String hexString = check.toRadixString(16);
    if (hexString.length % 2 != 0) {
      hexString = '0$hexString';
    }
    for (int i = 0; i < hexString.length; i += 2) {
      result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }

    return result;
  }

  static Future<bool> read(List<int> payload) async {
    _communicatingNow = true;
    Future.delayed(const Duration(minutes: 1)).then((value) => _setWake(true));
    List<int> answer = [];
    //subscribe to read charac
    await readCharacteristics!.setNotifyValue(true);
    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      answer.addAll(event);
    });

    List<int> cmd = [0xDD, 0xa5, ...payload, ...checksumtoRead(payload), 0x77];
    int j = 0;
    do {
      print("sending command : $cmd");
      for (var i = (wake) ? 0 : 1; i < 2; i++) {
        await writeCharacteristics!.write(cmd, withoutResponse: true);
        if (wake) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        _setWake(false);
      }
      //maybe this will fail on a 100 cells battery
      await Future.delayed(Duration(milliseconds: 300 + j * 300));
      j++;
      if (j > 5) {
        break;
      }
    } while (answer.isEmpty);

    notifySub.cancel();
    try {
      var good = _verifyReadings(answer);
      var data = answer.sublist(4, answer.length - 3);
      var good2 = Data.setBatchData(data, answer[1]);
      _communicatingNow = false;
      print(answer);
      return good && good2;
    } catch (e) {
      _communicatingNow = false;
      print("Reading failed ${e.toString()}");
      return false;
    }
  }

  static write(List<int> payload) async {
    while (_communicatingNow) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _communicatingNow = true;
    Future.delayed(const Duration(minutes: 1)).then((value) => _setWake(true));
    var confirmation = [];
    await readCharacteristics!.setNotifyValue(true);
    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      confirmation.addAll(event);
    });
    //subscribe to read charac
    List<int> cmd = [0xDD, 0x5a, ...payload, ...checksumtoRead(payload), 0x77];
    for (var i = (wake) ? 0 : 1; i < 2; i++) {
      writeCharacteristics!.write(cmd, withoutResponse: true);
      if (wake) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      _setWake(false);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    while (confirmation.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _communicatingNow = false;
  }

  static bool _verifyReadings(List<int> rawData) {
    if (rawData[0] != 0xDD) {
      print(rawData);
      rawData.clear();
      print("Wrong starting byte");
      return false;
    }
    if (rawData[2] != 0x00) {
      print(rawData);
      rawData.clear();
      print("Error code ${rawData[2]}");
      return false;
    }
    if (rawData[rawData.length - 1] != 0x77) {
      print(rawData);
      rawData.clear();
      print("wrong ending byte");
      return false;
    }

    var payload = rawData.sublist(3, rawData.length - 3);
    if (rawData.sublist(rawData.length - 3)[0] != checksumtoRead(payload)[0] ||
        rawData.sublist(rawData.length - 3)[1] != checksumtoRead(payload)[1]) {
      print("corupted data ${[
        ...checksumtoRead(payload),
        0x77
      ]} is not ${rawData.sublist(rawData.length - 3)} for ${rawData[1]}");
      print(rawData);
      rawData.clear();
      return false;
    }
    return true;
  }

  static void setUpdater(void Function() setstate) {
    updater = setstate;
  }

  static void turnOnDischarge() async {
    await write([
      ...Data.COMAND_PAYLOAD,
      _changeBit(
          0, 0, _boolArrayToInt([Data.chargeStatus, Data.dischargeStatus]))
    ]);
    await getBasicInfo();
  }

  static void turnOffDischarge() async {
    await write([
      ...Data.COMAND_PAYLOAD,
      _changeBit(
          0, 1, _boolArrayToInt([Data.chargeStatus, Data.dischargeStatus]))
    ]);
    await getBasicInfo();
  }

  static void turnOnCharge() async {
    await write([
      ...Data.COMAND_PAYLOAD,
      _changeBit(
          1, 0, _boolArrayToInt([Data.chargeStatus, Data.dischargeStatus]))
    ]);
    await getBasicInfo();
  }

  static void turnOffCharge() async {
    await write([
      ...Data.COMAND_PAYLOAD,
      _changeBit(
          1, 1, _boolArrayToInt([Data.chargeStatus, Data.dischargeStatus]))
    ]);
    await getBasicInfo();
  }

  static void _setWake(bool wakeValue) {
    wake = wakeValue;
  }

  static int _changeBit(int bitIndex, int bitValue, int byteToChange) {
    // Check if the bitIndex is within the valid range (0 to 7 for a byte)
    if (bitIndex < 0 || bitIndex > 1) {
      throw ArgumentError(
          'Invalid bit index. Bit index must be between 0 and 7.');
    }

    // Check if the bitValue is valid (0 or 1)
    if (bitValue != 0 && bitValue != 1) {
      throw ArgumentError('Invalid bit value. Bit value must be 0 or 1.');
    }

    // Clear the bit at the specified index
    int mask = ~(1 << bitIndex);
    int result = byteToChange & mask;

    // Set the bit to the desired value
    result |= (bitValue << bitIndex);
    print(result);

    return result;
  }

  static int _boolArrayToInt(List<bool> bits) {
    if (bits.length != 2) {
      throw ArgumentError('Input list must contain exactly 2 bools');
    }
    int result = 0;
    for (int i = 0; i < bits.length; i++) {
      if (bits[i]) {
        result |= (1 << i);
      }
    }
    return result;
  }

  static bool get comunivatingNow => _communicatingNow;
}

class Data {
  static const BASIC_INFO = 0x03;
  static const CELL_VOLTAGE = 0x04;
  static const DEVICE_NAME = 0x05;
  static const STAT_INFO = 0xAA;

  static const int DESIGN_CAP = 0x10;
  static const int CYCLE_CAP = 0x11;
  static const int CAP_100 = 0x12;
  static const int CAP_80 = 0x32;
  static const int CAP_60 = 0x33;
  static const int CAP_40 = 0x34;
  static const int CAP_20 = 0x35;
  static const int CAP_0 = 0x13;
  static const int DSG_RATE = 0x14;
  static const int MFG_DATE = 0x15;
  static const int SERIAL_NUM = 0x16;
  static const int CYCLE_CNT = 0x17;
  static const int CHGOT = 0x18;
  static const int CHGOT_REL = 0x19;
  static const int CHGUT = 0x1A;
  static const int CHGUT_REL = 0x1B;
  static const int CHG_T_DELAYS = 0x3A;
  static const int DSG_T_DELAYS = 0x3B;
  static const int DSGOT = 0x1C;
  static const int DSGOT_REL = 0x1D;
  static const int DSGUT = 0x1E;
  static const int DSGUT_REL = 0x1F;
  static const int POVP = 0x20;
  static const int POVP_REL = 0x21;
  static const int PUVP = 0x22;
  static const int PUVP_REL = 0x23;
  static const int PACK_V_DELAYS = 0x3C;
  static const int COVP = 0x24;
  static const int COVP_REL = 0x25;
  static const int CUVP = 0x26;
  static const int CUVP_REL = 0x27;
  static const int CELL_V_DELAYS = 0x3D;
  static const int CHGOC = 0x28;
  static const int CHGOC_DELAYS = 0x3E;
  static const int DSGOC = 0x29;
  static const int DSGOC_DELAYS = 0x3F;
  static const int BAL_START = 0x2A;
  static const int BAL_WINDOW = 0x2B;
  static const int SHUNT_RES = 0x2C;
  static const int FUNC_CONFIG = 0x2D;
  static const int NTC_CONFIG = 0x2E;
  static const int CELL_CNT = 0x2F;
  static const int FET_CTRL = 0x30;
  static const int LED_TIMER = 0x31;
  static const int COVP_HIGH = 0x36;
  static const int CUVP_HIGH = 0x37;
  static const int SC_DSGOC2 = 0x38;
  static const int CXVP_HIGH_DELAY_SC_REL = 0x39;
  static const int MFG_NAME = 0xA0;
  static const int DEVICE_NAME_FULL = 0xA1;
  static const int BARCODE = 0xA2;
  static const CLEAR_PASSWORD = 0x09;
  static const ENTER_FACTORY_MODE = 0x00;
  static const EXIT_FACTORY_MODE = 0x01;

  static final Map<String, List<int>> _data = {};
  static const BASIC_INFO_PAYLOAD = [BASIC_INFO, 0x00];
  static const CELL_INFO_PAYLOAD = [CELL_VOLTAGE, 0x00];
  static const STATS_PAYLOAD = [STAT_INFO, 0x00];
  static const COMAND_PAYLOAD = [0xe1, 0x02, 0x00];

  static bool availableData = false;
  static bool get isBLEConnected => availableData;
  static String get pack_mv => (!availableData)
      ? "0.0"
      : (((_data["pack_mv"]![0] << 8) + _data["pack_mv"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get pack_ma {
    if (!availableData) {
      return "0.0";
    }
    int result =
        (_data["pack_ma"]![1] & 0xFF) | ((_data["pack_ma"]![0] << 8) & 0xFF00);
    // Check the sign bit (MSB)
    if (result & 0x8000 != 0) {
      result = -(0x10000 - result);
    }
    return (result * 0.01).toStringAsFixed(2);
  }

  static String get cycle_cap => (!availableData)
      ? "0.0"
      : (((_data["cycle_cap"]![0] << 8) + _data["cycle_cap"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get design_cap => (!availableData)
      ? "0.0"
      : (((_data["design_cap"]![0] << 8) + _data["design_cap"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get cycle_cnt => (!availableData)
      ? "0"
      : (((_data["cycle_cnt"]![0] << 8) + _data["cycle_cnt"]![1])).toString();

  static bool get chargeStatus {
    if (!availableData) {
      return false;
    }
    return (_data["fet_status"]![0] & 0x1) != 0;
  }

  static bool get dischargeStatus {
    if (!availableData) {
      return false;
    }
    return (_data["fet_status"]![0] & 0x2) != 0;
  }

  static List<String> get curr_err {
    List<String> err = [];
    if (!availableData) {
      return [];
    }
    for (int i = 15; i >= 0; i--) {
      bool bit =
          (((_data["curr_err"]![0] << 8) + _data["curr_err"]![1]) & (1 << i)) !=
              0;
      if (bit) {
        switch (i) {
          case 0:
            err.add("CHVP"); // Cell high volatge protection
            break;
          case 1:
            err.add("CLVP"); // Cell low voltage protection
            break;
          case 2:
            err.add("PHVP"); //Pack high voltage protection
            break;
          case 3:
            err.add("PLVP"); //Pack low voltage protection
            break;
          case 4:
            err.add("COTP"); //Charge over Temperature protection
            break;
          case 5:
            err.add("CUTP"); //Charge under temperature protection
            break;
          case 6:
            err.add("DOTP"); //Discharge over temperature protection
            break;
          case 7:
            err.add("DUTP"); //Discharge under temperature protection
            break;
          case 8:
            err.add("COCP"); //Charge over current protection
            break;
          case 9:
            err.add("COCP"); //Discharge over current protection
            break;
          case 10:
            err.add("SCP"); //Short circuit protection
            break;
          case 11:
            err.add("FICE"); //Frontend IC err (afe_err)
            break;
          case 12:
            err.add("COBU"); //Chage turned off by user
            break;
          default:
            err.add("UNKOWN"); //Unknown error
            break;
        }
      }
    }
    return err;
  }

  static String get date {
    if (!availableData) {
      return "";
    }
    var dateData = ((_data["date"]![0] << 8) + _data["date"]![1]);
    // Extract year, month, and day components using bitwise operations and bit masking
    int year = (dateData >> 9) & 0x7F;
    int month = (dateData >> 5) & 0xF;
    int day = dateData & 0x1F;

    // Adjust year to account for the base year 2000
    year += 2000;
    return "$day/$month/$year";
  }

  static List<bool> get bal {
    if (!availableData) {
      return [];
    }
    List<bool> bal = [];
    int combined = ((_data["bal"]![0] << 8) + _data["bal"]![1]);
    for (int i = 0; i < 16; i++) {
      bool bit = (combined & (1 << i)) != 0;
      bal.add(bit);
    }
    return bal;
  }

  static int get cap_pct => (!availableData) ? 0 : _data["cap_pct"]![0];
  static int get cell_cnt => (!availableData) ? 0 : _data["cell_cnt"]![0];
  static int get ntc_cnt => (!availableData) ? 0 : _data["ntc_cnt"]![0];
  static List<String> get ntc_temp {
    if (!availableData) {
      return [];
    }
    List<String> temps = [];
    int j = 0;
    for (var i = 0; i < ntc_cnt; i++) {
      temps.add(
          (((_data["ntc_temp"]![j] << 8) + _data["ntc_temp"]![j + 1]) * 0.1 -
                  273.15)
              .toStringAsFixed(1));
      j += 2;
    }
    return temps;
  }

  static List<double> get cell_mv {
    if (!availableData) {
      return [];
    }
    List<double> cells = [];
    for (int i = 0; i < cell_cnt; i++) {
      cells.add(
          ((_data["cell${i}_mv"]![0] << 8) + _data["cell${i}_mv"]![1]) * 0.001);
    }

    return cells;
  }

  static int get sc_err_cnt => _getIntValue(_data["sc_err_cnt"]);
  static int get chgoc_err_cnt => _getIntValue(_data["chgoc_err_cnt"]);
  static int get dsgoc_err_cnt => _getIntValue(_data["dsgoc_err_cnt"]);
  static int get covp_err_cnt => _getIntValue(_data["covp_err_cnt"]);
  static int get cuvp_err_cnt => _getIntValue(_data["cuvp_err_cnt"]);
  static int get chgot_err_cnt => _getIntValue(_data["chgot_err_cnt"]);
  static int get chgut_err_cnt => _getIntValue(_data["chgut_err_cnt"]);
  static int get dsgot_err_cnt => _getIntValue(_data["dsgot_err_cnt"]);
  static int get dsgut_err_cnt => _getIntValue(_data["dsgut_err_cnt"]);
  static int get povp_err_cnt => _getIntValue(_data["povp_err_cnt"]);
  static int get puvp_err_cnt => _getIntValue(_data["puvp_err_cnt"]);
  static int get unknown => 0;
  static int _getIntValue(List<int>? bytes) {
    if (!availableData) {
      return 0;
    }
    int value = (bytes![0] << 8) + bytes![1];
    return value;
  }

  static int get device_name_lenght =>
      (!availableData) ? 0 : _data["device_name_lenght"]![0];
  static String get device_name =>
      (!availableData) ? "" : String.fromCharCodes(_data["device_name"]!);
  static String get watts {
    if (!availableData) {
      return "0.0";
    }
    int result =
        (_data["pack_ma"]![1] & 0xFF) | ((_data["pack_ma"]![0] << 8) & 0xFF00);

    // Check the sign bit (MSB)
    var doubleResult =
        (result & 0x8000 != 0) ? -(0x10000 - result) * 1.0 : result * 1.0;

    return (doubleResult *
            (((_data["pack_mv"]![0] << 8) + _data["pack_mv"]![1]) * 0.01) *
            0.01)
        .round()
        .toString();
  }

  static String get timeLeft {
    if (!availableData) {
      return "0 Minutes left";
    }
    var timeHours =
        ((_data["pack_ma"]![1] & 0xFF) | (_data["pack_ma"]![0] << 8) & 0xFF00) /
            ((_data["cycle_cap"]![0] << 8) + _data["cycle_cap"]![1]);
    double timeMinutes = timeHours * 60.0;
    return "$timeMinutes minutes left";
  }

  static double get celldif {
    if (!availableData) {
      return 0;
    }
    var current = cell_mv[0];
    for (var i = 0; i < cell_cnt; i++) {
      if (current > cell_mv[i]) {
        current = cell_mv[i];
      }
    }

    var smallest = current;
    print(smallest);
    current = cell_mv[0];
    for (var i = 0; i < cell_cnt; i++) {
      if (current < cell_mv[i]) {
        current = cell_mv[i];
      }
    }
    var biggest = current;
    print(biggest);
    return biggest - smallest;
  }

  static bool setBatchData(List<int> batch, int register) {
    setAvailableData(true);
    if (register == BASIC_INFO) {
      int afterNtc = 0;

      _data["pack_mv"] = batch.sublist(0, 2);
      _data["pack_ma"] = batch.sublist(0x2, 0x4);
      _data["cycle_cap"] = batch.sublist(0x4, 0x6);
      _data["design_cap"] = batch.sublist(0x6, 0x8);
      _data["cycle_cnt"] = batch.sublist(0x8, 0xA);
      _data["date"] = batch.sublist(0xA, 0xC);
      _data["bal"] = batch.sublist(0xC, 0x10);
      _data["curr_err"] = batch.sublist(0x10, 0x12);
      _data["version"] = [batch[0x12]];
      _data["cap_pct"] = [batch[0x13]];
      _data["fet_status"] = [batch[0x14]];
      _data["cell_cnt"] = [batch[0x15]];
      _data["ntc_cnt"] = [batch[0x16]];
      afterNtc = 0x017 + ntc_cnt * 2;
      _data["ntc_temp"] = batch.sublist(0x17, afterNtc);

      try {
        _data["humidity"] = [batch[afterNtc]];
        _data["alarm"] = batch.sublist(afterNtc, afterNtc + 1);
        _data["full_charge_capacity"] =
            batch.sublist(afterNtc + 1, afterNtc + 3);
        _data["remaining_capacity"] = batch.sublist(afterNtc + 3, afterNtc + 5);
        _data["balance_current"] = batch.sublist(afterNtc + 5, afterNtc + 7);
      } catch (e) {
        print(e.toString());
        print(
            "Data humidity, alarm, full_charge_capacity, remining_capacity and balance curent was not found in basic info");
      }
      setAvailableData(false);
      return true;
    }

    if (register == CELL_VOLTAGE) {
      int j = 0;
      for (int i = 0; i < cell_cnt; i++) {
        var key = "cell${i}_mv";
        _data[key] = batch.sublist(j, j + 2);
        j += 2;
      }
      setAvailableData(false);
      return true;
    }

    if (register == STAT_INFO) {
      List<String> keys = [
        "sc_err_cnt",
        "chgoc_err_cnt",
        "dsgoc_err_cnt",
        "covp_err_cnt",
        "cuvp_err_cnt",
        "chgot_err_cnt",
        "chgut_err_cnt",
        "dsgot_err_cnt",
        "dsgut_err_cnt",
        "povp_err_cnt",
        "puvp_err_cnt"
      ];

      int startOffset = 0;
      int endOffset = 2;

      for (String key in keys) {
        _data[key] = batch.sublist(startOffset, endOffset);
        startOffset += 2;
        endOffset += 2;
      }
      setAvailableData(false);
      return true;
    }

    if (register == DEVICE_NAME) {
      _data["device_name_lenght"] = [batch[0]];
      _data["device_name"] = batch.sublist(0x1, device_name_lenght);
      setAvailableData(false);
      return true;
    }

    print("unknown registery");
    setAvailableData(false);
    return false;
  }

  static setAvailableData(bool isBLEConnected) {
    availableData = isBLEConnected;
  }
}
