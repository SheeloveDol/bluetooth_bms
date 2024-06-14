import 'dart:async';

import 'package:bluetooth_bms/dashboard/BState.dart';
import 'package:bluetooth_bms/dashboard/CState.dart';
import 'package:bluetooth_bms/dashboard/Control.dart';
import 'package:bluetooth_bms/dashboard/Records.dart';
import 'package:bluetooth_bms/dashboard/TempData.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_bms/utils.dart';
import '../src.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DashBoard extends StatefulWidget {
  DashBoard({super.key});
  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  String title = "No Device";
  ScrollController controller = ScrollController();
  double height = 0;
  late Map<String, dynamic> configMap;
  Timer? _timer;
  bool alternate = true;
  bool done = false;

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
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
    if (Be.savedDevice == null) {
      super.initState();
    } else {
      title = Be.title!;
      Be.connect(Be.savedDevice!).then((map) async {
        configMap = map;
        done = true;
        if (map["error"] == null) {
          setState(() {});

          // _timer =
          //     Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
          //   if (!Be.communicatingNow) {
          //     (alternate) ? await Be.getBasicInfo() : await Be.getCellInfo();
          //     alternate = !alternate;
          //   }
          // });
        } else {
          if (this.mounted) {
            setState(() {});
            quicktell(context, "Could not connect to $title ${map["error"]}");
          }
        }
      });
      super.initState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
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
          BatteryControl(title: title, height: height),
          Visibility(
              visible: !done && (Be.savedDevice != null),
              child: Container(
                  color: Colors.white10,
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.black))))
        ]));
  }
}
