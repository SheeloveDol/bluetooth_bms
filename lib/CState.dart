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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    for (var i = 0; i < 14; i++) {
      cells.add(Container(
        width: 12,
        height: 12,
        color: Colors.blue,
      ));
    }
  }

  Widget grid() {
    List<Widget> columnContent = [];
    Column column = Column(children: columnContent);

    List<Widget> rowContent = [];
    Row row = Row(children: rowContent);
    for (var i = 0; i < cells.length; i++) {
      rowContent.add(cells[i]);
      if (i % 3 == 0 && i != 0) {
        rowContent = new List<Widget>.empty(growable: true);
        row = new Row(children: rowContent);
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
                    decoration: BoxDecoration(
                        color: Color(0x565B5B5B),
                        borderRadius: BorderRadius.circular(30)),
                    child: grid()))));
  }
}
