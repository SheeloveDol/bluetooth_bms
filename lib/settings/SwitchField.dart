import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwitchField extends SettingsElement {
  SwitchField({super.key, required this.text, required this.onChange, required this.value});
  bool value;
  final String text;
  final Function(bool) onChange;
  final TextStyle titleStyle =
      const TextStyle(fontSize: 14, color: Color.fromARGB(255, 183, 183, 183), fontWeight: FontWeight.bold);

  void ontaped(BuildContext con) {
    print("tapped");
    if (Be.locked) {
      showDialogAdaptive(con,
          title: Text("Unable to modify"), content: Text(" Modification is currently locked"), actions: []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => ontaped(context),
        child: Container(
            alignment: Alignment.bottomLeft,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SizedBox(width: 170, child: Text(text, style: titleStyle)),
              Switch.adaptive(value: value, onChanged: (!Be.locked) ? onChange : null)
            ])));
  }
}
