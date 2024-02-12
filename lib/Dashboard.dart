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
  const DashBoard({super.key, required this.title, required this.device});
  final String title;
  final BluetoothDevice device;

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  ScrollController controller = ScrollController();
  double height = 0;

  onDisconnect(BuildContext context) {
    Be.disconnect(widget.device).then((value) {
      quicktell(context, "Disconnected from ${widget.title}");
      Navigator.pop(context);
    });
  }

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
    Be.setUpdater(() => setState(() {}));
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
                child: Stack(children: [
                  ListView(
                      padding: EdgeInsets.only(top: 230 - height),
                      physics: const BouncingScrollPhysics(),
                      controller: controller,
                      children: const <Widget>[
                        BatteryState(),
                        CellsState(),
                        Temperatures(),
                        Reports()
                      ]),
                  BatteryControl(
                      height: height, back: () => onDisconnect(context))
                ]))));
  }
}
