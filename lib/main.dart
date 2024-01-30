import 'package:bluetooth_bms/BState.dart';
import 'package:bluetooth_bms/CState.dart';
import 'package:bluetooth_bms/Control.dart';
import 'package:bluetooth_bms/Devices.dart';
import 'package:bluetooth_bms/Records.dart';
import 'package:bluetooth_bms/TempData.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
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
        home: const ScanPage(title: 'Home Page'));
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.title});
  final String title;
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool disabled = false;
  List<Widget> devices = [];
  List<Widget> namelessDevices = [];

  onScan() async {
    setState(() => disabled = true);
    setState(() => devices.clear());
    if (!await Be.init()) {
      return;
    }
    await Be.scan(onFound);

    setState(() => disabled = false);
  }

  void onFound(String name, BluetoothDevice device) {
    if (device.advName.length > 1) {
      devices.insert(0, Device(title: name, device: device));
    } else {
      namelessDevices.add(Device(title: name, device: device));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Be.init();
  }

  @override
  Widget build(Object context) {
    return Scaffold(
        body: Stack(children: [
      //black bg
      Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF002A4D), Colors.black]))),
      //app title
      const Positioned(
          top: 95,
          left: 10,
          child: Text("Bluetooth BMS",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 25))),
      //Scan button
      Positioned(
          top: 90,
          right: 10,
          child: ElevatedButton(
              onPressed: (disabled) ? null : onScan,
              child: const Text("SCAN",
                  style: TextStyle(
                      color: Color(0xEC121315),
                      fontWeight: FontWeight.w300,
                      fontSize: 20,
                      letterSpacing: 2)))),
      //List of all devices
      Positioned.fill(
          top: 150,
          child: Container(
              decoration: const BoxDecoration(
                  color: Color(0xAE121315),
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(45))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(bottom: 10)),
                    const Text("Devices",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 20,
                            letterSpacing: 2)),
                    Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        height: 600,
                        child: ListView(
                          key: UniqueKey(),
                          children: devices,
                        ))
                  ]))),
    ]));
  }
}
