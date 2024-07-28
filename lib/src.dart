// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Be {
  static BluetoothDevice? savedDevice;
  static String? title;
  static BluetoothService? service;
  static BluetoothCharacteristic? readCharacteristics;
  static BluetoothCharacteristic? writeCharacteristics;
  static StreamSubscription<BluetoothConnectionState>? savedSubscription;
  static BuildContext? context;
  static bool wake = true;
  static int times = 0;
  static int readTimes = 0;
  static Function? updater;
  static bool _communicatingNow = false;
  static bool _warantyVoided = false;
  static bool _dubioslock = true;

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
        try {
          if (results.isNotEmpty) {
            ScanResult r = results.last;
            onFound(
                (r.advertisementData.advName.length > 1)
                    ? r.advertisementData.advName
                    : "${r.device.remoteId}",
                r.device);
          }
        } catch (e) {
          print("switched window");
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

  static setDevice(String title, BluetoothDevice device) {
    savedDevice = device;
    title = title;
  }

  static Future<Map<String, String?>> connect(BluetoothDevice device) async {
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("Device Disconnected : ${device.disconnectReason}");
      }
    });
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    // Connect to the device
    String? error;

    for (int j = 0; j < 3; j++) {
      try {
        await device.connect(timeout: const Duration(seconds: 7));
        error = null;
        break;
      } catch (e) {
        error = "failed to connect";
      }
    }
    if (error != null) return {"error": error};

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
      return {"error": "device not compatible"};
    }

    try {
      //getting first basic info
      var readSuccessFully = await read(Data.BASIC_INFO_PAYLOAD);
      readSuccessFully = (readSuccessFully)
          ? await read(Data.CELL_INFO_PAYLOAD)
          : readSuccessFully;
      readSuccessFully = (readSuccessFully)
          ? await read(Data.STATS_PAYLOAD)
          : readSuccessFully;

      if (readSuccessFully) {
        savedDevice = device;
        savedSubscription = subscription;
        readWhatsLeft();
        Data.setAvailableData(true);
        return {"error": null};
      }
      Data.clear();
      return {"error": "could not read device"};
    } catch (e) {
      return {"error": "failed to read device"};
    }
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

  static Future<void> disconnect({bool totaly = false}) async {
    // Disconnect from device
    await savedDevice?.disconnect();
    await savedSubscription?.cancel();
    savedSubscription = null;
    if (totaly) {
      savedDevice = null;
      title = null;
    }
  }

  static Future<bool> resetConnection() async {
    await disconnect(totaly: false);
    try {
      await savedDevice!.connect();
    } catch (e) {
      quicktell(context!, "Lost connection with device");
      return false;
    }
    await savedDevice!.discoverServices();
    return true;
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
    List<int> answer = [];
    //subscribe to read charac
    await readCharacteristics!.setNotifyValue(true);
    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      answer.addAll(event);
    });

    List<int> cmd = [0xDD, 0xa5, ...payload, ...checksumtoRead(payload), 0x77];
    print("reading command : $cmd");
    int j = 0;
    do {
      for (var i = (wake) ? 0 : 1; i < 2; i++) {
        await writeCharacteristics!.write(cmd, withoutResponse: true);
        if (wake) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        _setWake(false);
      }
      //maybe this will fail on a 100 cells battery

      await Future.delayed(Duration(milliseconds: 200 + j * 300));

      j++;
      if (j > 5) {
        break;
      }
    } while (answer.isEmpty);

    notifySub.cancel();

    var good = _verifyReadings(answer);
    print(answer);
    if (!good) {
      good = await resetConnection();
      print("RECONNECTED: $good");
      if (good) _communicatingNow = false;
      return good;
    }

    var data = answer.sublist(4, answer.length - 3);
    var good2 = Data.setBatchData(data, answer[1]);
    _communicatingNow = false;
    return good2;
  }

  static write(List<int> payload) async {
    while (_communicatingNow) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _communicatingNow = true;

    //TODO: Do we still need this _setWake function?

    Future.delayed(const Duration(minutes: 1)).then((value) => _setWake(true));
    var confirmation = [];

    //subscribe to read charac
    await readCharacteristics!.setNotifyValue(true);
    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      confirmation.addAll(event);
    });
    List<int> cmd = [0xDD, 0x5a, ...payload, ...checksumtoRead(payload), 0x77];
    print("writing command : $cmd");
    for (var i = (wake) ? 0 : 1; i < 2; i++) {
      await writeCharacteristics!.write(cmd, withoutResponse: true);
      if (wake) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      _setWake(false);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    while (confirmation.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    print("received from write command : $confirmation");
    _communicatingNow = false;
    notifySub.cancel();
  }

  static bool _verifyReadings(List<int> rawData) {
    try {
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
      if (rawData.sublist(rawData.length - 3)[0] !=
              checksumtoRead(payload)[0] ||
          rawData.sublist(rawData.length - 3)[1] !=
              checksumtoRead(payload)[1]) {
        print("corupted data ${[
          ...checksumtoRead(payload),
          0x77
        ]} is not ${rawData.sublist(rawData.length - 3)} for ${rawData[1]}");
        print(rawData);
        rawData.clear();
        print(rawData);
      }
    } catch (e) {
      print("could not verufy the readings");
      return false;
    }
    return true;
  }

  static void setUpdater(void Function() setstate) {
    updater = setstate;
  }

  static void on_discharge_on_charge() async {
    await write(Data.ON_DSICHARGE_ON_CHARGE_PAYLOAD);
    await getBasicInfo();
  }

  static void on_discharge_off_charge() async {
    await write(Data.ON_DSICHARGE_OFF_CHARGE_PAYLOAD);
    await getBasicInfo();
  }

  static void off_discharge_on_charge() async {
    await write(Data.OFF_DSICHARGE_ON_CHARGE_PAYLOAD);
    await getBasicInfo();
  }

  static void off_discharge_off_charge() async {
    await write(Data.OFF_DSICHARGE_OFF_CHARGE_PAYLOAD);
    await getBasicInfo();
  }

  static void reset() async {
    await write(Data.RESET_PAYLOAD);
    await getBasicInfo();
  }

  static void _setWake(bool wakeValue) {
    wake = wakeValue;
  }

  static void setCurrentContext(BuildContext con) {
    context = con;
  }

  static bool get communicatingNow => _communicatingNow;

  static bool get locked => !Data.factoryModeState;

  static lock() async {
    await write(Data.OPEN_FACTORY_MODE);
  }

  static unLock() async {
    await write(Data.OPEN_FACTORY_MODE);
  }

  static get warantyVoided => _warantyVoided;
  static voidWaranty() {
    _warantyVoided = true;
  }

  static readWhatsLeft() async {
    await read(Data.DEVICE_NAME_PAYLOAD);
    await read(Data.MANUF_PAYLOAD);
    await read(Data.BAL_PAYLOAD);
    updater!();
  }
}

