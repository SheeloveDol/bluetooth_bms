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
          Icon(Icons.thermostat, size: 20),
          Column(children: [
            Text(title, style: TextStyle(fontSize: 11, color: Colors.white)),
            Text(temp, style: TextStyle(fontSize: 11, color: Colors.white))
          ])
        ]));
  }

  Widget grid() {
    List<Widget> columnContent = [];
    Column column = Column(children: columnContent);

    List<Widget> rowContent = [];
    Row row = Row(children: rowContent);
    for (var i = 0; i < temps.length; i++) {
      rowContent.add(temps[i]);
      if (i % 6 == 0) {
        rowContent = List<Widget>.empty(growable: true);
        row = Row(children: rowContent);
        columnContent.add(row);
      }
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      children: temps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 100,
                  height: 80,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Color(0x565B5B5B),
                      borderRadius: BorderRadius.circular(30)),
                  child: ListView.builder(
                      itemCount: temps.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => temps[index]),
                ))));
  }
}
