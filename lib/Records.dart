import 'dart:ui';

import 'package:flutter/material.dart';
import 'src.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});
  @override
  State<StatefulWidget> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 250,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Color(0x565B5B5B),
                      borderRadius: BorderRadius.circular(30)),

                  //child: Row( [ 1, 2, 3 ])
                  //1 : Column [1,2,3,4,5,6]
                  //...
                ))));
  }
}
