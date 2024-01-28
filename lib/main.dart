import 'package:bluetooth_bms/BState.dart';
import 'package:bluetooth_bms/CState.dart';
import 'package:bluetooth_bms/Control.dart';
import 'package:bluetooth_bms/Devices.dart';
import 'package:bluetooth_bms/Records.dart';
import 'package:bluetooth_bms/TempData.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  onScan() async {
    setState(() => disabled = true);
    setState(() => devices.clear());
    if (!await Be.init()) {
      return;
    }
    await Be.scan(onFound);
    setState(() => disabled = false);
  }

  void onFound(String name) async {
    devices.add(Device(title: name));
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
      Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF002A4D), Colors.black]))),
      const Positioned(
          top: 95,
          left: 10,
          child: Text("Bluetooth BMS",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 25))),
      Positioned(
          top: 90,
          right: 60,
          child: ElevatedButton(
              onPressed: (disabled) ? null : onScan,
              child: const Text("SCAN",
                  style: TextStyle(
                      color: Color(0xEC121315),
                      fontWeight: FontWeight.w300,
                      fontSize: 20,
                      letterSpacing: 2)))),
      Positioned(
          top: 90,
          right: 0,
          child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(Icons.more_vert, color: Colors.white, size: 45),
              onPressed: () {})),
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
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.all(10),
                        height: 600,
                        child: ListView(
                          key: UniqueKey(),
                          children: devices,
                        ))
                  ]))),
    ]));
  }
}

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  ScrollController controller = ScrollController();
  double height = 0;
  @override
  void initState() {
    controller.addListener(() {
      if (controller.offset > 2) {
        setState(() {
          height = 105;
        });
        return;
      }
      if (controller.offset.isNegative) {
        setState(() {
          height = 0;
        });
        return;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
            child: Stack(children: [
              ListView(
                  padding: EdgeInsets.only(top: 230 - height),
                  physics: const BouncingScrollPhysics(),
                  controller: controller,
                  children: <Widget>[
                    const BatteryState(),
                    const CellsState(),
                    const Temperatures(),
                    const Reports()
                  ]),
              BatteryControl(height: height)
            ])));
  }
}
