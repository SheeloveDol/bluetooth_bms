import 'dart:ui';

import 'package:flutter/material.dart';
import 'src.dart';

class BatteryControl extends StatefulWidget {
  const BatteryControl({super.key});
  @override
  State<StatefulWidget> createState() => _BatteryControlState();
}

class _BatteryControlState extends State<BatteryControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin:
            const EdgeInsets.only(top: 100, left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                    decoration: BoxDecoration(
                        color: Color(0x0EFFFFFF),
                        borderRadius: BorderRadius.circular(30)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Left(), Middle(), Right()])))));
  }
}

class Right extends StatefulWidget {
  Right({super.key});
  double batteryH = 210;
  @override
  State<StatefulWidget> createState() => _RightState();
}

class _RightState extends State<Right> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}

class Middle extends StatefulWidget {
  Middle({super.key});
  double batteryH = 210;
  @override
  State<StatefulWidget> createState() => _MiddleState();
}

class _MiddleState extends State<Middle> {
  @override
  Widget build(BuildContext context) {
    int level = 50;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Container(
          decoration: BoxDecoration(
              color: Color.fromARGB(255, 0, 193, 6),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
          height: (widget.batteryH - level - 20 < 0)
              ? 0
              : widget.batteryH - level - 20,
          width: widget.batteryH / 2,
        ),
        Image.asset(
          "assets/bat.png",
          height: widget.batteryH,
        ),
        Padding(
            padding: EdgeInsets.only(bottom: 30),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                "90%",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 20),
              ),
              Text("55.20V"),
              Text("302/320Ah"),
            ])),
        Align(
          alignment: Alignment.topCenter,
          child: Text(
            "wec3",
            style: TextStyle(color: Colors.white),
          ),
        )
      ]),
    );
  }
}

class Left extends StatefulWidget {
  const Left({super.key});

  @override
  State<StatefulWidget> createState() => _LeftState();
}

class _LeftState extends State<Left> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
