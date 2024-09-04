import 'package:flutter/material.dart';
import '../src.dart';

class CellsState extends StatefulWidget {
  const CellsState({super.key});
  @override
  State<StatefulWidget> createState() => _CellsStateState();
}

class _CellsStateState extends State<CellsState> {
  double celldiff = 0;
  @override
  void initState() {
    super.initState();
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
    if (Data.cell_mv[index] > Data.bal_start) {
      color = Color(0xFFCA5100);
      weight = FontWeight.bold;
    }
    if (Data.cell_mv[index] < Data.bal_start) {
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
              style: TextStyle(fontSize: 12, color: titleColor, fontWeight: titleWeight),
            ),
            Text("${Data.cell_mv[index].toStringAsFixed(3)}V",
                style: TextStyle(fontSize: 12, height: 0, color: color, fontWeight: weight))
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: const Color(0x2EFFFFFF)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(children: [for (int i = 0; i < Data.cell_cnt; i++) cell("cell${i + 1}", i)]),
          Wrap(alignment: WrapAlignment.spaceBetween, children: [
            Text("Cell Difference:${Data.celldif.toStringAsFixed(3)}",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const Padding(padding: EdgeInsets.only(left: 5)),
            const Text("Balance inactive", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ]),
          const Wrap(alignment: WrapAlignment.spaceBetween, children: [
            Text("High cell group", style: TextStyle(color: Color(0xFFCA5100), fontWeight: FontWeight.bold)),
            Padding(padding: EdgeInsets.only(left: 5)),
            Text("Low cell group", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold))
          ])
        ]));
  }
}
