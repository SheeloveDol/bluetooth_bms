import 'dart:ui';

import 'package:flutter/material.dart';
import 'src.dart';

class Temperatures extends StatefulWidget {
  const Temperatures({super.key});
  @override
  State<StatefulWidget> createState() => _TemperaturesState();
}

class _TemperaturesState extends State<Temperatures> {
  List<Widget> temps = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    temps.add(Container());
    temps.add(generateTempWidget("T1", "17 C"));
    temps.add(generateTempWidget("T2", "17 C"));
    temps.add(generateTempWidget("T3", "-2 C"));

    for (var i = 4; i <= 8; i++) {
      temps.add(generateTempWidget("T$i", "NA"));
    }
  }

  Widget generateTempWidget(String title, String temp) {
    return Container(
        margin: EdgeInsets.all(3),
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: Color.fromARGB(46, 255, 255, 255),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(
            Icons.thermostat,
            size: 45,
          ),
          Column(children: [Text(title), Text(temp)])
        ]));
  }

  Widget grid() {
    List<Widget> columnContent = [];
    Column column = Column(children: columnContent);

    List<Widget> rowContent = [];
    Row row = Row(children: rowContent);
    for (var i = 0; i < temps.length; i++) {
      rowContent.add(temps[i]);
      if (i % 4 == 0) {
        rowContent = List<Widget>.empty(growable: true);
        row = Row(children: rowContent);
        columnContent.add(row);
      }
    }
    return column;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Color(0x565B5B5B),
                      borderRadius: BorderRadius.circular(30)),
                  child: grid(),
                ))));
  }
}
