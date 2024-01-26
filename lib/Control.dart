import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class BatteryControl extends StatefulWidget {
  ScrollController controller;

  BatteryControl({super.key, required this.controller});
  @override
  State<StatefulWidget> createState() => _BatteryControlState();
}

class _BatteryControlState extends State<BatteryControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                    decoration: BoxDecoration(
                        color: Color(0x565B5B5B),
                        borderRadius: BorderRadius.circular(30)),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Left(),
                            Middle(
                              controller: widget.controller,
                            ),
                            Right()
                          ]),
                      Text("5H 30M To Empty",
                          style: TextStyle(color: Colors.white, fontSize: 20))
                    ])))));
  }
}

class Right extends StatefulWidget {
  Right({
    super.key,
  });
  double batteryH = 210;
  @override
  State<StatefulWidget> createState() => _RightState();
}

class _RightState extends State<Right> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Row(children: [
                Icon(Icons.bolt, color: Colors.yellow),
                Icon(Icons.bolt, color: Colors.green),
                Icon(Icons.bolt, color: Colors.green)
              ]),
              Text("9.54A Out", style: TextStyle(color: Colors.white)),
              Text("122W out", style: TextStyle(color: Colors.white))
            ])),
        Padding(padding: EdgeInsets.symmetric(vertical: 20)),
        CupertinoButton(
          color: Colors.green,
          padding: EdgeInsets.all(3),
          onPressed: () {},
          child: Text("Discharge"),
        )
      ],
    );
  }
}

class Middle extends StatefulWidget {
  Middle({super.key, required this.controller});
  ScrollController controller;
  double batteryH = 200;
  @override
  State<StatefulWidget> createState() => _MiddleState();
}

class _MiddleState extends State<Middle> {
  String battery_name = "48V 320Ah - 245";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        widget.batteryH -= widget.controller.offset;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int level = 0;

    return Container(
      padding: EdgeInsets.only(top: 10, right: 10, left: 10),
      child: Column(children: [
        Text(battery_name,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Padding(padding: EdgeInsets.only(bottom: 10)),
        Stack(alignment: Alignment.bottomCenter, children: [
          Container(
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 193, 6),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30))),
            height: (widget.batteryH - level - 30 < 0)
                ? 0
                : widget.batteryH - level - 30,
            width: widget.batteryH / 2,
          ),
          Image.asset(
            "assets/bat.png",
            height: widget.batteryH,
          ),
          Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
        ])
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
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "OFF",
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.w900, color: Colors.red),
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 20)),
          CupertinoButton(
            color: Colors.red,
            padding: EdgeInsets.all(3),
            onPressed: () {},
            child: Text("Charge"),
          )
        ],
      ),
    );
  }
}