class Data {
  //basic regiesteries
  static const BASIC_INFO = 0x03;
  static const CELL_VOLTAGE = 0x04;
  static const DEVICE_NAME = 0x05;
  static const STAT_INFO = 0xAA;
  static const PARAMETERS = 0xFA;
  static const FET_CTRL = 0xE1;
  static const CMD_CTRL = 0x0A;

  //Parameters
  static const BAL_START = 0x26;
  static const MFG_NAME = 0x38;

  //Factory mode
  static const ENTER_FACTORY_MODE = 0x00;
  static const EXIT_FACTORY_MODE = 0x01;
  static const OPEN_FACTORY_MODE = [ENTER_FACTORY_MODE, 0x02, 0x56, 0x78];
  static const CLOSE_FACTORY_MODE = [EXIT_FACTORY_MODE, 0x02, 0x28, 0x28];

  //Read Payloads
  static const BASIC_INFO_PAYLOAD = [BASIC_INFO, 0x00];
  static const CELL_INFO_PAYLOAD = [CELL_VOLTAGE, 0x00];
  static const STATS_PAYLOAD = [STAT_INFO, 0x00];
  static const DEVICE_NAME_PAYLOAD = [DEVICE_NAME, 0x00];

  // 0xfa, 0x03, 0x00, 0x38, 0x10
  static const MANUF_PAYLOAD = [PARAMETERS, 0x03, 0x00, MFG_NAME, 0x10];
  static const BAL_PAYLOAD = [PARAMETERS, 0x03, 0x00, BAL_START, 0x2];

