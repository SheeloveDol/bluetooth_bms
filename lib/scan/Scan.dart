import 'package:bluetooth_bms/scan/Devices.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DeviceElement {
  final String title;
  final BluetoothDevice device;
  final Function setState;

  const DeviceElement(this.title, this.device, this.setState);
}

class ScanPage extends StatefulWidget {
  final Function gotoDashboard;

  const ScanPage({super.key, required this.gotoDashboard});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool disabled = false;
  bool visible = false;
  bool shadingVisible = false;
  List<DeviceElement> devices = [];
  List<DeviceElement> namelessDevices = [];
  Function? setSpecificState;
  final ScrollController _controller = ScrollController();

  Future<void> onScan() async {
    shadingVisible = false;
    setState(() => disabled = true);
    setState(() => devices.clear());
    if (!await Be.init()) {
      return;
    }
    setState(() => visible = false);
    Be.scan(onFound);
    await Future.delayed(const Duration(seconds: 5)).then((value) {
      if (this.mounted) {
        setState(() {
          visible = true;
          disabled = false;
        });
      }
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
    Be.setUpdater(() => setState(() {}));
    super.initState();

    Be.init().then((value) => {onScan()});
  }

  showAbout() {
    showAboutDialog(
        context: context,
        applicationName: "Bluetooth BMS",
        applicationIcon:
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset("assets/logo.png", height: 50)),
        children: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                launchUrlString("https://www.royerbatteries.com/terms/");
              },
              child: const Text("Privacy Terms and agreement"))
        ],
        applicationLegalese: "\u{a9} Royer Batteries");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: false,
        child: Stack(children: [
          //black bg
          Container(color: const Color(0xFF002A4D)),
          //app title
          const Positioned(
              top: 20,
              left: 10,
              child:
                  Text("Bluetooth BMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 25))),
          //Options button
          Positioned(
              top: 15,
              right: 10,
              child: GestureDetector(
                  onTap: showAbout,
                  child: const Icon(
                    Icons.more_vert_outlined,
                    color: Color(0xFF04080B),
                    size: 45,
                  ))),
          //List of all devices
          Positioned.fill(
              top: 80,
              child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xAE121315), Colors.black]),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const Padding(padding: EdgeInsets.only(bottom: 10)),
                    const Text("Devices",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 20, letterSpacing: 2)),
                    Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        height: MediaQuery.sizeOf(context).height - 310,
                        child: Stack(alignment: Alignment.topCenter, children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: RefreshIndicator(
                                onRefresh: onScan,
                                child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    controller: _controller,
                                    key: UniqueKey(),
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    children: [
                                      for (var d in devices)
                                        Device(title: d.title, device: d.device, goToDashboard: widget.gotoDashboard),
                                      if (visible)
                                        CupertinoButton(
                                            child: const Text(
                                              "Show All",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            onPressed: () {
                                              devices = [...devices, ...namelessDevices];
                                              visible = false;
                                              setState(() {});
                                            })
                                    ])),
                          ),
                          StatefulBuilder(builder: (context, setThisState) {
                            setSpecificState = () => setThisState(() {});
                            return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Visibility(
                                  visible: shadingVisible,
                                  child: Container(
                                      height: 15,
                                      decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Color(0xFF0D1A25), Colors.transparent])))),
                              if (devices.length > 5)
                                Container(
                                    height: 20,
                                    decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [Color(0xFF020405), Colors.transparent])))
                            ]);
                          })
                        ]))
                  ]))),
          Positioned(
              bottom: 40,
              left: (MediaQuery.sizeOf(context).width / 2) - 50,
              child: Image.asset("assets/logo.png", height: 100))
        ]));
  }
}
