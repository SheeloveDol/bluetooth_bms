import 'dart:ui';

import 'package:flutter/material.dart';
import 'src.dart';

class Temperatures extends StatefulWidget {
  const Temperatures({super.key});
  @override
  State<StatefulWidget> createState() => _TemperaturesState();
}

class _TemperaturesState extends State<Temperatures> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Widget generateTempWidget(String title, int index) {
    return Container(
        margin: EdgeInsets.all(3),
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: Color.fromARGB(46, 255, 255, 255),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.thermostat, size: 20),
          Column(children: [
            Text(title,
                style: const TextStyle(fontSize: 11, color: Colors.white)),
            Text(Data.ntc_temp[index],
                style: const TextStyle(fontSize: 11, color: Colors.white))
          ])
        ]));
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
                      itemCount: Data.ntc_cnt,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return generateTempWidget("T${index + 1}", index);
                      }),
                ))));
  }
}
