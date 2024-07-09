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
      this.firstHeader,
      this.secondHeader,
      this.thirdHeader,
      this.firstInitialValue,
      this.secondInitialValue,
      this.thirdInitialValue});
  String? firstHeader;
  String? secondHeader;
  String? thirdHeader;
  String? firstInitialValue;
  String? secondInitialValue;
  String? thirdInitialValue;
  final String text;
  final Function(String) firstOnChange;
  final Function(String) secondOnChange;
  final Function(String) thirdOnChange;
  final TextStyle titleStyle = const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 183, 183, 183),
      fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    double l = MediaQuery.sizeOf(context).width;
    return Container(
        alignment: Alignment.bottomLeft,
        margin: const EdgeInsets.all(3),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
              width: (l > 250) ? 110 : 200,
              child: Text(text, style: titleStyle)),
          SizedBox(
              width: 250,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ValueField(
                  onChange: firstOnChange,
                  initialValue: firstInitialValue,
                  header: firstHeader,
                ),
                const Padding(padding: EdgeInsets.only(right: 3)),
                ValueField(
                  onChange: secondOnChange,
                  initialValue: secondInitialValue,
                  header: secondHeader,
                ),
                const Padding(padding: EdgeInsets.only(right: 3)),
                ValueField(
                  onChange: thirdOnChange,
                  initialValue: thirdInitialValue,
                  header: thirdHeader,
                ),
                const Padding(padding: EdgeInsets.only(right: 3))
              ]))
        ]));
  }
}
