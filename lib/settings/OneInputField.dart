import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:flutter/material.dart';

class OneInputField extends SettingsElement {
  const OneInputField({super.key, required this.text, required this.onChange});
  final String text;
  final Function(String) onChange;

  @override
  Widget build(Object context) {
    return Container(
        alignment: Alignment.bottomLeft,
        child: Wrap(
            direction: Axis.horizontal,
            verticalDirection: VerticalDirection.down,
            children: [
              Text(text),
              const SizedBox(width: 60),
              Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color(0xFF373737)),
                  width: 80,
                  height: 20,
                  padding: const EdgeInsets.only(
                      left: 5, right: 5, top: 5, bottom: 5),
                  child: TextField(
                      onChanged: (value) => onChange(value),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          fillColor: Colors.blue,
                          errorBorder: InputBorder.none)))
            ]));
  }
}
