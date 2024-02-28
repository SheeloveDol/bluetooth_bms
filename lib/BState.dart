import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class BatteryState extends StatefulWidget {
  const BatteryState({super.key});
  @override
  State<StatefulWidget> createState() => _BatteryStateState();
}

class _BatteryStateState extends State<BatteryState> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: const Color(0x565B5B5B),
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "State",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              ActiveStates()
                            ]),
                        CupertinoButton(
                          color: Colors.white,
                          padding: const EdgeInsets.all(3),
                          onPressed: () {},
                          child: const Text("Reset",
                              style:
                                  TextStyle(fontSize: 11, color: Colors.black)),
                        )
                      ]),
                ))));
  }
}

class ActiveStates extends StatefulWidget {
  const ActiveStates({super.key});

  @override
  State<StatefulWidget> createState() => _ActiveStatesState();
}

class _ActiveStatesState extends State<ActiveStates> {
  Widget generateStateElement(String title) {
    var description = getDescription(title);
    Color color = Colors.orange;
    if (title == "SCP") {
      color = Colors.red;
    }
    if (description.length > 40) {
      var position = description.indexOf(" ", 23).clamp(0, description.length);
      description = description.replaceFirst(" ", "\n  ", position);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("$title",
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      const Padding(padding: EdgeInsets.only(left: 5)),
      Text(
        description,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        overflow: TextOverflow.visible,
        softWrap: true,
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: Data.curr_err
            .map((e) => generateStateElement(e))
            .toList()
            .reversed
            .toList());
  }
}

String getDescription(String s) {
  switch (s) {
    case "CHVP":
      return ": Cell high voltage protection";
    case "CLVP":
      return ": Cell low voltage protection";
    case "PHVP":
      return ": Pack high voltage protection";
    case "PLVP":
      return ": Pack low voltage protection";
    case "COTP":
      return ": Charge over Temperature protection";
    case "CUTP":
      return ": Charge under temperature protection";
    case "DOTP":
      return ": Discharge over temperature protection";
    case "DUTP":
      return ": Discharge under temperature protection (0°C)";
    case "COCP":
      return ": Charge over current protection";
    case "DOCP":
      return ": Discharge over current protection";
    case "SCP":
      return ": Short circuit protection";
    case "FICE":
      return ": Frontend IC error (afe_err)";
    case "COBU":
      return ": Charge turned off by user (Button)";
    default:
      return ": Unknown Error";
  }
}