  //write payloads
  static const ON_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x00];
  static const ON_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x01];
  static const OFF_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x02];
  static const OFF_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x03];
  static const RESET_PAYLOAD = [CMD_CTRL, 0x02, 0x04, 0x00];

  static final Map<String, List<int>> _data = {};
  static bool availableData = false;
  static bool? _factory;

  static bool get factoryModeState {
    if (_factory == null) {
      return false;
    }
    return _factory!;
  }

  static String get pack_mv => (_data["pack_mv"] == null)
      ? "0.0"
      : (((_data["pack_mv"]![0] << 8) + _data["pack_mv"]![1]) * 0.01)
          .toStringAsFixed(2);

  static String get pack_ma {
    if (_data["pack_ma"] == null) return "0.00";
    int result =
        (_data["pack_ma"]![1] & 0xFF) | ((_data["pack_ma"]![0] << 8) & 0xFF00);
    // Check the sign bit (MSB)
    if (result & 0x8000 != 0) {
      result = -(0x10000 - result);
    }
    return (result * 0.01).toStringAsFixed(2);
  }

  static String get cycle_cap => (_data["cycle_cap"] == null)
      ? "0.0"
      : (((_data["cycle_cap"]![0] << 8) + _data["cycle_cap"]![1]) * 0.01)
          .toStringAsFixed(1);

  //Battery capacity
  static String get design_cap => (_data["design_cap"] == null)
      ? "0.0"
      : (((_data["design_cap"]![0] << 8) + _data["design_cap"]![1]) * 0.01)
          .toStringAsFixed(1);

  static String get cycle_cnt => (_data["cycle_cnt"] == null)
      ? "0"
      : (((_data["cycle_cnt"]![0] << 8) + _data["cycle_cnt"]![1])).toString();

  static bool get chargeStatus {
    if (_data["fet_status"] == null) return false;
    return (_data["fet_status"]![0] & 0x1) != 0;
  }

  static bool get dischargeStatus {
    if (_data["fet_status"] == null) return false;
    return (_data["fet_status"]![0] & 0x2) != 0;
  }

  static List<String> get curr_err {
    if (_data["curr_err"] == null) return [];
    List<String> err = [];
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
            err.add("SL"); //Software Lock
            break;
          case 13:
            err.add("COBU"); //Chage turned off by user
            break;
          case 14:
            err.add("DOBU"); //Dischage turned off by user
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
    if (_data["date"] == null) return "";
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
    if (_data["bal"] == null) return [];
    List<bool> bal = [];
    int combined = ((_data["bal"]![0] << 8) + _data["bal"]![1]);
    for (int i = 0; i < 16; i++) {
      bool bit = (combined & (1 << i)) != 0;
      bal.add(bit);
    }
    return bal;
  }

  static int get cap_pct =>
      (_data["cap_pct"] == null) ? 0 : _data["cap_pct"]![0];

  static int get cell_cnt =>
      (_data["cell_cnt"] == null) ? 0 : _data["cell_cnt"]![0];

  static int get ntc_cnt =>
      (_data["ntc_cnt"] == null) ? 0 : _data["ntc_cnt"]![0];

  static List<String> get ntc_temp {
    if (_data["ntc_temp"] == null) return [];
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
    List<double> cells = [];
    for (int i = 0; i < cell_cnt; i++) {
      if (_data["cell${i}_mv"] == null) continue;
      cells.add(
          ((_data["cell${i}_mv"]![0] << 8) + _data["cell${i}_mv"]![1]) * 0.001);
    }

    return cells;
  }

  static int get unknown => 0;
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

  static int _getIntValue(List<int>? bytes) {
    if (bytes == null) return 0;
    int value = (bytes[0] << 8) + bytes[1];
    return value;
  }

  static int get device_name_lenght => (_data["device_name_lenght"] == null)
      ? 0
      : _data["device_name_lenght"]![0];

  static String get device_name => (_data["device_name"] == null)
      ? ""
      : String.fromCharCodes(_data["device_name"]!);

  // static int get mfg_name_lenght =>
  //     (_data["mfg_name_lenght"] == null) ? 0 : _data["mfg_name_lenght"]![0];

  static String get mfg_name => (_data["mfg_name"] == null)
      ? "Royer Batteries"
      : String.fromCharCodes(_data["mfg_name"]!);

  static double get bal_start {
    if (_data["bal_start"] == null) return 0.0;
    var bal = (((_data["bal_start"]![0] << 8) + _data["bal_start"]![1]) * 0.01);
    print(bal);
    return bal;
  }

  static String get watts {
    if (_data["pack_ma"] == null || _data["pack_mv"] == null) return "0.0";
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
    if (_data["cycle_cap"] == null ||
        _data["design_cap"] == null ||
        _data["pack_ma"] == null) return "0 Minutes left";

    int capacityLeft = ((_data["cycle_cap"]![0] << 8) + _data["cycle_cap"]![1]);
    int totalCapacity =
        ((_data["design_cap"]![0] << 8) + _data["design_cap"]![1]);
    int AmperageInputAndOutput =
        (_data["pack_ma"]![1] & 0xFF) | ((_data["pack_ma"]![0] << 8) & 0xFF00);
    // Check the sign bit (MSB)
    if (AmperageInputAndOutput & 0x8000 != 0) {
      AmperageInputAndOutput = -(0x10000 - AmperageInputAndOutput);
    }
    if (AmperageInputAndOutput == 0) {
      return "999 hours left";
    }

    var decimalHours = capacityLeft / AmperageInputAndOutput;
    if (!decimalHours.isNegative) {
      decimalHours = (totalCapacity - capacityLeft) / AmperageInputAndOutput;
    }

    int hours = decimalHours.truncate();
    int minutes = ((decimalHours - hours) * 60).round();

    // Returns hours and minutes left, but if minutes is less than 10, it adds a 0 before the minutes
    return "${hours}H ${(minutes.abs() < 10) ? "0$minutes" : "$minutes"}M ${!decimalHours.isNegative ? "Time to full" : "left"}"
        .replaceAll("-", "");

    // TODO: Possibly add pulsatting red When hours is less than 2
  }

  static double get celldif {
    if (!availableData) return 0;
    var current = cell_mv[0];
    for (var i = 0; i < cell_cnt; i++) {
      if (current > cell_mv[i]) {
        current = cell_mv[i];
      }
    }

    var smallest = current;
    current = cell_mv[0];
    for (var i = 0; i < cell_cnt; i++) {
      if (current < cell_mv[i]) {
        current = cell_mv[i];
      }
    }
    var biggest = current;
    return biggest - smallest;
  }

  static bool setBatchData(List<int> batch, int registerResponse) {
    setAvailableData(true);
    if (registerResponse == BASIC_INFO) {
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
        print(
            "Data humidity, alarm, full_charge_capacity, remining_capacity and balance curent was not found in basic info");
      }
      setAvailableData(false);
      return true;
    }

    if (registerResponse == CELL_VOLTAGE) {
      int j = 0;
      for (int i = 0; i < cell_cnt; i++) {
        var key = "cell${i}_mv";
        _data[key] = batch.sublist(j, j + 2);
        j += 2;
      }
      setAvailableData(false);
      return true;
    }

    if (registerResponse == STAT_INFO) {
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

    if (registerResponse == DEVICE_NAME) {
      // _data["device_name_lenght"] = [batch[0]];
      _data["device_name"] = batch;
      setAvailableData(false);
      return true;
    }

    if (registerResponse == PARAMETERS) {
      switch (batch[1]) {
        case BAL_START:
          _data["bal_start"] = batch.sublist(3, 5);
          setAvailableData(false);
          return true;
        case MFG_NAME:
          var mfg_name_lenght = batch[3];
          _data["mfg_name"] = batch.sublist(4, 4 + mfg_name_lenght);
          setAvailableData(false);
          return true;
      }

      setAvailableData(false);
      return true;
    }

    if (registerResponse == ENTER_FACTORY_MODE) {
      _factory = true;
      setAvailableData(false);
      return true;
    }

    if (registerResponse == EXIT_FACTORY_MODE) {
      _factory = false;
      setAvailableData(false);
      return true;
    }
    print("uncaught registery");
    setAvailableData(false);
    return false;
  }

  static setAvailableData(bool isBLEConnected) {
    availableData = isBLEConnected;
  }

  static clear() {
    setAvailableData(false);
    _data.clear();
  }
}
