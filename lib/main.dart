import 'package:bluetooth_bms/Devices.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class DeviceElement {
  final String title;
  final BluetoothDevice device;
  final GlobalKey<State<StatefulWidget>> contextkey;
  final Function setState;

  const DeviceElement(this.title, this.device, this.contextkey, this.setState);
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool disabled = false;
  bool visible = false;
  List<DeviceElement> devices = [];
  List<DeviceElement> namelessDevices = [];

  onScan() async {
    setState(() => disabled = true);
    setState(() => devices.clear());
    if (!await Be.init()) {
      return;
    }
    setState(() => visible = false);
    Be.scan(onFound);
    await Future.delayed(const Duration(seconds: 5)).then((value) {
      setState(() {
        visible = true;
        disabled = false;
      });
    });
  }

  void onFound(String name, BluetoothDevice device) {
    if (device.advName.length > 1) {
      devices.insert(0, DeviceElement(name, device, _scaffoldKey, setState));
      setState(() {});
    } else {
      namelessDevices.add(DeviceElement(name, device, _scaffoldKey, setState));
    }
  }

  @override
  void initState() {
    super.initState();
    Be.init().then((value) => onScan());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF002A4D),
      systemNavigationBarColor: Colors.transparent, // Navigation bar color
    ));
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            bottom: false,
            child: Stack(children: [
              //black bg
              Container(color: const Color(0xFF002A4D)),
              //app title
              const Positioned(
                  top: 15,
                  left: 10,
                  child: Text("Bluetooth BMS",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 25))),
              //Scan button
              Positioned(
                  top: 10,
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
                  top: 60,
                  child: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xAE121315), Colors.black]),
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
                                height: 560,
                                child: ListView(key: UniqueKey(), children: [
                                  for (var d in devices)
                                    Device(
                                        title: d.title,
                                        device: d.device,
                                        scafoldContextKey: d.contextkey,
                                        rescan: onScan),
                                  if (visible)
                                    CupertinoButton(
                                        child: const Text("Show more"),
                                        onPressed: () {
                                          devices = [
                                            ...devices,
                                            ...namelessDevices
                                          ];
                                          visible = false;
                                          setState(() {});
                                        })
                                ]))
                          ]))),
              Positioned(
                  bottom: 40,
                  left: (MediaQuery.sizeOf(context).width / 2) - 50,
                  child: Image.asset("assets/logo.png", height: 100))
            ])));
  }
}
