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
  const DashBoard({
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
  onDisconnect() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      Data.setAvailableData(false);
      Be.disconnect(totaly: true).then((value) {
        quicktell(context, "Disconnected from ${widget.title}");
      });
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
    Be.connect(widget.device).then((map) async {
      configMap = map;
      if (map["error"] == null) {
        Data.setAvailableData(true);
        setState(() {});
        /*_timer =
            Timer.periodic(const Duration(milliseconds: 700), (timer) async {
          if (!Be.communicatingNow) {
            var good =
                (alternate) ? await Be.getBasicInfo() : await Be.getCellInfo();
            if (!good) {
              quicktell(context, "Lost connection to the Device");
              _timer?.cancel();
            }
            alternate = !alternate;
          }
        });*/
      } else {
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
                child: Stack(children: [
                  ListView(
                      padding: EdgeInsets.only(top: 230 - height),
                      physics: const BouncingScrollPhysics(),
                      controller: controller,
                      children: <Widget>[
                        BatteryState(),
                        CellsState(),
                        Temperatures(),
                        Reports()
                      ]),
                  BatteryControl(
                      title: widget.title,
                      height: height,
                      back: () => onDisconnect())
                ]))));
  }
}
