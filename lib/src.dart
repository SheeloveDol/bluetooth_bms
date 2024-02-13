// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Be {
  static BluetoothDevice? savedDevice;
  static BluetoothService? service;
  static BluetoothCharacteristic? readCharacteristics;
  static BluetoothCharacteristic? writeCharacteristics;
  static StreamSubscription<BluetoothConnectionState>? savedSubscription;
  static List<int> _answer = [];
  static int times = 0;
  static int readTimes = 0;
  static Function? updater;

  Be() {}

  static Future<bool> init() async {
    bool status = false;
    // first, check if bluetooth is supported by your hardware
    // Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return false;
    }

// handle bluetooth on & off
// note: for iOS the initial state is typically BluetoothAdapterState.unknown
// note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        status = true;
      } else {
        status = false;
      }
    });

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

// cancel to prevent duplicate listeners
    subscription.cancel();
    return status;
  }

  static scan(Function(String, BluetoothDevice) onFound) async {
    try {
      if (savedDevice != null) {
        disconnect(savedDevice!);
      }
    } catch (e) {
      print("maybe it is already disconnected");
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

    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // Wait for Bluetooth enabled & permission granted
    // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    // Start scanning w/ timeout
    // Optional: you can use `stopScan()` as an alternative to using a timeout
    // Note: scan filters use an *or* behavior. i.e. if you set `withServices` & `withNames`
    //   we return all the advertisments that match any of the specified services *or* any
    //   of the specified names.
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  static Future<bool> connect(BluetoothDevice device) async {
    // listen for disconnection

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        print("Device Disconnected : ${device.disconnectReason}");
      }
    });
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);
    // Connect to the device
    try {
      await device.connect();
      savedSubscription = subscription;
      return true;
    } on Exception catch (_, e) {
      print("Reason why it could not connect ${e.toString()}");
      savedSubscription = null;
      return false;
    }
  }

  static Future<void> disconnect(BluetoothDevice device) async {
    // Disconnect from device
    await device.disconnect();
    // cancel to prevent duplicate listeners
    savedSubscription?.cancel();

    savedDevice = null;
    service = null;
    readCharacteristics = null;
    writeCharacteristics = null;
    updater = null;
  }

  static Future<bool> save(BluetoothDevice device) async {
    bool check = false;
    savedDevice = device;
    check = await _getReadWriteService();
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return false;
    }
    check = _getReadCharacteristics();
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return false;
    }
    check = _getWriteCharacteristics();
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return false;
    }

    print("Service and characteristics has ben saved");
    await readCharacteristics!.setNotifyValue(true);
    readCharacteristics!.onValueReceived.listen((event) {
      _answer.addAll(event);
    });

    return await read(Data.BASIC_INFO);
  }

  static bool _getWriteCharacteristics() {
    // get write char
    var characteristics = service!.characteristics;
    for (BluetoothCharacteristic c in characteristics) {
      if (c.characteristicUuid == Guid("FF02")) {
        writeCharacteristics = c;
        return true;
      }
    }
    return false;
  }

  static bool _getReadCharacteristics() {
    // get Read char
    var characteristics = service!.characteristics;
    for (BluetoothCharacteristic c in characteristics) {
      if (c.characteristicUuid == Guid("FF01")) {
        readCharacteristics = c;
        return true;
      }
    }
    return false;
  }

  static Future<bool> _getReadWriteService() async {
    // Note: You must call discoverServices after every re-connection!
    try {
      List<BluetoothService> services = await savedDevice!.discoverServices();
      for (var s in services) {
        if (s.serviceUuid == Guid("FF00")) {
          service = s;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static List<int> _checksumtoRead(int register, int bytelength) {
    return _hexToIntList(0x10000 - (register + bytelength));
  }

  static List<int> _hexToIntList(int hexValue) {
    List<int> result = [];
    String hexString = hexValue.toRadixString(16);
    if (hexString.length % 2 != 0) {
      hexString = '0$hexString';
    }
    for (int i = 0; i < hexString.length; i += 2) {
      result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }

    return result;
  }

  static Future<bool> read(int registerToRead) async {
    List<int> cmd = [
      0xDD,
      0xa5,
      registerToRead,
      0x00,
      ..._checksumtoRead(registerToRead, 0x00),
      0x77
    ];

    List<int> rawData = await queryRawCmd(cmd);
    while (_answer[_answer.length - 1] != 0x77) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    readTimes++;
    bool good = _verifyReadings(rawData);
    if (!good) {
      print("failed to read");
      return false;
    }
    /*List<int> rawData = [
      221,
      3,
      0,
      29,
      5,
      50,
      0,
      0,
      46,
      122,
      66,
      104,
      0,
      1,
      46,
      187,
      0,
      0,
      0,
      0,
      0,
      0,
      97,
      70,
      1,
      4,
      3,
      11,
      148,
      11,
      143,
      11,
      144,
      250,
      237,
      119
    ];8*/
    readTimes = 0;
    List<int> data = rawData.sublist(4, 4 + rawData[3]);
    Data.setBatchData(data, Data.BASIC_INFO);
    if (updater != null) {
      updater!();
    }
    return true;
  }

  static Future queryRawCmd(List<int> cmd) async {
    _answer.clear();
    for (int i = 0; i < 2; i++) {
      await writeCharacteristics!.write(cmd, withoutResponse: true);
    }
    return;
  }

  static bool _verifyReadings(List<int> rawData) {
    if (rawData[0] != 0xDD) {
      print(rawData);
      print("Wrong starting byte");
      _answer.clear();
      return false;
    }
    if (rawData[2] != 0x00) {
      print(rawData);
      print("Error code ${rawData[2]}");
      _answer.clear();
      return false;
    }
    if (rawData[rawData.length - 1] != 0x77) {
      print(rawData);
      print("wrong ending byte");
      _answer.clear();
      return false;
    }

    int datasum = 0;
    for (var i = 2; i < rawData.length - 3; i++) {
      datasum += rawData[i];
    }
    if (rawData.sublist(rawData.length - 3)[0] !=
            _checksumtoRead(datasum, 0x0)[0] ||
        rawData.sublist(rawData.length - 3)[1] !=
            _checksumtoRead(datasum, 0x0)[1]) {
      print("corupted data ${[
        ..._checksumtoRead(datasum, 0x0),
        0x77
      ]} is not ${rawData.sublist(rawData.length - 3)}");
      _answer.clear();
      return false;
    }
    return true;
  }

  static void setUpdater(void Function() setstate) {
    updater = setstate;
  }
}

class Data {
  static const BASIC_INFO = 0x03;
  static const CELL_VOLTAGE = 0x04;
  static const DEVICE_NAME = 0x05;
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
  static const int ERROR_CNTS = 0xAA;
  static const CLEAR_PASSWORD = 0x09;
  static const ENTER_FACTORY_MODE = 0x00;
  static const EXIT_FACTORY_MODE = 0x01;

  static final Map<String, List<int>> _data = {};

  static String get pack_mv =>
      (((_data["pack_mv"]![0] << 8) + _data["pack_mv"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get pack_ma {
    // Combine the bytes to form a 16-bit integer
    int result =
        (_data["pack_ma"]![1] & 0xFF) | ((_data["pack_ma"]![0] << 8) & 0xFF00);
    // Check the sign bit (MSB)
    if (result & 0x8000 != 0) {
      result = -(0x10000 - result);
    }
    return (result * 0.01).toStringAsFixed(2);
  }

  static String get cycle_cap =>
      (((_data["cycle_cap"]![0] << 8) + _data["cycle_cap"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get design_cap =>
      (((_data["design_cap"]![0] << 8) + _data["design_cap"]![1]) * 0.01)
          .toStringAsFixed(2);
  static String get cycle_cnt =>
      (((_data["cycle_cnt"]![0] << 8) + _data["cycle_cnt"]![1])).toString();
  static List<bool> get fet_status => [
        (_data["fet_status"]![0] & 0x0) != 0,
        (_data["fet_status"]![0] & 0x1) != 0
      ];
  static List<String> get curr_err {
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
    List<bool> bal = [];
    for (int i = 15; i >= 0; i--) {
      bool bit = (((_data["bal"]![0] << 8) + _data["bal"]![1]) & (1 << i)) != 0;
      bal.add(bit);
    }
    return bal;
  }

  static int get cap_pct => _data["cap_pct"]![0];
  static int get cell_cnt => _data["cell_cnt"]![0];
  static int get ntc_cnt => _data["ntc_cnt"]![0];
  static List<String> get ntc_temp {
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

  static int get device_name_lenght => _data["device_name_lenght"]![0];
  static String get watts {
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

  static void setBatchData(List<int> batch, int register) {
    switch (register) {
      case BASIC_INFO:
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
        int afterNtc = 0x017 + ntc_cnt * 2;
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
              "Data humidity, alarm, full_charge_capacity, remining_capacity and balance curent was not found in basic info");
        }
        break;

      case CELL_VOLTAGE:
        int j = 0;
        for (int i = 0; i < cell_cnt; i++) {
          _data["cell${i}_mv"] = batch.sublist(j, j + 2);
          j += 2;
        }
        break;

      case DEVICE_NAME:
        _data["device_name_lenght"] = [batch[0x0]];
        _data["device_name"] = batch.sublist(0x1, 0x1 + device_name_lenght);
        break;

      default:
        print("unknown registery");
        break;
    }
  }
}
