import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../src.dart';

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
    var size = MediaQuery.sizeOf(context).width;
    return AnimatedContainer(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10, top: 40),
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
        height: (size > 260) ? 190 - widget.height : 300 - widget.height,
        decoration: BoxDecoration(
            color: (widget.height > 0) ? const Color(0xF2002A4D) : null,
            gradient: (widget.height > 0)
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.transparent, Color(0xFF002A4D)]),
            borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: (widget.height > 0)
              ? BatteryControlSmall()
              : Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  const SizedBox(height: 5),
                  Text("widget.title",
                      style: TextStyle(
                          fontSize: (widget.title.length > 20) ? 10 : 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (size > 260)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Left(), Middle(title: widget.title), Right()]),
                  if (size <= 260)
                    Column(children: [
                      Middle(title: widget.title),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Left(), Right()])
                    ]),
                  const SizedBox(height: 5),
                  Text(Data.timeLeft, style: const TextStyle(color: Colors.white, fontSize: 20))
                ]),
        ));
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
        "${(Data.pack_ma.isNegative) ? Data.pack_ma.toStringAsFixed(2).substring(1) : Data.pack_ma.toStringAsFixed(2)}A ${(Data.pack_ma.isNegative) ? "Out" : "In"}";
    var watts =
        "${(Data.pack_ma.isNegative) ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma.isNegative) ? "Out" : "In"}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Bolts(position: BoltPosition.right),
          (Data.dischargeStatus && !Data.chargeStatus)
              ? Text(ma, style: const TextStyle(fontSize: 11, color: Colors.white))
              : const SizedBox(height: 15),
          (Data.dischargeStatus && !Data.chargeStatus)
              ? Text(watts, style: const TextStyle(fontSize: 11, color: Colors.white))
              : const SizedBox(height: 15)
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
  double batterySize = 70;
  @override
  Widget build(BuildContext context) {
    int level = 100; //Data.cap_pct;
    var size = MediaQuery.sizeOf(context).width;
    if (size > 260) batterySize = min(MediaQuery.sizeOf(context).width * 0.18, 105);
    if (size <= 260) batterySize = MediaQuery.sizeOf(context).width * 0.24;

    return Column(children: [
      const SizedBox(height: 45),
      Stack(children: [
        AnimatedContainer(
            duration: Durations.extralong3,
            margin: const EdgeInsets.only(left: 7, top: 3),
            decoration: BoxDecoration(color: const Color(0xFF00C106), borderRadius: BorderRadius.circular(10)),
            width: (level * batterySize * 0.0187 - 20 < 0) ? 0 : level * batterySize * 0.0187 - 18,
            height: batterySize - 4),
        Container(
            width: batterySize * 2,
            height: batterySize,
            padding:const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: const BoxDecoration(image: DecorationImage(fit: BoxFit.scaleDown, image: AssetImage('assets/bat.png'))),
            child: Stack(children: [
              FittedBox(
                  fit: BoxFit.fitWidth,

                  child: Column(children: [
                    Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Text(
                        "${Data.cap_pct}%",
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 30),
                      ),
                      Text(
                        "${Data.pack_mv.toStringAsFixed(2)}V",
                        style: TextStyle(height: 0, fontSize: 15),
                      ),
                      Text("${Data.cycle_cap}Ah/${Data.design_cap}Ah", style: TextStyle(height: 0, fontSize: 15))
                    ])
                  ]))
            ]))
      ])
    ]);
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
        "${(Data.pack_ma.isNegative) ? Data.pack_ma.toStringAsFixed(2).substring(1) : Data.pack_ma.toStringAsFixed(2)}A ${(Data.pack_ma.isNegative) ? "Out" : "In"}";
    var watts =
        "${(Data.pack_ma.isNegative) ? Data.watts.substring(1) : Data.watts}W ${(Data.pack_ma.isNegative) ? "Out" : "In"}";
    return Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Bolts(position: BoltPosition.left),
        (Data.chargeStatus || Data.dischargeStatus && Data.chargeStatus)
            ? Text(ma, style: const TextStyle(fontSize: 11, color: Colors.white))
            : const SizedBox(height: 15),
        (Data.chargeStatus || Data.dischargeStatus && Data.chargeStatus)
            ? Text(watts, style: const TextStyle(fontSize: 11, color: Colors.white))
            : const SizedBox(height: 15)
      ]),
      const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
      CupertinoButton(
          pressedOpacity: 0.1,
          color: (Data.chargeStatus) ? Colors.green : Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          onPressed: chargePressed,
          child: const Text("Charge", style: TextStyle(fontSize: 11)))
    ]);
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
                color: Color.fromARGB(255, 0, 193, 3), borderRadius: BorderRadius.horizontal(left: Radius.circular(30))),
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
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15),
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
    return;
  } else if (!Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns on dischacharge and turns on charge
    Be.on_discharge_on_charge();
    return;
  } else if (!Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns on dischacharge and turns off charge
    Be.on_discharge_off_charge();
    return;
  } else if (Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns off dischacharge and turns off charge
    Be.off_discharge_off_charge();
    return;
  }
}

void chargePressed() {
  if (Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns on dischacharge and turns off charge
    Be.on_discharge_off_charge();
    return;
  } else if (!Data.dischargeStatus && Data.chargeStatus) {
    //send payload that turns off dischacharge and turns off charge
    Be.off_discharge_off_charge();
    return;
  } else if (!Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns off dischacharge and turns on charge
    Be.off_discharge_on_charge();
    return;
  } else if (Data.dischargeStatus && !Data.chargeStatus) {
    //send payload that turns on dischacharge and turns on charge
    Be.on_discharge_on_charge();
    return;
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
  List<Color> colors = [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow];
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
    setState(() => colors.setAll(0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]));
  }

  void start() {
    if (Data.pack_ma != 0 &&
        _timer == null &&
        ((widget.position == BoltPosition.left && ((Data.dischargeStatus && Data.chargeStatus) || Data.chargeStatus)) ||
            (widget.position == BoltPosition.right && Data.dischargeStatus))) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (Data.pack_ma == 0) {
          stop();
          return;
        }
        c++;
        if (c > 3) {
          c = 0;
        }
        setState(() {
          colors.setAll(0, [Colors.yellow, Colors.yellow, Colors.yellow, Colors.yellow]);
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
