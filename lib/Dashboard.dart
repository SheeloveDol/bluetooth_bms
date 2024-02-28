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
  dynamic cellInfo;
  dynamic statsreports;
  double height = 0;
  late Map<String, dynamic> configMap;
  onDisconnect() {
    Navigator.pop(context);
    try {
      Be.disconnect(widget.device, configMap["sub"], configMap["notify"])
          .then((value) {
        quicktell(context, "Disconnected from ${widget.title}");
      });
    } catch (e) {
      print("object");
    }
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
    Be.connect(widget.device).then((map) {
      configMap = map;
      if (map["error"] == null) {
        Data.setAvailableData(true);
        cellInfo = Be.getCellInfo();
        statsreports = Be.getStatsReport();
        setState(() {});
      } else {
        quicktell(
            context, "Could not connect to ${widget.title} ${map["error"]}");
      }
    });
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
                        const BatteryState(),
                        FutureBuilder<bool>(
                          future: cellInfo,
                          builder: (context, snapshot) {
                            return const CellsState();
                          },
                        ),
                        const Temperatures(),
                        FutureBuilder<bool>(
                            future: statsreports,
                            builder: (context, snapshot) {
                              return const Reports();
                            })
                      ]),
                  BatteryControl(
                      title: widget.title,
                      height: height,
                      back: () => onDisconnect())
                ]))));
  }
}
