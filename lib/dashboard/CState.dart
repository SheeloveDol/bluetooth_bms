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
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: const BoxDecoration(
          image: DecorationImage(
        image: AssetImage('assets/bat.png'),
        fit: BoxFit.scaleDown, // or BoxFit.fill, BoxFit.contain, etc.
      )),
      child: Padding(
          padding: const EdgeInsets.only(left: 5, right: 13),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: titleColor, fontWeight: titleWeight),
                ),
                Text("${Data.cell_mv[index].toStringAsFixed(3)}V",
                    style: TextStyle(fontSize: 12, height: 0, color: color, fontWeight: weight))
              ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: const Color(0x2EFFFFFF)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Wrap(children: [for (int i = 0; i < Data.cell_cnt; i++) cell("cell${i + 1}", i)]),
          FittedBox(
              fit: BoxFit.fitWidth,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Text("Cell Difference: ${Data.celldif.toStringAsFixed(3)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Padding(padding: EdgeInsets.only(left: 3)),
                const Text("Balance inactive", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
              ])),
          FittedBox(
              fit: BoxFit.fitWidth,
              child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Text("High cell group", style: TextStyle(color: Color(0xFFCA5100), fontWeight: FontWeight.bold)),
                Padding(padding: EdgeInsets.only(left: 3)),
                Text("Low cell group", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold))
              ]))
        ]));
  }
}
