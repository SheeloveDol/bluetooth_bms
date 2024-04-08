import 'dart:async';

import 'package:bluetooth_bms/BState.dart';
import 'package:bluetooth_bms/CState.dart';
import 'package:bluetooth_bms/Control.dart';
import 'package:bluetooth_bms/Records.dart';
import 'package:bluetooth_bms/TempData.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_bms/utils.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'src.dart';

class DashBoard extends StatefulWidget {
  DashBoard({
    super.key,
    required this.title,
    required this.device,
  });
  final String title;
  final BluetoothDevice device;

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  ScrollController controller = ScrollController();
  double height = 0;
  late Map<String, dynamic> configMap;
  Timer? _timer;
  bool alternate = true;
  bool done = false;
  onDisconnect() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      Data.setAvailableData(false);

      Be.disconnect(totaly: true).then((value) {
        quicktell(Be.context!, "Disconnected from ${widget.title}");
      });
      Data.clear();
    } catch (e) {
      print("Disconnected but with error");
    }
    super.dispose();
  }

  @override
  void initState() {
    controller.addListener(() {
      if (controller.offset > 2) {
        setState(() {
          height = 100;
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
    Be.setUpdater(() => setState(() {}));
    Be.setCurrentContext(context);
    Be.connect(widget.device).then((map) async {
      configMap = map;
      done = true;
      if (map["error"] == null) {
        Be.readWhatsLeft();
        Data.setAvailableData(true);
        setState(() {});

        _timer =
            Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
          if (!Be.communicatingNow) {
            (alternate) ? await Be.getBasicInfo() : await Be.getCellInfo();
            alternate = !alternate;
          }
        });
      } else {
        setState(() {});
        quicktell(
            context, "Could not connect to ${widget.title} ${map["error"]}");
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            bottom: false,
            child: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF002A4D), Colors.black])),
                child: Stack(children: <Widget>[
                  Container(
                      margin: EdgeInsets.only(top: 235 - height),
                      child: ListView(
                          physics: const BouncingScrollPhysics(),
                          controller: controller,
                          children: <Widget>[
                            BatteryState(),
                            CellsState(),
                            Temperatures(),
                            Reports()
                          ])),
                  BatteryControl(
                      title: widget.title,
                      height: height,
                      back: () => onDisconnect()),
                  Visibility(
                      visible: !done,
                      child: Container(
                          color: Colors.white10,
                          child: const Center(
                              child: const CircularProgressIndicator(
                                  color: Colors.black))))
                ]))));
  }
}
