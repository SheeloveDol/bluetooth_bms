import 'package:bluetooth_bms/BState.dart';
import 'package:bluetooth_bms/CState.dart';
import 'package:bluetooth_bms/Control.dart';
import 'package:bluetooth_bms/Records.dart';
import 'package:bluetooth_bms/TempData.dart';
import 'package:flutter/material.dart';

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
