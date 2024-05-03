import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class BatteryControl extends StatefulWidget {
  BatteryControl({super.key, required this.height, required this.title});
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
        height: 190 - widget.height,
        decoration: BoxDecoration(
            color: (widget.height > 0) ? const Color(0xF2002A4D) : null,
            gradient: (widget.height > 0)
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Color(0xFF002A4D)]),
            borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.center,
        child: (widget.height > 0)
            ? BatteryControlSmall()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Left(),
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
    var watts =
        "${(Data.pack_ma[0] == "-") ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma[0] == "-") ? "Out" : "In"}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(padding: EdgeInsets.only(top: 35)),
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Bolts(position: BoltPosition.right),
          (Data.pack_ma[0] != "-")
              ? const SizedBox(height: 15)
              : Text(ma,
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
          (Data.pack_ma[0] != "-")
              ? const SizedBox(height: 15)
              : Text(watts,
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
  double batterySize = 80;
  @override
  Widget build(BuildContext context) {
    int level = Data.cap_pct;
    batterySize = MediaQuery.sizeOf(context).width * 0.17;

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
                margin: const EdgeInsets.only(left: 7),
                color: const Color(0xFF00C106),
                width: (level * batterySize * 0.0187 - 20 < 0)
                    ? 0
                    : level * batterySize * 0.0187 - 20,
                height: batterySize - 2),
            Container(
                child: Stack(alignment: Alignment.center, children: [
              Image.asset(
                "assets/bat.png",
                height: batterySize,
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                Text("${Data.cycle_cap}Ah/${Data.design_cap}Ah",
                    style: const TextStyle(height: 0, fontSize: 10))
              ])
            ]))
          ])
        ]));
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
    var ma =
        "${(Data.pack_ma[0] == "-") ? Data.pack_ma.substring(1) : Data.pack_ma}A ${(Data.pack_ma[0] == "-") ? "Out" : "In"}";
    var watts =
        "${(Data.pack_ma[0] == "-") ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma[0] == "-") ? "Out" : "In"}";
    return Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Bolts(position: BoltPosition.left),
      (Data.pack_ma[0] == "-")
          ? const SizedBox(height: 15)
          : Text(ma, style: const TextStyle(fontSize: 11, color: Colors.white)),
      (Data.pack_ma[0] == "-")
          ? const SizedBox(height: 15)
          : Text(watts,
              style: const TextStyle(fontSize: 11, color: Colors.white)),
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
      (Data.chargeStatus)
          ? Bolts(position: BoltPosition.left)
          : const CupertinoButton(
              pressedOpacity: 0.1,
              color: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 15),
              onPressed: chargePressed,
              child: Text("Charge", style: TextStyle(fontSize: 11))),
      const Padding(padding: EdgeInsets.only(right: 12)),
      Stack(alignment: Alignment.centerLeft, children: [
        Container(
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 0, 193, 3),
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(30))),
            width: (level - 15 < 0) ? 0 : level - 15,
            height: 49),
        Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                "assets/bat.png",
                height: 50,
              ),
              Text(
                "${Data.cap_pct}%",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 15),
              )
            ],
          ),
        ),
      ]),
      const Padding(padding: EdgeInsets.only(right: 12)),
      (Data.dischargeStatus)
          ? Bolts(position: BoltPosition.right)
          : const CupertinoButton(
              pressedOpacity: 0.1,
              color: Colors.red,
              padding: EdgeInsets.all(3),
              onPressed: dischargePressed,
              child: Text("Discharge", style: TextStyle(fontSize: 11)))
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

enum BoltPosition {
  left,
  right;
}

class Bolts extends StatefulWidget {
  final BoltPosition position;

  Bolts({super.key, required this.position});

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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    setState(() => colors.setAll(
        0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]));
  }

  void start() {
    if (Data.pack_ma != "0.00" &&
        _timer == null &&
        ((widget.position == BoltPosition.right && Data.pack_ma[0] == "-") ||
            (widget.position == BoltPosition.left && Data.pack_ma[0] != "-"))) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (Data.pack_ma == "0.00") {
          stop();
          return;
        }
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
  Widget build(BuildContext context) {
    start();
    return Row(children: [
      Icon(Icons.bolt, size: 20, color: colors[0]),
      Icon(Icons.bolt, size: 20, color: colors[1]),
      Icon(Icons.bolt, size: 20, color: colors[2]),
      Icon(Icons.bolt, size: 20, color: colors[3])
    ]);
  }
}
