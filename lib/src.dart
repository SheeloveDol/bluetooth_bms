import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Be {
  static BluetoothDevice? savedDevice;
  static BluetoothService? service;
  static BluetoothCharacteristic? readCharacteristics;
  static BluetoothCharacteristic? writeCharacteristics;
  static StreamSubscription<BluetoothConnectionState>? savedSubscription;

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
    } catch (e) {
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

  static save(BluetoothDevice device) async {
    bool check = false;
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
    //dd a5 03 00 ff fd 77 : get basic info
    writeRawCmd([0xdd, 0xa5, 0x03, 0x00, 0xff, 0xfd, 0x77]);
  }

  static writeRawCmd(List<int> cmd) async {
    writeCharacteristics!.write(cmd);

    var answer = await readCharacteristics!.read(timeout: 7);
    print(answer);
    print("*********SUCCESS*********");
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
}
