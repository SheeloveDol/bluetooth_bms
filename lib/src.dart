// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceConnectionState { connecting, connected, disconnected }

class Be {
  static BluetoothDevice? savedDevice;
  static DeviceConnectionState _currentState =
      DeviceConnectionState.disconnected;
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
  static Function? _onConectedCb;
  static Function? factoryUpdater;
  static bool _communicatingNow = false;
  static bool _warantyVoided = false;

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

  static setDeviceTitle(String title) {
    title = title;
  }

  static Future<bool> connect(BluetoothDevice device) async {
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
    if (error != null) {
      setConnectionState(DeviceConnectionState.disconnected);
      title ??= "Bluetooth Device";
      quicktell(context, "failed to connect to $title");
      return false;
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
      setConnectionState(DeviceConnectionState.disconnected);
      quicktell(context, "Device $title is not compatible");
      return false;
    }

    setConnectionState(DeviceConnectionState.connected);

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
        setConnectionState(DeviceConnectionState.connected);
        _onConectedCb!();
        return true;
      }
      Data.clear();
      setConnectionState(DeviceConnectionState.disconnected);
      quicktell(context, "Could not read from $title");
      return false;
    } catch (e) {
      setConnectionState(DeviceConnectionState.disconnected);
      quicktell(context, "failed to read from $title");
      return false;
    }
  }

  static void onConnected(Function cb) {
    _onConectedCb = cb;
  }

  static Future<bool> getBasicInfo() async {
    var readSuccessFully = await read(Data.BASIC_INFO_PAYLOAD);
    if (readSuccessFully) {
      Data.setAvailableData(true);
      updater!();
    }

    return readSuccessFully;
  }

  static Future<bool> getCellInfo() async {
    var readSuccessFully = await read(Data.CELL_INFO_PAYLOAD);
    if (readSuccessFully) {
      Data.setAvailableData(true);
      updater!();
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
    _onConectedCb = null;
    if (totaly) {
      savedDevice = null;
      title = null;
      setConnectionState(DeviceConnectionState.disconnected);
    }
  }

  static Future<bool> resetConnection() async {
    print("RECONNECTING");
    setConnectionState(DeviceConnectionState.connecting);
    await disconnect(totaly: false);
    Data.clear();
    _onConectedCb = null;
    try {
      await savedDevice!.connect();
      await savedDevice!.discoverServices();
      print("RECONNECTED");
      setConnectionState(DeviceConnectionState.connected);
      return true;
    } catch (e) {
      print("[FATAL] DISCONNECTED");
      disconnect(totaly: true);
      quicktell(context, "Lost connection with device");
      return false;
    }
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
    if (_currentState != DeviceConnectionState.connected) {
      _communicatingNow = false;
      print("no device is currently connected to read");
      return false;
    }

    while (_communicatingNow) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _communicatingNow = true;
    List<int> answer = [];
    var good = false;

    int k = 0;
    do {
      //subscribe to read charac
      await readCharacteristics!.setNotifyValue(true);

      var notifySub = readCharacteristics!.onValueReceived.listen((event) {
        answer.addAll(event);
      });
      List<int> cmd = [
        0xDD,
        0xa5,
        ...payload,
        ...checksumtoRead(payload),
        0x77
      ];
      print("sending read command : $cmd");
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
        if (j > 5) break;
      } while (answer.isEmpty);
      notifySub.cancel();
      good = _verifyReadings(answer);
      print(answer);

      if (!good) await resetConnection();
      k++;
      if (k > 2) {
        _communicatingNow = false;
        return false;
      }
    } while (!good);

    if (answer.isEmpty) {
      _communicatingNow = false;
      return false;
    }
    var data = answer.sublist(4, answer.length - 3);
    good = Data.setBatchData(data, answer[1]);
    _communicatingNow = false;
    return good;
  }

  static Future<List<int>> parameterRead(List<int> payload) async {
    if (_currentState != DeviceConnectionState.connected) {
      print("no device is currently connected to read");
      return [];
    }
    while (_communicatingNow) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _communicatingNow = true;
    List<int> answer = [];
    var good = false;

    //subscribe to read charac
    await readCharacteristics!.setNotifyValue(true);

    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      answer.addAll(event);
    });
    List<int> cmd = [0xDD, 0xa5, ...payload, ...checksumtoRead(payload), 0x77];
    print("sendind read command : $cmd");
    for (var i = (wake) ? 0 : 1; i < 2; i++) {
      await writeCharacteristics!.write(cmd, withoutResponse: true);
      if (wake) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      _setWake(false);
    }
    int k = 0;
    while (answer.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      k++;
      if (k > 4) {
        notifySub.cancel();
        _communicatingNow = false;
        print("[ERR][returned] : $answer");
        return [];
      }
    }
    notifySub.cancel();
    good = _verifyReadings(answer);
    List<int> data = [];
    if (good) {
      data.addAll(answer.sublist(4, answer.length - 3));
    }
    _communicatingNow = false;

    print("[returned] : $answer");
    return data;
  }

  static Future<List<int>> write(List<int> payload) async {
    if (_currentState != DeviceConnectionState.connected) {
      _communicatingNow = false;
      print("no device is currently connected to write");
      return [0, 999];
    }

    while (_communicatingNow) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _communicatingNow = true;

    //TODO: Do we still need this _setWake function?
    Future.delayed(const Duration(minutes: 1)).then((value) => _setWake(true));
    List<int> confirmation = [];

    //subscribe to read charac
    await readCharacteristics!.setNotifyValue(true);
    var notifySub = readCharacteristics!.onValueReceived.listen((event) {
      confirmation.addAll(event);
    });
    List<int> cmd = [0xDD, 0x5a, ...payload, ...checksumtoRead(payload), 0x77];
    print("writing command : $cmd");
    for (var i = (wake) ? 0 : 1; i < 2; i++) {
      await writeCharacteristics!.write(cmd, withoutResponse: true);
      if (wake) await Future.delayed(const Duration(milliseconds: 300));
      _setWake(false);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    while (confirmation.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    print("received from write command : $confirmation");
    _communicatingNow = false;
    notifySub.cancel();
    return confirmation;
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
        Data.clear();
        print(rawData);
      }
    } catch (e) {
      print("could not verify the readings ${e.toString()}");
      return false;
    }
    return true;
  }

  static void setUpdater(void Function() setstate) {
    updater = setstate;
  }

  static void setFactryUpdater(void Function() setstate) {
    factoryUpdater = setstate;
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

  static void _setWake(bool wakeValue) {
    wake = wakeValue;
  }

  static void setCurrentContext(BuildContext con) {
    context = con;
  }

  static bool get communicatingNow => _communicatingNow;

  static bool get locked => !Data.factoryModeState;

  static lock() async {
    if (locked) {
      return;
    }
    var batch = await write(Data.CLOSE_FACTORY_MODE);
    Data.setBatchData(batch, batch[1]);
    factoryUpdater!();
  }

  static unLock() async {
    if (!locked) {
      return;
    }
    var batch = await write(Data.OPEN_FACTORY_MODE);
    Data.setBatchData(batch, batch[1]);
    factoryUpdater!();
  }

  static resetAlarm() async {
    await write(Data.RESET_PAYLOAD);
    updater!();
  }

  static voidWaranty() {
    _warantyVoided = true;
  }

  static void readWhatsLeft() async {
    await read(Data.DEVICE_NAME_PAYLOAD);
    updater!();
  }

  static void readSettings() async {
    Data.setAvailableData(false);
    await write(Data.CLR_PW_CMD);
    await write(Data.USE_PW_CMD);
    await write(Data.OPEN_FACTORY_MODE);
    var batch = await parameterRead(Data.ALL_PARAMS_PAYLOAD);
    if (batch.isEmpty) {
      print("No data was found trying to read all at the same time");
      batch = await recursiveParamRead(Data.legacy(Data.DESIGN_CAP), []);
    }
    await write(Data.CLOSE_FACTORY_MODE);
    if (batch.isNotEmpty) {
      Data.setBatchData(batch, Data.PARAMETERS);
    }
    updater!();
  }

  static Future<List<int>> recursiveParamRead(
      int param, List<int> batch) async {
    if (param == Data.ADV_LOW_V_TRIG + 1) {
      return batch;
    }
    List<int> payload = [param, 0x0];
    var b = await parameterRead(payload);
    if (b.isNotEmpty) {
      batch.addAll(b);
      return recursiveParamRead(param + 1, batch);
    } else {
      return batch;
    }
  }

  static void setConnectionState(DeviceConnectionState state) {
    _currentState = state;
    updater!();
  }

  static bool get warantyVoided => _warantyVoided;
  static DeviceConnectionState get conectionState => _currentState;
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
  static const CLR_PW = 0x09;
  static const USE_PW = 0x06;

  // Parameters registries
  static const DESIGN_CAP = 0x00;
  static const CYCLE_CAP = 0x01;
  static const CELL_FULL_MV = 0x02;
  static const CELL_MIN_MV = 0x03;
  static const CELL_D_PERC = 0x04;
  // Production Date and serial number is unnecessary
  static const CYCLES = 0x07;
  static const PROT_C_HIGH_TEMP_TRIG = 0x08;
  static const PROT_C_HIGH_TEMP_REL = 0x09;
  static const PROT_C_LOW_TEMP_TRIG = 0x0A;
  static const PROT_C_LOW_TEMP_REL = 0x0B;
  static const PROT_D_HIGH_TEMP_TRIG = 0x0C;
  static const PROT_D_HIGH_TEMP_REL = 0x0D;
  static const PROT_D_LOW_TEMP_TRIG = 0x0E;
  static const PROT_D_LOW_TEMP_REL = 0x0F;
  static const PROT_BAT_HIGH_TRIG = 0x10;
  static const PROT_BAT_HIGH_REL = 0x11;
  static const PROT_BAT_LOW_TRIG = 0x12;
  static const PROT_BAT_LOW_REL = 0x13;
  static const PROT_CELL_HIGH_TRIG = 0x14;
  static const PROT_CELL_HIGH_REL = 0x15;
  static const PROT_CELL_LOW_TRIG = 0x16;
  static const PROT_CELL_LOW_REL = 0x17;
  static const PROT_CH_HIGH_MA = 0x18;
  static const PROT_CH_LOW_MA = 0x19;
  static const BAL_START = 0x1A;
  static const BAL_DELTA = 0x1B;
  static const RESISTOR = 0x1C;
  static const FUNCTION = 0x1D;
  static const NTC_EN = 0x1E;
  static const CELL_CNT = 0x1F;
  static const DEL_FET_CTRL_SW = 0x20;
  static const DEL_LED = 0x21;
  // TODO: SEE VALUES FOR THIS GAP
  static const ADV_HIGH_V_TRIG = 0x26;
  static const ADV_LOW_V_TRIG = 0x27;
  // after here, the two modes of retreiving info from the bms gets complicated
  static const ADV_PROT_HIGH_MA = 0x28;
  static const SC_PROT_SET = 0x29;
  static const DEL_ADV_HIGH_LOW_V = 0x2A;
  static const DEL_SC_REL = 0x2B;
  static const DEL_LOW_CH_TEMP = 0x2C;
  static const DEL_HIGH_CH_TEMP = 0x2D;
  static const DEL_LOW_D_TEMP = 0x2E;
  static const DEL_HIGH_D_TEMP = 0x2F;
  static const DEL_LOW_BAT_V = 0x30;
  static const DEL_HIGH_BAT_V = 0x31;
  static const DEL_LOW_CELL_V = 0x32;
  static const DEL_HIGH_CELL_V = 0x33;
  static const DEL_HIGH_MA = 0x34;
  static const DEL_HIGH_MA_REL = 0x35;
  static const DEL_LOW_MA = 0x36;
  static const DEL_LOW_MA_REL = 0x37;
  static const MFG_NAME = 0x38;

  //Legacy way of getting parameters
  static const LEGACY_SC_DSGOC2 = 0x38;
  static const LEGACY_CXVP = 0x39;
  static const LEGACY_DEL_CH_LOW_HIGH_TEMP = 0x3A;
  static const LEGACY_DEL_D_LOW_HIGH_TEMP = 0x3B;
  static const LEGACY_DEL_PACK_LOW_HIGH_V = 0x3C;
  static const LEGACY_DEL_CELL_LOW_HIGH_V = 0x3D;
  static const LEGACY_DEL_CH_TRIG_REL_MA = 0x3E;
  static const LEGACY_DEL_D_TRIG_REL_MA = 0x3F;
  static const LEGACY_MFG_NAME = 0xA0;
  // Unnecessary values for this GAP
  static const GPS_SHUTD = 0x68;
  static const DEL_GPS_SHUTD = 0x69;

  /*TODO:
  static const CELL_100 = 0;
  static const CELL_90 = 0;
  static const CELL_80 = 0;
  static const CELL_70 = 0;
  static const CELL_60 = 0;
  static const CELL_50 = 0;
  static const CELL_40 = 0;
  static const CELL_30 = 0;
  static const CELL_20 = 0;
  static const CELL_10 = 0; */

  static final Map<int, String> parameterRegistry = {
    DESIGN_CAP: 'DESIGN_CAP',
    CYCLE_CAP: 'CYCLE_CAP',
    CELL_FULL_MV: 'CELL_FULL_MV',
    CELL_MIN_MV: 'CELL_MIN_MV',
    CELL_D_PERC: 'CELL_D_PERC',
    CYCLES: 'CYCLES',
    PROT_C_HIGH_TEMP_TRIG: 'PROT_C_HIGH_TEMP_TRIG',
    PROT_C_HIGH_TEMP_REL: 'PROT_C_HIGH_TEMP_REL',
    PROT_C_LOW_TEMP_TRIG: 'PROT_C_LOW_TEMP_TRIG',
    PROT_C_LOW_TEMP_REL: 'PROT_C_LOW_TEMP_REL',
    PROT_D_HIGH_TEMP_TRIG: 'PROT_D_HIGH_TEMP_TRIG',
    PROT_D_HIGH_TEMP_REL: 'PROT_D_HIGH_TEMP_REL',
    PROT_D_LOW_TEMP_TRIG: 'PROT_D_LOW_TEMP_TRIG',
    PROT_D_LOW_TEMP_REL: 'PROT_D_LOW_TEMP_REL',
    PROT_BAT_HIGH_TRIG: 'PROT_BAT_HIGH_TRIG',
    PROT_BAT_HIGH_REL: 'PROT_BAT_HIGH_REL',
    PROT_BAT_LOW_TRIG: 'PROT_BAT_LOW_TRIG',
    PROT_BAT_LOW_REL: 'PROT_BAT_LOW_REL',
    PROT_CELL_HIGH_TRIG: 'PROT_CELL_HIGH_TRIG',
    PROT_CELL_HIGH_REL: 'PROT_CELL_HIGH_REL',
    PROT_CELL_LOW_TRIG: 'PROT_CELL_LOW_TRIG',
    PROT_CELL_LOW_REL: 'PROT_CELL_LOW_REL',
    PROT_CH_HIGH_MA: 'PROT_CH_HIGH_MA',
    PROT_CH_LOW_MA: 'PROT_CH_LOW_MA',
    BAL_START: 'BAL_START',
    BAL_DELTA: 'BAL_DELTA',
    RESISTOR: 'RESISTOR',
    FUNCTION: 'FUNCTION',
    NTC_EN: 'NTC_EN',
    CELL_CNT: 'CELL_CNT',
    DEL_FET_CTRL_SW: 'DEL_FET_CTRL_SW',
    DEL_LED: 'DEL_LED',
    // volt percent
    ADV_HIGH_V_TRIG: 'ADV_HIGH_V_TRIG',
    ADV_LOW_V_TRIG: 'ADV_LOW_V_TRIG',
    ADV_PROT_HIGH_MA: 'ADV_PROT_HIGH_MA',
    SC_PROT_SET: 'SC_PROT_SET',
    DEL_ADV_HIGH_LOW_V: 'DEL_ADV_HIGH_LOW_V',
    DEL_SC_REL: 'DEL_SC_REL',
    DEL_LOW_CH_TEMP: 'DEL_LOW_CH_TEMP',
    DEL_HIGH_CH_TEMP: 'DEL_HIGH_CH_TEMP',
    DEL_LOW_D_TEMP: 'DEL_LOW_D_TEMP',
    DEL_HIGH_D_TEMP: 'DEL_HIGH_D_TEMP',
    DEL_LOW_BAT_V: 'DEL_LOW_BAT_V',
    DEL_HIGH_BAT_V: 'DEL_HIGH_BAT_V',
    DEL_LOW_CELL_V: 'DEL_LOW_CELL_V',
    DEL_HIGH_CELL_V: 'DEL_HIGH_CELL_V',
    DEL_HIGH_MA: 'DEL_HIGH_MA',
    DEL_HIGH_MA_REL: 'DEL_HIGH_MA_REL',
    DEL_LOW_MA: 'DEL_LOW_MA',
    DEL_LOW_MA_REL: 'DEL_LOW_MA_REL',
    GPS_SHUTD: 'GPS_SHUTD',
    DEL_GPS_SHUTD: 'DEL_GPS_SHUTD',
    // volt percent
  };

  // password : 'J1B2D4'
  static const PW = [0x07, 0x06, 0x4A, 0x31, 0x42, 0x32, 0x44, 0x34];
  static const CLR_PW_CMD = [CLR_PW, ...PW];
  static const USE_PW_CMD = [USE_PW, ...PW];

  // Legacy parameters
  static int legacy(int param) {
    if (param > ADV_LOW_V_TRIG || param < 0) {
      throw "Unaceptable legacy parameter";
    }
    param = param + 0x10;
    return param;
  }

  //Factory mode
  static const ENTER_FACTORY_MODE = 0x00;
  static const EXIT_FACTORY_MODE = 0x01;
  static const OPEN_FACTORY_MODE = [ENTER_FACTORY_MODE, 0x02, 0x56, 0x78];
  static const CLOSE_FACTORY_MODE = [EXIT_FACTORY_MODE, 0x02, 0x28, 0x28];

  //Basic Read Payloads
  static const BASIC_INFO_PAYLOAD = [BASIC_INFO, 0x00];
  static const CELL_INFO_PAYLOAD = [CELL_VOLTAGE, 0x00];
  static const STATS_PAYLOAD = [STAT_INFO, 0x00];
  static const DEVICE_NAME_PAYLOAD = [DEVICE_NAME, 0x00];

  // Legacy read commands
  static const LEGACY_MANUF_PAYLOAD = [LEGACY_MFG_NAME, 0x02, 0x10, 0x00];

  // Parameters payload read, i want registry 0 all the way to 55    here |
  static const ALL_PARAMS_PAYLOAD = [PARAMETERS, 0x03, 0x00, DESIGN_CAP, 56];
  static const MANUF_PAYLOAD = [PARAMETERS, 0x03, 0x00, MFG_NAME, 10];

  //command write payloads
  static const ON_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x00];
  static const ON_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x01];
  static const OFF_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x02];
  static const OFF_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x03];
  static const RESET_PAYLOAD = [CMD_CTRL, 0x02, 0x04, 0x00];

  static final Map<String, List<int>> _data = {};
  static final Map<String, List<int>> _settingsData = {};
  static bool _availableData = false;
  static bool? _factory;

  //Basic info and Cell info and Stats info and Device name
  static bool get factoryModeState => (_factory == null) ? false : _factory!;
  static double get pack_mv => _unsigned10Mili(_data["pack_mv"]);
  static double get pack_ma => _signed10Mili(_data["pack_ma"]);
  static String get cycle_cap =>
      _unsigned10Mili(_data["cycle_cap"]).toStringAsFixed(1);
  static String get design_cap =>
      _unsigned10Mili(_data["design_cap"]).toStringAsFixed(1);
  static String get cycle_cnt => _oneUnit(_data["cycle_cnt"]).toString();
  static bool get chargeStatus =>
      _oneBool(_data["fet_status"], 0x01); // position 01
  static bool get dischargeStatus =>
      _oneBool(_data["fet_status"], 0x02); // position 10
  static int get cap_pct => _oneByteOneUnit(_data["cap_pct"]);
  static int get cell_cnt => _oneByteOneUnit(_data["cell_cnt"]);
  static int get ntc_cnt => _oneByteOneUnit(_data["ntc_cnt"]);
  static int get unknown => 0;
  static int get sc_err_cnt => _oneUnit(_data["sc_err_cnt"]);
  static int get chgoc_err_cnt => _oneUnit(_data["chgoc_err_cnt"]);
  static int get dsgoc_err_cnt => _oneUnit(_data["dsgoc_err_cnt"]);
  static int get covp_err_cnt => _oneUnit(_data["covp_err_cnt"]);
  static int get cuvp_err_cnt => _oneUnit(_data["cuvp_err_cnt"]);
  static int get chgot_err_cnt => _oneUnit(_data["chgot_err_cnt"]);
  static int get chgut_err_cnt => _oneUnit(_data["chgut_err_cnt"]);
  static int get dsgot_err_cnt => _oneUnit(_data["dsgot_err_cnt"]);
  static int get dsgut_err_cnt => _oneUnit(_data["dsgut_err_cnt"]);
  static int get povp_err_cnt => _oneUnit(_data["povp_err_cnt"]);
  static int get puvp_err_cnt => _oneUnit(_data["puvp_err_cnt"]);
  static String get device_name => (_data["device_name"] == null)
      ? ""
      : String.fromCharCodes(_data["device_name"]!);

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
    var dateData = _combine(_data["date"]!, 0, 1);
    int year = (dateData >> 9) & 0x7F;
    int month = (dateData >> 5) & 0xF;
    int day = dateData & 0x1F;

    // Adjust year to account for the base year 2000
    year += 2000;
    return "$day/$month/$year";
  }

  static List<bool> get bal {
    if (_data["bal"] == null) return [for (var i = 0; i < 16; i++) false];
    List<bool> bal = [];
    int combined = _combine(_data["bal"]!, 0, 1);
    for (int i = 0; i < 16; i++) {
      bool bit = (combined & (1 << i)) != 0;
      bal.add(bit);
    }
    return bal;
  }

  static List<String> get ntc_temp {
    if (_data["ntc_temp"] == null) return [];
    List<String> temps = [];
    int j = 0;
    for (var i = 0; i < ntc_cnt; i++) {
      temps.add(
          (_kelvinsToCelcius(_data["ntc_temp"], j, j + 1)).toStringAsFixed(1));
      j += 2;
    }
    return temps;
  }

  static List<double> get cell_mv {
    List<double> cells = [];
    for (int i = 0; i < cell_cnt; i++) {
      if (_data["cell${i}_mv"] == null) {
        cells.add(0.0);
        continue;
      }
      cells.add(_unsignedOneMili(_data["cell${i}_mv"]));
    }
    return cells;
  }

  static double get bal_start => _unsigned10Mili(_data["bal_start"]);

  static String get watts => (pack_ma * pack_mv).round().toString();

  static String get timeLeft {
    if (_data["cycle_cap"] == null ||
        _data["design_cap"] == null ||
        _data["pack_ma"] == null) {
      return "0 Minutes left";
    }

    int capacityLeft = _combine(_data["cycle_cap"]!, 0, 1);
    int totalCapacity = _combine(_data["design_cap"]!, 0, 1);
    int amperageInputAndOutput = _combineSigned(_data["pack_ma"]!, 0, 1);
    // Check the sign bit (MSB)
    if (amperageInputAndOutput & 0x8000 != 0) {
      amperageInputAndOutput = -(0x10000 - amperageInputAndOutput);
    }
    if (amperageInputAndOutput == 0) {
      return "999 hours left";
    }

    var decimalHours = capacityLeft / amperageInputAndOutput;
    if (!decimalHours.isNegative) {
      decimalHours = (totalCapacity - capacityLeft) / amperageInputAndOutput;
    }

    int hours = decimalHours.truncate();
    int minutes = ((decimalHours - hours) * 60).round();

    // Returns hours and minutes left, but if minutes is less than 10, it adds a 0 before the minutes
    return "${hours}H ${(minutes.abs() < 10) ? "0$minutes" : "$minutes"}M ${!decimalHours.isNegative ? "Time to full" : "left"}"
        .replaceAll("-", "");

    // TODO: Possibly add pulsatting red When hours is less than 2
  }

  static double get celldif {
    if (cell_mv.isEmpty) return 0;
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
    setAvailableData(false);
    switch (registerResponse) {
      case BASIC_INFO:
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
          _data["remaining_capacity"] =
              batch.sublist(afterNtc + 3, afterNtc + 5);
          _data["balance_current"] = batch.sublist(afterNtc + 5, afterNtc + 7);
        } catch (e) {
          print(
              "Data humidity, alarm, full_charge_capacity, remining_capacity and balance current was not found");
        }
        return true;

      case CELL_VOLTAGE:
        int j = 0;
        for (int i = 0; i < cell_cnt; i++) {
          var key = "cell${i}_mv";
          _data[key] = batch.sublist(j, j + 2);
          j += 2;
        }
        return true;

      case STAT_INFO:
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
        return true;

      case DEVICE_NAME:
        _data["device_name"] = batch;
        return true;

      case PARAMETERS:
        return _handleParameterData(batch);

      case ENTER_FACTORY_MODE:
        print("ENTER_FACTORY_MODE");
        _factory = true;
        return true;

      case EXIT_FACTORY_MODE:
        print("EXIT_FACTORY_MODE");
        _factory = false;
        return true;

      default:
        print("uncaught registery $registerResponse");
        return false;
    }
  }

  static bool _handleParameterData(List<int> batch) {
    var register = batch[1];
    print("handeling ${parameterRegistry[register]} payload : $batch");
    return _handleBatchParameterData(batch.sublist(3), register);
  }

  // Parameters info
  static String get param_prot_c_high_temp_trig =>
      _kelvinsToCelcius(_settingsData["PROT_C_HIGH_TEMP_TRIG"])
          .toStringAsFixed(1);
  static String get param_prot_c_high_temp_rel =>
      _kelvinsToCelcius(_settingsData["PROT_C_HIGH_TEMP_REL"])
          .toStringAsFixed(1);
  static String get param_prot_c_low_temp_trig =>
      _kelvinsToCelcius(_settingsData["PROT_C_LOW_TEMP_TRIG"])
          .toStringAsFixed(1);
  static String get param_prot_c_low_temp_rel =>
      _kelvinsToCelcius(_settingsData["PROT_C_LOW_TEMP_REL"])
          .toStringAsFixed(1);
  static String get param_prot_d_high_temp_trig =>
      _kelvinsToCelcius(_settingsData["PROT_D_HIGH_TEMP_TRIG"])
          .toStringAsFixed(1);
  static String get param_prot_d_high_temp_rel =>
      _kelvinsToCelcius(_settingsData["PROT_D_HIGH_TEMP_REL"])
          .toStringAsFixed(1);
  static String get param_prot_d_low_temp_trig =>
      _kelvinsToCelcius(_settingsData["PROT_D_LOW_TEMP_TRIG"])
          .toStringAsFixed(1);
  static String get param_design_cap =>
      _unsigned10Mili(_settingsData["DESIGN_CAP"]).toStringAsFixed(2);
  static String get param_cycle_cap =>
      _unsigned10Mili(_settingsData["CYCLE_CAP"]).toStringAsFixed(2);
  static String get param_cell_full_mv =>
      _unsignedOneMili(_settingsData["CELL_FULL_MV"]).toStringAsFixed(2);
  static String get param_cell_min_mv =>
      _unsignedOneMili(_settingsData["CELL_MIN_MV"]).toStringAsFixed(2);
  static String get param_cell_d_perc =>
      _unsigned100Mili(_settingsData["CELL_D_PERC"]).toStringAsFixed(2);
  static String get param_prot_d_low_temp_rel =>
      _kelvinsToCelcius(_settingsData["PROT_D_LOW_TEMP_REL"])
          .toStringAsFixed(1);
  static String get param_prot_bat_high_trig =>
      _unsigned10Mili(_settingsData["PROT_BAT_HIGH_TRIG"]).toStringAsFixed(2);
  static String get param_prot_bat_high_rel =>
      _unsigned10Mili(_settingsData["PROT_BAT_HIGH_REL"]).toStringAsFixed(2);
  static String get param_prot_bat_low_trig =>
      _unsigned10Mili(_settingsData["PROT_BAT_LOW_TRIG"]).toStringAsFixed(2);
  static String get param_prot_bat_low_rel =>
      _unsigned10Mili(_settingsData["PROT_BAT_LOW_REL"]).toStringAsFixed(2);
  static String get param_prot_cell_high_trig =>
      _unsignedOneMili(_settingsData["PROT_CELL_HIGH_TRIG"]).toStringAsFixed(2);
  static String get param_prot_cell_high_rel =>
      _unsignedOneMili(_settingsData["PROT_CELL_HIGH_REL"]).toStringAsFixed(2);
  static String get param_prot_cell_low_trig =>
      _unsignedOneMili(_settingsData["PROT_CELL_LOW_TRIG"]).toStringAsFixed(2);
  static String get param_prot_cell_low_rel =>
      _unsignedOneMili(_settingsData["PROT_CELL_LOW_REL"]).toStringAsFixed(2);
  static String get param_prot_ch_high_ma =>
      _unsigned10Mili(_settingsData["PROT_CH_HIGH_MA"]).toStringAsFixed(2);
  static String get param_prot_ch_low_ma =>
      _unsigned10Mili(_settingsData["PROT_CH_LOW_MA"]).toStringAsFixed(2);
  static String get param_bal_start =>
      _unsignedOneMili(_settingsData["BAL_START"]).toStringAsFixed(2);
  static String get param_bal_delta =>
      _unsignedOneMili(_settingsData["BAL_DELTA"]).toStringAsFixed(2);
  static String get param_resistor =>
      _unsigned100Mili(_settingsData["RESISTOR"]).toStringAsFixed(2);
  static String get param_adv_high_v_trig =>
      _unsignedOneMili(_settingsData["ADV_HIGH_V_TRIG"]).toStringAsFixed(2);
  static String get param_adv_low_v_trig =>
      _unsignedOneMili(_settingsData["ADV_LOW_V_TRIG"]).toStringAsFixed(2);
  static String get mfg_name => (_data["mfg_name"] == null)
      ? "Royer Batteries"
      : String.fromCharCodes(_data["mfg_name"]!);
  static String get param_gps_shutd =>
      _unsignedOneMili(_settingsData["GPS_SHUTD"]).toStringAsFixed(2);

  static int get param_cell_cnt => _oneUnit(_settingsData["CELL_CNT"]);
  static int get param_cycles => _oneUnit(_settingsData["CYCLES"]);
  static int get param_del_fet_ctrl_sw =>
      _oneUnit(_settingsData["DEL_FET_CTRL_SW"]);
  static int get param_del_led => 0; //_oneUnit(_settingsData["DEL_LED"]);
  static int get param_del_sc_rel => _oneUnit(_settingsData["DEL_SC_REL"]);
  static int get param_del_low_ch_temp =>
      _oneUnit(_settingsData["DEL_LOW_CH_TEMP"]);
  static int get param_del_high_ch_temp =>
      _oneUnit(_settingsData["DEL_HIGH_CH_TEMP"]);
  static int get param_del_low_d_temp =>
      _oneUnit(_settingsData["DEL_LOW_D_TEMP"]);
  static int get param_del_high_d_temp =>
      _oneUnit(_settingsData["DEL_HIGH_D_TEMP"]);
  static int get param_del_low_bat_v =>
      _oneUnit(_settingsData["DEL_LOW_BAT_V"]);
  static int get param_del_high_bat_v =>
      _oneUnit(_settingsData["DEL_HIGH_BAT_V"]);
  static int get param_del_low_cell_v =>
      _oneUnit(_settingsData["DEL_LOW_CELL_V"]);
  static int get param_del_high_cell_v =>
      _oneUnit(_settingsData["DEL_HIGH_CELL_V"]);
  static int get param_del_high_ma => _oneUnit(_settingsData["DEL_HIGH_MA"]);
  static int get param_del_high_ma_rel =>
      _oneUnit(_settingsData["DEL_HIGH_MA_REL"]);
  static int get param_del_low_ma => _oneUnit(_settingsData["DEL_LOW_MA"]);
  static int get param_del_low_ma_rel =>
      _oneUnit(_settingsData["DEL_LOW_MA_REL"]);
  static int get param_del_gps_shutd =>
      _oneUnit(_settingsData["DEL_GPS_SHUTD"]);

  static String get param_function =>
      _unsigned10Mili(_settingsData["FUNCTION"]).toStringAsFixed(2);
  static String get param_ntc_en =>
      _unsigned10Mili(_settingsData["NTC_EN"]).toStringAsFixed(2);
  static String get param_adv_prot_high_ma =>
      _unsigned10Mili(_settingsData["ADV_PROT_HIGH_MA"]).toStringAsFixed(2);
  static String get param_sc_prot_set =>
      _unsigned10Mili(_settingsData["SC_PROT_SET"]).toStringAsFixed(2);
  static String get param_del_adv_high_low_v =>
      _unsigned10Mili(_settingsData["DEL_ADV_HIGH_LOW_V"]).toStringAsFixed(2);

  static bool _handleBatchParameterData(List<int> batch, int param) {
    if (batch.isEmpty) {
      return true;
    }
    if (param == DEL_GPS_SHUTD) {
      _settingsData["DEL_GPS_SHUTD"] = batch.sublist(0, 2);
      print(" [param] ${parameterRegistry[param]}:$param_del_gps_shutd");
      return true;
    }

    switch (param) {
      case DESIGN_CAP:
        _settingsData["DESIGN_CAP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_design_cap");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CYCLE_CAP:
        _settingsData["CYCLE_CAP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cycle_cap");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CELL_FULL_MV:
        _settingsData["CELL_FULL_MV"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cell_full_mv");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CELL_MIN_MV:
        _settingsData["CELL_MIN_MV"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cell_min_mv");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CELL_D_PERC:
        _settingsData["CELL_D_PERC"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cell_d_perc");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CYCLES:
        _settingsData["CYCLES"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cell_d_perc");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_C_HIGH_TEMP_TRIG:
        _settingsData["PROT_C_HIGH_TEMP_TRIG"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_c_high_temp_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_C_HIGH_TEMP_REL:
        _settingsData["PROT_C_HIGH_TEMP_REL"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_c_high_temp_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_C_LOW_TEMP_TRIG:
        _settingsData["PROT_C_LOW_TEMP_TRIG"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_c_low_temp_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_C_LOW_TEMP_REL:
        _settingsData["PROT_C_LOW_TEMP_REL"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_c_low_temp_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_D_HIGH_TEMP_TRIG:
        _settingsData["PROT_D_HIGH_TEMP_TRIG"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_d_high_temp_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_D_HIGH_TEMP_REL:
        _settingsData["PROT_D_HIGH_TEMP_REL"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_d_high_temp_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_D_LOW_TEMP_TRIG:
        _settingsData["PROT_D_LOW_TEMP_TRIG"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_d_low_temp_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_D_LOW_TEMP_REL:
        _settingsData["PROT_D_LOW_TEMP_REL"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_d_low_temp_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_BAT_HIGH_TRIG:
        _settingsData["PROT_BAT_HIGH_TRIG"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_bat_high_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_BAT_HIGH_REL:
        _settingsData["PROT_BAT_HIGH_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_bat_high_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_BAT_LOW_TRIG:
        _settingsData["PROT_BAT_LOW_TRIG"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_bat_low_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_BAT_LOW_REL:
        _settingsData["PROT_BAT_LOW_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_bat_low_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CELL_HIGH_TRIG:
        _settingsData["PROT_CELL_HIGH_TRIG"] = batch.sublist(0, 2);
        print(
            " [param] ${parameterRegistry[param]}:$param_prot_cell_high_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CELL_HIGH_REL:
        _settingsData["PROT_CELL_HIGH_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_cell_high_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CELL_LOW_TRIG:
        _settingsData["PROT_CELL_LOW_TRIG"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_cell_low_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CELL_LOW_REL:
        _settingsData["PROT_CELL_LOW_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_cell_low_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CH_HIGH_MA:
        _settingsData["PROT_CH_HIGH_MA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_ch_high_ma");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case PROT_CH_LOW_MA:
        _settingsData["PROT_CH_LOW_MA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_prot_ch_low_ma");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case BAL_START:
        _settingsData["BAL_START"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_bal_start");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case BAL_DELTA:
        _settingsData["BAL_DELTA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_bal_delta");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case NTC_EN:
        _settingsData["NTC_EN"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_ntc_en");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case CELL_CNT:
        _settingsData["CELL_CNT"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_cell_cnt");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_FET_CTRL_SW:
        _settingsData["DEL_FET_CTRL_SW"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_fet_ctrl_sw");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LED:
        _settingsData["DEL_LED"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_led");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case ADV_HIGH_V_TRIG:
        _settingsData["ADV_HIGH_V_TRIG"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_adv_high_v_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case ADV_LOW_V_TRIG:
        _settingsData["ADV_LOW_V_TRIG"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_adv_low_v_trig");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case ADV_PROT_HIGH_MA:
        _settingsData["ADV_PROT_HIGH_MA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_adv_prot_high_ma");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case SC_PROT_SET:
        _settingsData["SC_PROT_SET"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_sc_prot_set");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_ADV_HIGH_LOW_V:
        _settingsData["DEL_ADV_HIGH_LOW_V"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_adv_high_low_v");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_SC_REL:
        _settingsData["DEL_SC_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_sc_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_CH_TEMP:
        _settingsData["DEL_LOW_CH_TEMP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_ch_temp");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_CH_TEMP:
        _settingsData["DEL_HIGH_CH_TEMP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_ch_temp");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_D_TEMP:
        _settingsData["DEL_LOW_D_TEMP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_d_temp");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_D_TEMP:
        _settingsData["DEL_HIGH_D_TEMP"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_d_temp");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_BAT_V:
        _settingsData["DEL_LOW_BAT_V"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_bat_v");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_BAT_V:
        _settingsData["DEL_HIGH_BAT_V"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_bat_v");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_CELL_V:
        _settingsData["DEL_LOW_CELL_V"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_cell_v");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_CELL_V:
        _settingsData["DEL_HIGH_CELL_V"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_cell_v");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_MA:
        _settingsData["DEL_HIGH_MA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_ma");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_HIGH_MA_REL:
        _settingsData["DEL_HIGH_MA_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_high_ma_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_MA:
        _settingsData["DEL_LOW_MA"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_ma");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_LOW_MA_REL:
        _settingsData["DEL_LOW_MA_REL"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_low_ma_rel");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case GPS_SHUTD:
        _settingsData["GPS_SHUTD"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_gps_shutd");
        return _handleBatchParameterData(batch.sublist(2), param + 1);

      case DEL_GPS_SHUTD:
        _settingsData["DEL_GPS_SHUTD"] = batch.sublist(0, 2);
        print(" [param] ${parameterRegistry[param]}:$param_del_gps_shutd");
        return _handleBatchParameterData(batch.sublist(2), param + 1);
      default:
        print("param:$param unknown: $batch");
        return _handleBatchParameterData(batch.sublist(2), param + 1);
    }
  }

  /// combine two bytes;
  static int _combine(List<int> data, int index, int nextIndex) {
    return (data[index] << 8) + data[nextIndex];
  }

  /// combine two bytes with sign (usually for amps);
  static int _combineSigned(List<int> data, int index, int nextIndex) {
    return (data[nextIndex] & 0xFF) | ((data[index] << 8) & 0xFF00);
  }

  /// converts 2 bytes to a value of unit of unsigned 1mili
  static double _unsignedOneMili(List<int>? data) {
    return (data == null) ? 0.0 : _combine(data, 0, 1) * 0.001;
  }

  /// converts 2 bytes to a value of unit of unsigned 10mili
  static double _unsigned10Mili(List<int>? data) {
    return (data == null) ? 0.0 : _combine(data, 0, 1) * 0.01;
  }

  /// converts 2 bytes to a value of unit of unsigned 100mili
  static double _unsigned100Mili(List<int>? data,
      [int index = 0, int nextIndex = 1]) {
    return (data == null) ? 0.0 : _combine(data, index, nextIndex) * 0.1;
  }

  /// converts 2 bytes to a value of unit of unsigned 100mili then substracts 273.15
  static double _kelvinsToCelcius(List<int>? data,
      [int index = 0, int nextIndex = 1]) {
    return (data == null)
        ? 0.0
        : _unsigned100Mili(data, index, nextIndex) - 273.15;
  }

  /// converts 2 bytes to a value of unit of signed 10mili
  static double _signed10Mili(List<int>? data) {
    if (data == null) return 0.00;
    int result = (data[1] & 0xFF) | ((data[0] << 8) & 0xFF00);
    // Check the sign bit (MSB)
    if (result & 0x8000 != 0) result = -(0x10000 - result);
    return (result * 0.01);
  }

  /// converts 2 bytes to a value of one unit 1;
  static int _oneUnit(List<int>? data) {
    return (data == null) ? 0 : _combine(data, 0, 1);
  }

  /// converts 1 bytes to a value of one unit 1;
  static int _oneByteOneUnit(List<int>? data) {
    return (data == null) ? 0 : data[0];
  }

  /// converts 1 bytes to a value of a bool;
  static bool _oneBool(List<int>? data, int position) {
    if (data == null) return false;
    return (data[0] & position) != 0;
  }

  static setAvailableData(bool isBLEConnected) {
    _availableData = isBLEConnected;
  }

  static bool get availableData => _availableData;

  static clear() {
    setAvailableData(false);
    _data.clear();
    _settingsData.clear();
  }
}
