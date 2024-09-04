// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceConnectionState { connecting, connected, disconnected }

class Be {
  static BluetoothDevice? savedDevice;
  static DeviceConnectionState _currentState = DeviceConnectionState.disconnected;
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

  static Future<bool> init() async {
    bool status = false;
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return false;
    }
    var subscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
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
                (r.advertisementData.advName.length > 1) ? r.advertisementData.advName : "${r.device.remoteId}", r.device);
          }
        } catch (e) {
          print("switched window");
        }
      },
      onError: (e) => print(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
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
    var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
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
      readSuccessFully = (readSuccessFully) ? await read(Data.CELL_INFO_PAYLOAD) : readSuccessFully;
      readSuccessFully = (readSuccessFully) ? await read(Data.STATS_PAYLOAD) : readSuccessFully;

      if (readSuccessFully) {
        savedDevice = device;
        savedSubscription = subscription;
        readWhatsLeft();
        Data.setAvailableData(true);
        setConnectionState(DeviceConnectionState.connected);
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
      setConnectionState(DeviceConnectionState.disconnected);
    }
  }

  static Future<bool> resetConnection() async {
    print("RECONNECTING");
    setConnectionState(DeviceConnectionState.connecting);
    await disconnect(totaly: false);
    Data.clear();
    try {
      await savedDevice!.connect();
      await savedDevice!.discoverServices();
      print("RECONNECTED");
      setConnectionState(DeviceConnectionState.connected);
      return true;
    } catch (e) {
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
    _communicatingNow = true;
    List<int> answer = [];
    var good = false;

    if (_currentState != DeviceConnectionState.connected) {
      print("no device is currently connefcted");
      return false;
    }

    int k = 0;
    do {
      //subscribe to read charac

      await readCharacteristics?.setNotifyValue(true);

      var notifySub = readCharacteristics?.onValueReceived.listen((event) {
        answer.addAll(event);
      });
      List<int> cmd = [0xDD, 0xa5, ...payload, ...checksumtoRead(payload), 0x77];
      print("reading command : $cmd");
      int j = 0;
      do {
        for (var i = (wake) ? 0 : 1; i < 2; i++) {
          await writeCharacteristics?.write(cmd, withoutResponse: true);
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
      notifySub?.cancel();
      good = _verifyReadings(answer);
      print(answer);

      if (!good) await resetConnection();
      k++;
      if (k > 2) return false;
    } while (!good);

    var data = answer.sublist(4, answer.length - 3);
    good = Data.setBatchData(data, answer[1]);
    _communicatingNow = false;
    return good;
  }

  static Future<List<int>> write(List<int> payload) async {
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
      if (rawData.sublist(rawData.length - 3)[0] != checksumtoRead(payload)[0] ||
          rawData.sublist(rawData.length - 3)[1] != checksumtoRead(payload)[1]) {
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
      print("could not verify the readings");
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

  static read_design_cap() async {
    await read(Data.DESIGN_CAP_PAYLOAD);
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
    updater!();
  }

  static unLock() async {
    if (!locked) {
      return;
    }
    var batch = await write(Data.OPEN_FACTORY_MODE);
    Data.setBatchData(batch, batch[1]);
    updater!();
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
    await read(Data.MANUF_PAYLOAD);
    updater!();
    //await read(Data.BAL_PAYLOAD);
    //updater!();
  }

  static void setConnectionState(DeviceConnectionState state) {
    updater!();
    _currentState = state;
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

  //Parameters registeries
  static const DESIGN_CAP = 0;
  static const CYCLE_CAP = 1;
  static const CELL_FULL_MV = 2;
  static const CELL_MIN_MV = 3;
  static const CELL_D_PERC = 4;
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
  static const CELL_10 = 0;*/
  static const PROT_C_HIGH_TEMP_TRIG = 8;
  static const PROT_C_HIGH_TEMP_REL = 9;
  static const PROT_C_LOW_TEMP_TRIG = 10;
  static const PROT_C_LOW_TEMP_REL = 11;
  static const PROT_D_HIGH_TEMP_TRIG = 12;
  static const PROT_D_HIGH_TEMP_REL = 13;
  static const PROT_D_LOW_TEMP_TRIG = 14;
  static const PROT_D_LOW_TEMP_REL = 15;
  static const PROT_BAT_HIGH_TRIG = 16;
  static const PROT_BAT_HIGH_REL = 17;
  static const PROT_BAT_LOW_TRIG = 18;
  static const PROT_BAT_LOW_REL = 19;
  static const PROT_CELL_HIGH_TRIG = 20;
  static const PROT_CELL_HIGH_REL = 21;
  static const PROT_CELL_LOW_TRIG = 22;
  static const PROT_CELL_LOW_REL = 23;
  static const PROT_CH_HIGH_MA = 24;
  static const PROT_CH_LOW_MA = 25;
  static const BAL_START = 26;
  static const BAL_DELTA = 27;
  static const BAL_EN = 28;
  static const BAL_EN_C = 29;
  static const NTC_EN = 30;
  static const CELL_CNT = 31;
  static const DEL_FET_CTRL_SW = 32;
  static const DEL_LED = 33;
  // TODO: SEE VALEUES FOR THIS GAP
  static const ADV_HIGH_V_TRIG = 38;
  static const ADV_LOW_V_TRIG = 39;
  static const ADV_PROT_HIGH_MA = 40;
  static const SC_PROT_SET = 41;
  static const DEL_ADV_HIGH_LOW_V = 42;
  static const DEL_SC_REL = 43;
  static const DEL_LOW_CH_TEMP = 44;
  static const DEL_HIGH_CH_TEMP = 45;
  static const DEL_LOW_D_TEMP = 46;
  static const DEL_HIGH_D_TEMP = 47;
  static const DEL_LOW_BAT_V = 48;
  static const DEL_HIGH_BAT_V = 49;
  static const DEL_LOW_CELL_V = 50;
  static const DEL_HIGH_CELL_V = 51;
  static const DEL_HIGH_MA = 52;
  static const DEL_HIGH_MA_REL = 53;
  static const DEL_LOW_MA = 54;
  static const DEL_LOW_MA_REL = 55;
  static const MFG_NAME = 56;
  //Unecessary values for this GAP
  static const GPS_SHUTD = 104;
  static const DEL_GPS_SHUTD = 105;
  //106 to 111 are cell %

  static final Map<int, String> parameterRegistry = {
    0: 'DESIGN_CAP',
    1: 'CYCLE_CAP',
    2: 'CELL_FULL_MV',
    3: 'CELL_MIN_MV',
    4: 'CELL_D_PERC',
    8: 'PROT_C_HIGH_TEMP_TRIG',
    9: 'PROT_C_HIGH_TEMP_REL',
    10: 'PROT_C_LOW_TEMP_TRIG',
    11: 'PROT_C_LOW_TEMP_REL',
    12: 'PROT_D_HIGH_TEMP_TRIG',
    13: 'PROT_D_HIGH_TEMP_REL',
    14: 'PROT_D_LOW_TEMP_TRIG',
    15: 'PROT_D_LOW_TEMP_REL',
    16: 'PROT_BAT_HIGH_TRIG',
    17: 'PROT_BAT_HIGH_REL',
    18: 'PROT_BAT_LOW_TRIG',
    19: 'PROT_BAT_LOW_REL',
    20: 'PROT_CELL_HIGH_TRIG',
    21: 'PROT_CELL_HIGH_REL',
    22: 'PROT_CELL_LOW_TRIG',
    23: 'PROT_CELL_LOW_REL',
    24: 'PROT_CH_HIGH_MA',
    25: 'PROT_CH_LOW_MA',
    26: 'BAL_START',
    27: 'BAL_DELTA',
    28: 'BAL_EN',
    29: 'BAL_EN_C',
    30: 'NTC_EN',
    31: 'CELL_CNT',
    32: 'DEL_FET_CTRL_SW',
    33: 'DEL_LED',
    38: 'ADV_HIGH_V_TRIG',
    39: 'ADV_LOW_V_TRIG',
    40: 'ADV_PROT_HIGH_MA',
    41: 'SC_PROT_SET',
    42: 'DEL_ADV_HIGH_LOW_V',
    43: 'DEL_SC_REL',
    44: 'DEL_LOW_CH_TEMP',
    45: 'DEL_HIGH_CH_TEMP',
    46: 'DEL_LOW_D_TEMP',
    47: 'DEL_HIGH_D_TEMP',
    48: 'DEL_LOW_BAT_V',
    49: 'DEL_HIGH_BAT_V',
    50: 'DEL_LOW_CELL_V',
    51: 'DEL_HIGH_CELL_V',
    52: 'DEL_HIGH_MA',
    53: 'DEL_HIGH_MA_REL',
    54: 'DEL_LOW_MA',
    55: 'DEL_LOW_MA_REL',
    56: 'MFG_NAME',
    104: 'GPS_SHUTD',
    105: 'DEL_GPS_SHUTD',
  };

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

  // Parameters payload read
  static const ALL_PARAMS_PAYLOAD = [PARAMETERS, 0x03, 0x00, DESIGN_CAP, 56]; // i want registry 0 all the way to 55;
  static const MANUF_PAYLOAD = [PARAMETERS, 0x03, 0x00, MFG_NAME, 0x10];

  static const BAL_PAYLOAD = [PARAMETERS, 0x03, 0x00, BAL_START, 0x2];
  static const DESIGN_CAP_PAYLOAD = [PARAMETERS, 0x03, 0x00, DESIGN_CAP, 0x1];

  // Parameters payload write
  static const DESIGN_CAP_WRITE = [PARAMETERS, 0x00, 5, 0x00, 0x00, 66, 204];

  //command write payloads
  static const ON_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x00];
  static const ON_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x01];
  static const OFF_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x02];
  static const OFF_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x03];
  static const RESET_PAYLOAD = [CMD_CTRL, 0x02, 0x04, 0x00];

  static final Map<String, List<int>> _data = {};
  static final Map<String, List<int>> _settingsData = {};
  static bool availableData = false;
  static bool? _factory;

  static bool get factoryModeState => (_factory == null) ? false : _factory!;
  static String get pack_mv => _unsigned10Mili(_data["pack_mv"]).toStringAsFixed(2);
  static String get pack_ma => _signed10Mili(_data["pack_ma"]).toStringAsFixed(2);
  static String get cycle_cap => _unsigned10Mili(_data["cycle_cap"]).toStringAsFixed(1);
  static String get design_cap => _unsigned10Mili(_data["design_cap"]).toStringAsFixed(1);
  static String get cycle_cnt => _oneUnit(_data["cycle_cnt"]).toString();
  static bool get chargeStatus => _oneBool(_data["fet_status"], 0x01); // position 01
  static bool get dischargeStatus => _oneBool(_data["fet_status"], 0x02); // position 10
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
  static String get device_name => (_data["device_name"] == null) ? "" : String.fromCharCodes(_data["device_name"]!);
  static String get mfg_name => (_data["mfg_name"] == null) ? "Royer Batteries" : String.fromCharCodes(_data["mfg_name"]!);

  static List<String> get curr_err {
    if (_data["curr_err"] == null) return [];
    List<String> err = [];
    for (int i = 15; i >= 0; i--) {
      bool bit = (((_data["curr_err"]![0] << 8) + _data["curr_err"]![1]) & (1 << i)) != 0;
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
    if (_data["bal"] == null) return [];
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
      temps.add((_unsigned100Mili(_data["ntc_temp"], j, j + 1) - 273.15).toStringAsFixed(1));
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

  static String get watts {
    if (_data["pack_ma"] == null || _data["pack_mv"] == null) return "0.0";
    int result = _combineSigned(_data["pack_ma"]!, 0, 1);
    // Check the sign bit (MSB)
    var doubleResult = (result & 0x8000 != 0) ? -(0x10000 - result) * 1.0 : result * 1.0;
    return (doubleResult * _combine(_data["pack_ma"]!, 0, 1) * 0.01).round().toString();
  }

  static String get timeLeft {
    if (_data["cycle_cap"] == null || _data["design_cap"] == null || _data["pack_ma"] == null) {
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
          _data["full_charge_capacity"] = batch.sublist(afterNtc + 1, afterNtc + 3);
          _data["remaining_capacity"] = batch.sublist(afterNtc + 3, afterNtc + 5);
          _data["balance_current"] = batch.sublist(afterNtc + 5, afterNtc + 7);
        } catch (e) {
          print("Data humidity, alarm, full_charge_capacity, remining_capacity and balance current was not found");
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
        _factory = false;
        return true;

      default:
        print("uncaught registery");
        return false;
    }
  }

  static bool _handleParameterData(List<int> batch) {
    var register = batch[1];
    print("handeling ${parameterRegistry[register]} payload : $batch");
    switch (register) {
      case DESIGN_CAP:
        print("Starting recursion");
        return _handleBatchParameterData(batch.sublist(3), 5, DESIGN_CAP);
      case MFG_NAME:
        var mfg_name_lenght = batch[3];
        _data["mfg_name"] = batch.sublist(4, 4 + mfg_name_lenght);
        return true;
    }
    return false;
  }

  static bool _handleBatchParameterData(List<int> batch, int index, int param) {
    print("handeling $param:${parameterRegistry[param]} payload left: $batch");
    if (param == MFG_NAME) {
      return true;
    }

    //chat gpt this please

    switch (param) {
      case DESIGN_CAP:
        _settingsData["DESIGN_CAP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case CYCLE_CAP:
        _settingsData["CYCLE_CAP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case CELL_FULL_MV:
        _settingsData["CELL_FULL_MV"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case CELL_MIN_MV:
        _settingsData["CELL_MIN_MV"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case CELL_D_PERC:
        _settingsData["CELL_D_PERC"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_C_HIGH_TEMP_TRIG:
        _settingsData["PROT_C_HIGH_TEMP_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_C_HIGH_TEMP_REL:
        _settingsData["PROT_C_HIGH_TEMP_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_C_LOW_TEMP_TRIG:
        _settingsData["PROT_C_LOW_TEMP_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_C_LOW_TEMP_REL:
        _settingsData["PROT_C_LOW_TEMP_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_D_HIGH_TEMP_TRIG:
        _settingsData["PROT_D_HIGH_TEMP_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_D_HIGH_TEMP_REL:
        _settingsData["PROT_D_HIGH_TEMP_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_D_LOW_TEMP_TRIG:
        _settingsData["PROT_D_LOW_TEMP_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_D_LOW_TEMP_REL:
        _settingsData["PROT_D_LOW_TEMP_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_BAT_HIGH_TRIG:
        _settingsData["PROT_BAT_HIGH_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_BAT_HIGH_REL:
        _settingsData["PROT_BAT_HIGH_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_BAT_LOW_TRIG:
        _settingsData["PROT_BAT_LOW_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_BAT_LOW_REL:
        _settingsData["PROT_BAT_LOW_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CELL_HIGH_TRIG:
        _settingsData["PROT_CELL_HIGH_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CELL_HIGH_REL:
        _settingsData["PROT_CELL_HIGH_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CELL_LOW_TRIG:
        _settingsData["PROT_CELL_LOW_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CELL_LOW_REL:
        _settingsData["PROT_CELL_LOW_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CH_HIGH_MA:
        _settingsData["PROT_CH_HIGH_MA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case PROT_CH_LOW_MA:
        _settingsData["PROT_CH_LOW_MA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case BAL_START:
        _settingsData["BAL_START"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case BAL_DELTA:
        _settingsData["BAL_DELTA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case BAL_EN:
        _settingsData["BAL_EN"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case BAL_EN_C:
        _settingsData["BAL_EN_C"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case NTC_EN:
        _settingsData["NTC_EN"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case CELL_CNT:
        _settingsData["CELL_CNT"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_FET_CTRL_SW:
        _settingsData["DEL_FET_CTRL_SW"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LED:
        _settingsData["DEL_LED"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case ADV_HIGH_V_TRIG:
        _settingsData["ADV_HIGH_V_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case ADV_LOW_V_TRIG:
        _settingsData["ADV_LOW_V_TRIG"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case ADV_PROT_HIGH_MA:
        _settingsData["ADV_PROT_HIGH_MA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case SC_PROT_SET:
        _settingsData["SC_PROT_SET"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_ADV_HIGH_LOW_V:
        _settingsData["DEL_ADV_HIGH_LOW_V"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_SC_REL:
        _settingsData["DEL_SC_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_CH_TEMP:
        _settingsData["DEL_LOW_CH_TEMP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_CH_TEMP:
        _settingsData["DEL_HIGH_CH_TEMP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_D_TEMP:
        _settingsData["DEL_LOW_D_TEMP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_D_TEMP:
        _settingsData["DEL_HIGH_D_TEMP"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_BAT_V:
        _settingsData["DEL_LOW_BAT_V"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_BAT_V:
        _settingsData["DEL_HIGH_BAT_V"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_CELL_V:
        _settingsData["DEL_LOW_CELL_V"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_CELL_V:
        _settingsData["DEL_HIGH_CELL_V"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_MA:
        _settingsData["DEL_HIGH_MA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_HIGH_MA_REL:
        _settingsData["DEL_HIGH_MA_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_MA:
        _settingsData["DEL_LOW_MA"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_LOW_MA_REL:
        _settingsData["DEL_LOW_MA_REL"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case MFG_NAME:
        _settingsData["MFG_NAME"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case GPS_SHUTD:
        _settingsData["GPS_SHUTD"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);

      case DEL_GPS_SHUTD:
        _settingsData["DEL_GPS_SHUTD"] = batch.sublist(3, index);
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);
      default:
        print("param:$param unknown: $batch");
        return _handleBatchParameterData(batch.sublist(index), index + 2, param + 1);
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
  static double _unsigned100Mili(List<int>? data, [int index = 0, int nextIndex = 1]) {
    return (data == null) ? 0.0 : _combine(data, index, nextIndex) * 0.1;
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
    availableData = isBLEConnected;
  }

  static clear() {
    setAvailableData(false);
    _data.clear();
    _settingsData.clear();
  }
}
