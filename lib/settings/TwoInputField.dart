import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TwoInputField extends SettingsElement {
  TwoInputField(
      {super.key,
      required this.text,
      required this.firstOnChange,
      required this.secondOnChange,
      this.firstHeader,
      this.secondHeader,
      this.firstInitialValue,
      this.secondInitialValue});
  String? firstHeader;
  String? secondHeader;
  String? firstInitialValue;
  String? secondInitialValue;
  final String text;
  final Function(String) firstOnChange;
  final Function(String) secondOnChange;
  final TextStyle titleStyle = const TextStyle(fontSize: 14, color: Color(0xFFB7B7B7), fontWeight: FontWeight.bold);
  @override
  Widget build(Object context) {
    return Container(
        alignment: Alignment.bottomLeft,
        margin: const EdgeInsets.all(3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 110, child: Text(text, style: titleStyle)),
          ValueField(
            onChange: firstOnChange,
            initialValue: firstInitialValue,
            header: firstHeader,
          ),
          ValueField(
            onChange: secondOnChange,
            initialValue: secondInitialValue,
            header: secondHeader,
          ),
        ]));
  }
}
