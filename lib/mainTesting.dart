import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Bluetooth BMS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1645BC)),
          useMaterial3: true,
        ),
        home: const App());
  }
}

class App extends StatefulWidget {
  const App();

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  List<Widget> devices = [];
  List<int> data = [];
  BluetoothDevice? currentDevice;
  dynamic currentSub;
  dynamic currentChar;
  dynamic currentNotify;
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("With flutter bleu")),
        body: Center(
            child: Column(children: [
          ElevatedButton(
              onPressed: () async {
                var devicesRaw = await scan();
                for (var device in devicesRaw) {
                  devices.add(TextButton(
                      onPressed: () async {
                        var map = await connect(device, data, () => setState(() {}));
                        currentChar = map["char"];
                        currentSub = map["sub"];
                        currentNotify = map["notify"];
                        currentDevice = device;
                      },
                      child: Text("${device.advName}")));
                }
                setState(() {});
              },
              child: Text("scan")),
          Wrap(children: [...devices]),
          ElevatedButton(
              onPressed: () async {
                write(currentChar);
              },
              child: Text("read")),
          ElevatedButton(
              onPressed: () async {
                write(currentChar, true);
              },
              child: Text("wake & read")),
          Text("$data"),
          ElevatedButton(
              onPressed: () async {
                await disconnect(currentDevice!, currentSub);
                currentChar = null;
                currentSub = null;
                currentDevice = null;
                currentNotify.cancel();
                currentNotify = null;
                devices.clear();
                setState(() {});
              },
              child: Text("disconnect"))
        ])));
  }
}

Future<bool> init() async {
  bool status = false;
  // first, check if bluetooth is supported by your hardware
  // Note: The platform is initialized on the first call to any FlutterBluePlus method.
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

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
  if (Platform.isAndroid) {
    await FlutterBluePlus.turnOn();
  }

// cancel to prevent duplicate listeners
  subscription.cancel();
  return status;
}

Future<List<BluetoothDevice>> scan() async {
  List<BluetoothDevice> devices = [];
  var subscription = FlutterBluePlus.onScanResults.listen(
    (results) async {
      if (results.isNotEmpty) {
        ScanResult r = results.last;
        devices.add(r.device);
      }
    },
    onError: (e) => print(e),
  );
  FlutterBluePlus.cancelWhenScanComplete(subscription);
  await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
  await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

  // wait for scanning to stop
  await FlutterBluePlus.isScanning.where((val) => val == false).first;
  return devices;
}

Future<Map<String, dynamic>> connect(BluetoothDevice device, List<int> data, Function state) async {
  // listen for disconnection

  if (FlutterBluePlus.isScanningNow) {
    await FlutterBluePlus.stopScan();
  }

  var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
    if (state == BluetoothConnectionState.disconnected) {
      // 1. typically, start a periodic timer that tries to
      //    reconnect, or just call connect() again right now
      // 2. you must always re-discover services after disconnection!
      print("Device Disconnected : ${device.disconnectReason}");
    }
  });
  device.cancelWhenDisconnected(subscription, delayed: true, next: true);
  // Connect to the device

  await device.connect();

  late BluetoothService service;
  late BluetoothCharacteristic readCharacteristics;
  late BluetoothCharacteristic writeCharacteristics;

  //get service
  List<BluetoothService> services = await device.discoverServices();
  for (var s in services) {
    if (s.serviceUuid == Guid("FF00")) {
      service = s;
    }
  }
  //get write charac
  var characteristics = service.characteristics;
  for (BluetoothCharacteristic c in characteristics) {
    if (c.characteristicUuid == Guid("FF01")) {
      readCharacteristics = c;
    }
  }
  //get read charac
  characteristics = service.characteristics;
  for (BluetoothCharacteristic c in characteristics) {
    if (c.characteristicUuid == Guid("FF02")) {
      writeCharacteristics = c;
    }
  }

  //subscribe to read char
  await readCharacteristics.setNotifyValue(true);
  var notifySub = readCharacteristics.onValueReceived.listen((event) {
    data.addAll(event);
    state();
    print(event);
  });

  return {"sub": subscription, "char": writeCharacteristics, "notify": notifySub};
}

List<int> checksumtoRead(List<int> payload) {
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

read(writeCharacteristics, [wake = false]) async {
  //write something to write and wait for read
  // Everytime you send type of data you must change the checksum ie: 0xfd --> 0xfc
  // manufacturer specific command 0xfa, 0x03, 0x00, 0x38, 0x10   factoryMode: 0x00, 0x02, 0x56, 0x78
  List<int> payload = [0xfa, 0x03, 0x00, 0x38, 0x10];
  List<int> cmd = [0xDD, 0xa5, ...payload, ...checksumtoRead(payload), 0x77];
  for (var i = (wake) ? 0 : 1; i < 2; i++) {
    writeCharacteristics.write(cmd, withoutResponse: true);
    await Future.delayed(Duration(milliseconds: 700));
  }
}

const FET_CTRL = 0xE1;
const ON_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x00];
const ON_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x01];
const OFF_DSICHARGE_ON_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x00, 0x02];
const OFF_DSICHARGE_OFF_CHARGE_PAYLOAD = [FET_CTRL, 0x02, 0x01, 0x03];

write(writeCharacteristics, [wake = false]) async {
  //write something to write and wait for notif
  //
  // List<int> payload = ON_DSICHARGE_ON_CHARGE_PAYLOAD;
  // List<int> payload = [0xfa, 0x03, 0x00, 0x38, 0x10];
  // List<int> payload = [0xfa, 0x03, 0x00, 0x38, 0x10];
  List<int> payload = [0xfa, 0x03, 0x00, 0x38, 0x10];
  List<int> cmd = [0xDD, 0x5a, ...payload, ...checksumtoRead(payload), 0x77];
  for (var i = (wake) ? 0 : 1; i < 2; i++) {
    writeCharacteristics.write(cmd, withoutResponse: true);
    await Future.delayed(Duration(milliseconds: 700));
  }
}

disconnect(BluetoothDevice device, sub) async {
// Disconnect from device
  await device.disconnect();
  // cancel to prevent duplicate listeners
  sub.cancel();
}
