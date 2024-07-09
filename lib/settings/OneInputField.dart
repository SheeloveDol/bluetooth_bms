import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OneInputField extends SettingsElement {
  OneInputField(
      {super.key,
      required this.text,
      required this.onChange,
      this.initialValue});
  String? initialValue;
  final String text;
  final Function(String) onChange;
  final TextStyle titleStyle = const TextStyle(
      fontSize: 14, color: Color(0xFFB7B7B7), fontWeight: FontWeight.bold);
  @override
  Widget build(Object context) {
    return Container(
        alignment: Alignment.bottomLeft,
        margin: const EdgeInsets.all(3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SizedBox(width: 170, child: Text(text, style: titleStyle)),
          ValueField(onChange: onChange, initialValue: initialValue)
        ]));
  }
}

class ValueField extends StatelessWidget {
  String? initialValue;
  final Function(String) onChange;
  String? header;
  String? unit;

  ValueField(
      {super.key, required this.onChange, this.initialValue, this.header});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (header != null)
        Text(header!,
            style: const TextStyle(fontSize: 10, color: Color(0xFFB7B7B7))),
      Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: (!Be.locked)
                  ? const Color(0xFF001424)
                  : const Color(0xFF00223D)),
          width: 80,
          height: 30,
          padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
          child: TextFormField(
              initialValue: initialValue,
              enabled: !Be.locked,
              onChanged: (value) => onChange(value),
              onTapOutside: (PointerDownEvent event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"^-?[\d,.]*$")),
              ],
              //textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  fillColor: Colors.blue,
                  errorBorder: InputBorder.none)))
    ]);
  }
}
