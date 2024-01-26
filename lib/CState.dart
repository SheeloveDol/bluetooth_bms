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

    cells.add(Container());
  }

  Widget grid() {
    if (cells.length % 4 == 0) {
      var cols = cells.length / 4;
      for (var i = 0; i <= cols; i++) {
        for (var i = 0; i < 5; i++) {
          var rows = <Widget>[];
          rows.add(cells[i]);
          if (i == 4) {}
        }
      }
    }
    return Row();
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
