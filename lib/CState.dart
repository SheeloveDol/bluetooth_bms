import 'package:flutter/material.dart';
import 'src.dart';

class CellsState extends StatefulWidget {
  const CellsState({super.key});
  @override
  State<StatefulWidget> createState() => _CellsStateState();
}

class _CellsStateState extends State<CellsState> {
  double celldiff = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    celldiff = Data.celldif;
  }

  Widget cell(String title, int index) {
    Color color = Colors.black;
    Color titleColor = Colors.black;
    FontWeight weight = FontWeight.normal;
    FontWeight titleWeight = FontWeight.normal;
    if (Data.bal[index]) {
      titleColor = Colors.blue;
      titleWeight = FontWeight.bold;
    }
    if (Data.cell_mv[index] > 3.45) {
      color = Color(0xFFCA5100);
      weight = FontWeight.bold;
    }
    if (Data.cell_mv[index] < 3.45) {
      color = Colors.yellow;
      weight = FontWeight.bold;
    }
    return Container(
      width: 75,
      padding: EdgeInsets.all(2),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          Image.asset(
            "assets/bat.png",
            height: 35,
          ),
          Column(children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 12, color: titleColor, fontWeight: titleWeight),
            ),
            Text("${Data.cell_mv[index].toStringAsFixed(2)}V",
                style: TextStyle(
                    fontSize: 12, height: 0, color: color, fontWeight: weight))
          ])
        ])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0x565B5B5B),
            borderRadius: BorderRadius.circular(30)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Wrap(children: [
                for (int i = 0; i < Data.cell_cnt; i++) cell("cell${i + 1}", i)
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Column(children: [
                  Text("Cell Difference:${celldiff.toStringAsFixed(1)}",
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  const Text("Ballance inactive",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold))
                ]),
                const Column(children: [
                  Text("High cell group",
                      style: TextStyle(
                          color: Color(0xFFCA5100),
                          fontWeight: FontWeight.bold)),
                  Text("Low cell group",
                      style: TextStyle(
                          color: Colors.yellow, fontWeight: FontWeight.bold))
                ])
              ])
            ]));
  }
}
