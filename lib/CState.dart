import 'dart:ui';

import 'package:flutter/material.dart';
import 'src.dart';

class CellsState extends StatefulWidget {
  const CellsState({super.key});
  @override
  State<StatefulWidget> createState() => _CellsStateState();
}

class _CellsStateState extends State<CellsState> {
  List<Widget> cells = [];
  double celldiff = 0.2;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cells.add(Container());
    cells.add(cell("Cell1", 3.44));
    for (var i = 2; i < 16; i++) {
      cells.add(cell("Cell$i", 3.45));
    }
    cells.add(cell("Cell16", 3.46));
  }

  Widget cell(String title, double volts) {
    Color color = Colors.black;
    FontWeight weight = FontWeight.normal;
    if (volts > 3.45) {
      color = Color(0xFFCA5100);
      weight = FontWeight.bold;
    }
    if (volts < 3.45) {
      color = Colors.yellow;
      weight = FontWeight.bold;
    }
    return Container(
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
                fontSize: 12,
              ),
            ),
            Text("${volts}V",
                style: TextStyle(
                    fontSize: 12, height: 0, color: color, fontWeight: weight))
          ])
        ])
      ]),
    );
  }

  Widget grid() {
    List<Widget> columnContent = [];
    Column column = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: columnContent);

    List<Widget> rowContent = [];
    Row row = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowContent);
    for (var i = 0; i < cells.length; i++) {
      rowContent.add(cells[i]);
      if (i % 4 == 0) {
        rowContent = List<Widget>.empty(growable: true);
        row = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowContent);
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
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          grid(),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(children: [
                                  Text("Cell Difference:$celldiff",
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                  Text("Ballance inactive",
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold))
                                ]),
                                Column(children: [
                                  Text("High cell group",
                                      style: TextStyle(
                                          color: Color(0xFFCA5100),
                                          fontWeight: FontWeight.bold)),
                                  Text("Low cell group",
                                      style: TextStyle(
                                          color: Colors.yellow,
                                          fontWeight: FontWeight.bold))
                                ])
                              ])
                        ])))));
  }
}
