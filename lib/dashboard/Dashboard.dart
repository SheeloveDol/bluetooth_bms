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
  Timer? _t;
  bool alternate = true;
  double size = 0;

  @override
  void dispose() {
    _t?.cancel();
    controller.dispose();
    super.dispose();
  }

  void runPeriodic() {
    _t = Timer.periodic(const Duration(milliseconds: 1500), (t) async {
      if (!Be.locked) {
        await Be.lock();
      }

      if (!Be.communicatingNow) {
        (alternate) ? await Be.getBasicInfo() : await Be.getCellInfo();
        alternate = !alternate;
      }
    });
  }

  @override
  void initState() {
    if (!Be.locked) {
      Be.lock();
    }
    Be.setUpdater(() => setState(() {}));
    controller.addListener(() {
      if (controller.offset > 2) {
        setState(() => height = (size > 360) ? 100 : 210);
        return;
      }
      if (controller.offset.isNegative || controller.offset < 3) {
        setState(() => height = 0);
      }
    });
    if (Be.conectionState == DeviceConnectionState.disconnected) {
      super.initState();
      return;
    }
    if (Be.conectionState == DeviceConnectionState.connected) {
      Data.setAvailableData(true);
      runPeriodic();
      super.initState();
      return;
    }
    if (Be.conectionState == DeviceConnectionState.connecting) {
      title = Be.title!;
      super.initState();
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.sizeOf(context).width;
    return Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
        child: SafeArea(
            bottom: false,
            child: Stack(children: <Widget>[
              ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 200),
                  controller: controller,
                  children: <Widget>[
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 300), height: (size > 360) ? 235 - height : 350 - height),
                    DelayedBuilder(child: BatteryState()),
                    DelayedBuilder(child: CellsState()),
                    DelayedBuilder(child: Temperatures()),
                    DelayedBuilder(child: Reports())
                  ]),
              BatteryControl(title: title, height: height),
              Visibility(
                  visible: Be.conectionState == DeviceConnectionState.connecting,
                  child: Container(
                      color: Colors.white10, child: const Center(child: CircularProgressIndicator(color: Colors.black))))
            ])));
  }
}
