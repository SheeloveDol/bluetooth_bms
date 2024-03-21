import 'package:bluetooth_bms/Devices.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MaterialApp(home: ScanPage()));
}

class DeviceElement {
  final String title;
  final BluetoothDevice device;
  final Function setState;

  const DeviceElement(this.title, this.device, this.setState);
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool disabled = false;
  bool visible = false;
  bool shadingVisible = false;
  List<DeviceElement> devices = [];
  List<DeviceElement> namelessDevices = [];
  Function? setSpecificState;
  final ScrollController _controller = ScrollController();

  onScan() async {
    shadingVisible = false;
    Be.setCurrentContext(context);
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
      devices.insert(0, DeviceElement(name, device, setState));
      setState(() {});
    } else {
      namelessDevices.add(DeviceElement(name, device, setState));
    }
  }

  @override
  void initState() {
    _controller.addListener(() {
      if (_controller.offset > 2) {
        shadingVisible = true;
        setSpecificState!();
        return;
      }
      if (_controller.offset <= 0) {
        shadingVisible = false;
        setSpecificState!();
        return;
      }
    });
    super.initState();

    Be.init().then((value) => onScan());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
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
                                height: MediaQuery.sizeOf(context).height - 270,
                                child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Container(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 2),
                                          child: ListView(
                                              controller: _controller,
                                              key: UniqueKey(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15),
                                              children: [
                                                for (var d in devices)
                                                  Device(
                                                      title: d.title,
                                                      device: d.device,
                                                      rescan: onScan),
                                                if (visible)
                                                  CupertinoButton(
                                                      child: const Text(
                                                        "Show All",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      onPressed: () {
                                                        devices = [
                                                          ...devices,
                                                          ...namelessDevices
                                                        ];
                                                        visible = false;
                                                        setState(() {});
                                                      })
                                              ])),
                                      StatefulBuilder(
                                          builder: (context, setThisState) {
                                        setSpecificState =
                                            () => setThisState(() {});
                                        return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Visibility(
                                                  visible: shadingVisible,
                                                  child: Container(
                                                      decoration: const BoxDecoration(
                                                          gradient: LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                            Color(0xFF0D1A25),
                                                            Colors.transparent
                                                          ])),
                                                      height: 15)),
                                              Container(
                                                  decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                          begin: Alignment
                                                              .bottomCenter,
                                                          end: Alignment
                                                              .topCenter,
                                                          colors: [
                                                        Color(0xFF04080B),
                                                        Colors.transparent
                                                      ])),
                                                  height: 20)
                                            ]);
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
