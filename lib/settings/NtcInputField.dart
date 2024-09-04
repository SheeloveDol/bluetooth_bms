import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';

class NtcInputfield extends SettingsElement {
  List<bool> value = [];
  final String text;
  final Function(List<bool>) onChange;
  NtcInputfield({super.key, required this.text, required this.onChange});

  final TextStyle titleStyle =
      const TextStyle(fontSize: 14, color: Color.fromARGB(255, 183, 183, 183), fontWeight: FontWeight.bold);

  void onSingularChange(int index, bool activated) {
    value[index] = activated;
  }

  @override
  Widget build(BuildContext context) {
    List<NtcField> ntcs = [];
    for (var i = 1; i <= Data.ntc_cnt; i++) {
      value.add(true); //to change to add a list of NTCs
      ntcs.add(NtcField(
          title: "T$i",
          index: i - 1,
          activated: true, //to change to add a list of NTCs
          onChange: onSingularChange));
    }
    if (ntcs.isEmpty) {
      ntcs.add(NtcField(title: "T0", index: 0, activated: false, onChange: (i, v) {}));
    }
    return Container(
        alignment: Alignment.bottomLeft,
        margin: const EdgeInsets.all(3),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SizedBox(width: 225, child: Text(text, style: titleStyle)), Wrap(children: ntcs)]));
  }
}

class NtcField extends SettingsField {
  final bool activated;
  final String title;
  final int index;
  final Function(int, bool) onChange;
  NtcField({super.key, required this.title, required this.index, required this.activated, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          ontap(context);
          onChange(index, !activated);
        },
        child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
                color: (activated) ? Colors.greenAccent : const Color(0xFF00192E), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.thermostat, color: Colors.white, size: 30),
              Column(children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.white)),
              ])
            ])));
  }
}
