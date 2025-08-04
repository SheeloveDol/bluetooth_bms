import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThreeInputField extends SettingsElement {
  ThreeInputField(
      {super.key,
      required this.text,
      required this.firstOnChange,
      required this.secondOnChange,
      required this.thirdOnChange,
      this.pair,
      this.firstHeader,
      this.secondHeader,
      this.thirdHeader,
      this.firstInitialValue,
      this.secondInitialValue,
      this.thirdInitialValue});
  String? firstHeader;
  String? secondHeader;
  String? thirdHeader;
  dynamic firstInitialValue;
  dynamic secondInitialValue;
  dynamic thirdInitialValue;
  bool? pair;
  final String text;
  final Function(String) firstOnChange;
  final Function(String) secondOnChange;
  final Function(String) thirdOnChange;
  final TextStyle titleStyle =
      const TextStyle(fontSize: 14, color: Color.fromARGB(255, 183, 183, 183), fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    double l = MediaQuery.sizeOf(context).width;
    pair ??= false;
    return Container(
        decoration: (pair!) ? BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black12) : null,
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(3),
        margin: const EdgeInsets.only(top: 1, bottom: 5, left: 1, right: 1),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SizedBox(width: (l <= 400) ? 100 : 150, child: Text(text, style: titleStyle)),
          SizedBox(
              width: 170,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ValueField(
                  onChange: firstOnChange,
                  initialValue: firstInitialValue,
                  header: firstHeader,
                  width: 60,
                ),
                const Padding(padding: EdgeInsets.only(right: 3)),
                ValueField(
                  onChange: secondOnChange,
                  initialValue: secondInitialValue,
                  header: secondHeader,
                  width: 60,
                ),
                const Padding(padding: EdgeInsets.only(right: 3)),
                ValueField(
                  onChange: thirdOnChange,
                  initialValue: thirdInitialValue,
                  header: thirdHeader,
                  width: 35,
                ),
                const Padding(padding: EdgeInsets.only(right: 3))
              ]))
        ]));
  }
}
