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
  static late Function updater;

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
      print(state);
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
    // listen to scan results
    // Note: `onScanResults` only returns live scan results, i.e. during scanning
    // Use: `scanResults` if you want live scan results *or* the results from a previous scan
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last;
          onFound(
              (r.advertisementData.advName.length > 1)
                  ? r.advertisementData.advName
                  : "${r.device.remoteId}",
              r.device); // the most recently found device
          print(
              '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
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
  }

  static save(BluetoothDevice device, Function setstate) async {
    /*bool check = false;
    savedDevice = device;
    check = await _getReadWriteService();
    print(check);
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return;
    }
    check = _getReadCharacteristics();
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return;
    }
    check = _getWriteCharacteristics();
    if (!check) {
      await disconnect(device);
      print("Device is not compatible");
      return;
    }

    print("Service and characteristics has ben saved");
    await readCharacteristics!.setNotifyValue(true);
    //dd a5 03 00 ff fd 77 : get basic info
    writeRawCmd([0xdd, 0xa5, 0x03, 0x00, 0xff, 0xfd, 0x77]);*/
    updater = setstate;
    read(Data.basic_info);
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

  static read(int registerToRead) async {
    List<int> cmd = [
      0xDD,
      0xa5,
      registerToRead,
      0x00,
      ..._checksumtoRead(registerToRead, 0x00),
      0x77
    ];

    List<int> rawData = await queryRawCmd(cmd);
    readTimes++;
    bool good = _verifyReadings(rawData);
    if (!good) {
      (readTimes < 3)
          ? await read(registerToRead)
          : print("Failed to read command");
      return;
    }
    readTimes = 0;
    List<int> data = rawData.sublist(4, 4 + rawData[3]);
    Data.setBatchData(data);
    updater(() {});
  }

  static Future<List<int>> queryRawCmd(List<int> cmd) async {
    Completer<List<int>> completer = Completer<List<int>>();
    _answer.clear();

    readCharacteristics!.onValueReceived.listen((event) {
      _answer = [...event];
    }, onDone: () {
      if (_answer[1] == Data.basic_info && times < 1) {
        times++;
        return;
      }
      times = 0;
      completer.complete(_answer);
    });

    for (int i = 0; i < 2; i++) {
      await writeCharacteristics!.write(cmd, withoutResponse: true);
    }
    return completer.future;
  }

  static bool _verifyReadings(List<int> rawData) {
    if (rawData[0] != 0xDD) {
      print("Wrong starting byte");
      return false;
    }
    if (rawData[2] != 0x00) {
      print("Error code ${rawData[2]}");
      return false;
    }
    /*int datasum = 0;
    for (var i = 1; i < rawData.length - 3; i++) {
      datasum += rawData[i];
    }
    if (rawData.sublist(rawData.length - 2) !=
        [..._checksumtoRead(datasum, 0x0), 0x77]) {
      print("corupted data ${[
        ..._checksumtoRead(datasum, 0x0),
        0x77
      ]} is not ${rawData.sublist(rawData.length - 3)}");
      return false;
    }*/
    return true;
  }
}

class Data {
  static final Map<String, int> _register = {
    "Basic info": 0x03,
  };

  static final Map<String, List<int>> _data = {};

  static int get basic_info => _register["Basic info"]!;
  static List<int>? get pack_mv => _data["pack_mv"];

  void _setData(String name, List<int> value) {
    _data[name] = value;
  }

  static void setBatchData(List<int> batch) {
    _data["pack_mv"] = batch.sublist(0, 2);
  }
}
