import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Be {
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

  static Future<StreamSubscription<BluetoothConnectionState>?> connect(
      BluetoothDevice device) async {
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
      return subscription;
    } catch (e) {
      return Future(() => null);
    }
  }

  static Future<void> disconnect(BluetoothDevice device,
      StreamSubscription<BluetoothConnectionState> subscription) async {
    // Disconnect from device
    await device.disconnect();
    // cancel to prevent duplicate listeners
    subscription.cancel();
  }
}
