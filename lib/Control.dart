import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class BatteryControl extends StatefulWidget {
  BatteryControl({super.key, required this.height, required this.back});
  final Function() back;
  double height;
  @override
  State<StatefulWidget> createState() => _BatteryControlState();
}

class _BatteryControlState extends State<BatteryControl> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        margin: const EdgeInsets.only(top: 40, left: 15, right: 15, bottom: 10),
        duration: Duration(milliseconds: 300),
        height: 180 - widget.height,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                    decoration: BoxDecoration(
                        color: Color(0x565B5B5B),
                        borderRadius: BorderRadius.circular(30)),
                    child: (widget.height == 105)
                        ? BatteryControlSmall()
                        : Column(children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Left(back: widget.back),
                                  Middle(),
                                  Right()
                                ]),
                            Text("5H 30M To Empty",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))
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
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(padding: EdgeInsets.only(top: 35)),
        Container(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              bolts(),
              Text(
                  "${(Data.pack_ma[0] == "-") ? Data.pack_ma.substring(1) : Data.pack_ma} ${(Data.pack_ma[0] == "-") ? "Out" : "In"}",
                  style: TextStyle(fontSize: 11, color: Colors.white)),
              Text(
                  "${(Data.pack_ma[0] == "-") ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma[0] == "-") ? "Out" : "In"}",
                  style: TextStyle(fontSize: 11, color: Colors.white))
            ])),
        Padding(padding: EdgeInsets.symmetric(vertical: 3)),
        CupertinoButton(
          color: Colors.green,
          padding: EdgeInsets.all(3),
          onPressed: () {},
          child: Text(
            "Discharge",
            style: TextStyle(fontSize: 11),
          ),
        )
      ],
    );
  }
}

class Middle extends StatefulWidget {
  Middle({
    super.key,
  });
  @override
  State<StatefulWidget> createState() => _MiddleState();
}

class _MiddleState extends State<Middle> {
  String battery_name = "48V 320Ah - 245";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int level = Data.cap_pct;

    return Container(
      padding: EdgeInsets.only(top: 10, right: 10, left: 10),
      child: Column(children: [
        Text(battery_name,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Padding(padding: EdgeInsets.only(bottom: 10)),
        Stack(alignment: Alignment.centerLeft, children: [
          Container(
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 0, 193, 6),
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(30))),
              width: (level * 1.45 - 10 < 0) ? 0 : level * 1.45 - 10,
              height: 79),
          Image.asset(
            "assets/bat.png",
            height: 80,
          ),
          Positioned.fill(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(
                  "${Data.cap_pct}%",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 20),
                ),
                Text(
                  "${Data.pack_mv}V",
                  style: TextStyle(height: 0, fontSize: 10),
                ),
                Text("${Data.cycle_cap}Ah/${Data.design_cap}Ah",
                    style: TextStyle(height: 0, fontSize: 10)),
              ]))
        ])
      ]),
    );
  }
}

class Left extends StatefulWidget {
  const Left({super.key, required this.back});
  final Function() back;
  @override
  State<StatefulWidget> createState() => _LeftState();
}

class _LeftState extends State<Left> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => widget.back(),
              child: Row(children: [
                Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
                Text("Back",
                    style: TextStyle(color: Colors.white, fontSize: 11))
              ])),
          Text("OFF",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.red)),
          CupertinoButton(
              color: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 15),
              onPressed: () {},
              child: Text("Charge", style: TextStyle(fontSize: 11)))
        ]));
  }
}

class BatteryControlSmall extends StatefulWidget {
  BatteryControlSmall({super.key});
  @override
  State<StatefulWidget> createState() => _BatteryControlSmallState();
}

class _BatteryControlSmallState extends State<BatteryControlSmall> {
  @override
  Widget build(BuildContext context) {
    int level = Data.cap_pct;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      CupertinoButton(
          color: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 15),
          onPressed: () {},
          child: Text("Charge", style: TextStyle(fontSize: 11))),
      Padding(padding: EdgeInsets.only(right: 12)),
      Stack(alignment: Alignment.centerLeft, children: [
        Container(
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 193, 3),
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(30))),
            width: (level - 15 < 0) ? 0 : level - 15,
            height: 49),
        Image.asset(
          "assets/bat.png",
          height: 50,
        )
      ]),
      Padding(padding: EdgeInsets.only(right: 12)),
      CupertinoButton(
          color: Colors.green,
          padding: EdgeInsets.all(3),
          onPressed: () {},
          child: Text(
            "Discharge",
            style: TextStyle(fontSize: 11),
          ))
    ]);
  }
}

class bolts extends StatefulWidget {
  @override
  _boltsState createState() => _boltsState();
}

class _boltsState extends State<bolts> {
  List<Color> colors = [
    Colors.yellow,
    Colors.yellow,
    Colors.yellow,
    Colors.yellow
  ];
  int c = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!Data.fet_status[0] && !Data.fet_status[1]) {
      _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
        c++;
        if (c > 3) {
          c = 0;
        }
        setState(() {
          colors.setAll(
              0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]);
          colors[c] = Colors.green;
        });
      });
    }
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(Icons.bolt,
          size: 20, color: (!Data.fet_status[0]) ? colors[0] : colors[3]),
      Icon(Icons.bolt,
          size: 20, color: (!Data.fet_status[0]) ? colors[1] : colors[2]),
      Icon(Icons.bolt,
          size: 20, color: (!Data.fet_status[0]) ? colors[2] : colors[1]),
      Icon(Icons.bolt,
          size: 20, color: (!Data.fet_status[0]) ? colors[3] : colors[0])
    ]);
  }
}
