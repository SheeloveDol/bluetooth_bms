import 'package:flutter/material.dart';
import 'src.dart';

class Temperatures extends StatefulWidget {
  const Temperatures({super.key});
  @override
  State<StatefulWidget> createState() => _TemperaturesState();
}

class _TemperaturesState extends State<Temperatures> {
  Widget generateTempWidget(String title, int index) {
    return Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: const Color(0x2DFFFFFF),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.thermostat, size: 20),
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
      padding: const EdgeInsets.all(15),
      height: 100,
      width: 80,
      decoration: BoxDecoration(
          color: const Color(0x565B5B5B),
          borderRadius: BorderRadius.circular(30)),
      child: ListView.builder(
          itemCount: Data.ntc_cnt,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return generateTempWidget("T${index + 1}", index);
          }),
    );
  }
}
