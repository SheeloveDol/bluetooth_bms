import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class BatteryControl extends StatefulWidget {
  BatteryControl(
      {super.key,
      required this.height,
      required this.back,
      required this.title});
  final Function() back;
  final String title;
  double height;
  @override
  State<StatefulWidget> createState() => _BatteryControlState();
}

class _BatteryControlState extends State<BatteryControl> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10, top: 40),
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.only(left: 10, right: 15, bottom: 15),
        height: 185 - widget.height,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Color(0xFF002A4D)]),
            borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.center,
        child: (widget.height == 105)
            ? BatteryControlSmall()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Left(back: widget.back),
                          Middle(title: widget.title),
                          Right()
                        ]),
                    Text(Data.timeLeft,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20))
                  ]));
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
    var ma =
        "${(Data.pack_ma[0] == "-") ? Data.pack_ma.substring(1) : Data.pack_ma}A ${(Data.pack_ma[0] == "-") ? "Out" : "In"}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(padding: EdgeInsets.only(top: 35)),
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Bolts(),
          Text(ma, style: const TextStyle(fontSize: 11, color: Colors.white)),
          Text(
              "${(Data.pack_ma[0] == "-") ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma[0] == "-") ? "Out" : "In"}",
              style: const TextStyle(fontSize: 11, color: Colors.white))
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
        CupertinoButton(
          pressedOpacity: 0.1,
          color: (Data.dischargeStatus) ? Colors.green : Colors.red,
          padding: const EdgeInsets.all(3),
          onPressed: dischargePressed,
          child: const Text("Discharge", style: TextStyle(fontSize: 11)),
        )
      ],
    );
  }
}

class Middle extends StatefulWidget {
  Middle({super.key, required this.title});
  final String title;
  @override
  State<StatefulWidget> createState() => _MiddleState();
}

class _MiddleState extends State<Middle> {
  @override
  Widget build(BuildContext context) {
    int level = Data.cap_pct;

    return Container(
      padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
      child: Column(children: [
        Text(widget.title,
            style: TextStyle(
                fontSize: (widget.title.length > 20) ? 10 : 15,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const Padding(padding: EdgeInsets.only(bottom: 10)),
        Stack(alignment: Alignment.centerLeft, children: [
          AnimatedContainer(
              duration: Durations.extralong3,
              margin: EdgeInsets.only(left: 7),
              color: const Color(0xFF00C106),
              width: (level * 1.7 - 20 < 0) ? 0 : level * 1.7 - 20,
              height: 79),
          Image.asset(
            "assets/bat.png",
            height: 90,
          ),
          Positioned.fill(
              right: 15,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${Data.cap_pct}%",
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 20),
                    ),
                    Text(
                      "${Data.pack_mv}V",
                      style: const TextStyle(height: 0, fontSize: 10),
                    ),
                    Text(
                        "${Data.cycle_cap}Ah/${Data.design_cap}Ah", // remove milliamps from the string, supposed to be "Ah" not "mAh"
                        style: const TextStyle(height: 0, fontSize: 10)),
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
              child: const Row(children: [
                Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
                Text("Disconnect",
                    style: TextStyle(color: Colors.white, fontSize: 11))
              ])),
          Text((Data.chargeStatus) ? "ON" : "OFF",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: (Data.chargeStatus) ? Colors.green : Colors.red)),
          CupertinoButton(
              pressedOpacity: 0.1,
              color: (Data.chargeStatus) ? Colors.green : Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              onPressed: chargePressed,
              child: const Text("Charge", style: TextStyle(fontSize: 11)))
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
          pressedOpacity: 0.1,
          color: (Data.chargeStatus) ? Colors.green : Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          onPressed: chargePressed,
          child: const Text("Charge", style: TextStyle(fontSize: 11))),
      const Padding(padding: EdgeInsets.only(right: 12)),
      Stack(alignment: Alignment.centerLeft, children: [
        Container(
            decoration: const BoxDecoration(
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
      const Padding(padding: EdgeInsets.only(right: 12)),
      CupertinoButton(
          pressedOpacity: 0.1,
          color: (Data.dischargeStatus) ? Colors.green : Colors.red,
          padding: const EdgeInsets.all(3),
          onPressed: dischargePressed,
          child: const Text("Discharge", style: TextStyle(fontSize: 11)))
    ]);
  }
}

void dischargePressed() {
  if (Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns off dischacharge and turns on charge
    Be.off_discharge_on_charge();
  } else if (!Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns on dischacharge and turns on charge
    Be.on_discharge_on_charge();
  } else if (!Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns on dischacharge and turns off charge
    Be.on_discharge_off_charge();
  } else if (Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns off dischacharge and turns off charge
    Be.off_discharge_off_charge();
  }
}

void chargePressed() {
  if (Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns on dischacharge and turns off charge
    Be.on_discharge_off_charge();
  } else if (!Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns off dischacharge and turns off charge
    Be.off_discharge_off_charge();
  } else if (!Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns off dischacharge and turns on charge
    Be.off_discharge_on_charge();
  } else if (Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns on dischacharge and turns on charge
    Be.on_discharge_on_charge();
  }
}

class Bolts extends StatefulWidget {
  Bolts({super.key});
  @override
  _BoltsState createState() => _BoltsState();
}

class _BoltsState extends State<Bolts> {
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

    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (Data.pack_ma != "0.00") {
        c++;
        if (c > 3) {
          c = 0;
        }
        setState(() {
          colors.setAll(
              0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]);
          colors[c] = Colors.green;
        });
      } else {
        setState(()=>
          colors.setAll(
              0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]);
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(Icons.bolt,
          size: 20, color: (Data.pack_ma[0] == "-") ? colors[0] : colors[3]),
      Icon(Icons.bolt,
          size: 20, color: (Data.pack_ma[0] == "-") ? colors[1] : colors[2]),
      Icon(Icons.bolt,
          size: 20, color: (Data.pack_ma[0] == "-") ? colors[2] : colors[1]),
      Icon(Icons.bolt,
          size: 20, color: (Data.pack_ma[0] == "-") ? colors[3] : colors[0])
    ]);
  }
}
