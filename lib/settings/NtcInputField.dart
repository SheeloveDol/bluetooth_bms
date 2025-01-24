import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';

class NtcInputfield extends SettingsElement {
  int value = 0;
  final String text;
  final Function(int) onChange;
  NtcInputfield({super.key, required this.text, required this.onChange});

  final TextStyle titleStyle = const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 183, 183, 183),
      fontWeight: FontWeight.bold);

  void onSingularChange(int index, bool activated) {
    value |= (activated) ? 1 : 0 << (index - 1);
    onChange(value);
  }

  bool activated(int index) => ((Data.param_ntc_en >> (index - 1)) & 1) == 1;

  @override
  Widget build(BuildContext context) {
    List<NtcField> ntcs = [];
    value = Data.param_ntc_en;
    for (var i = 1; i <= 8; i++) {
      ntcs.add(NtcField(
          title: "T$i",
          index: i - 1,
          activated: activated(i), //to change to add a list of NTCs
          onChange: onSingularChange));
    }
    if (ntcs.isEmpty) {
      ntcs.add(NtcField(
          title: "T0", index: 0, activated: false, onChange: (i, v) {}));
    }
    return Container(
        alignment: Alignment.bottomLeft,
        margin: const EdgeInsets.all(3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 225, child: Text(text, style: titleStyle)),
          Wrap(children: ntcs)
        ]));
  }
}

class NtcField extends SettingsField {
  bool activated;
  final String title;
  final int index;
  final Function(int, bool) onChange;
  late Function setState;
  NtcField(
      {super.key,
      required this.title,
      required this.index,
      required this.activated,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () {
      var update = ontap(context);
      if (update) {
        activated = !activated;
        setState();
        onChange(index, activated);
      }
    }, child: StatefulBuilder(builder: (context, setState) {
      this.setState = () => setState(() {});
      return Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          height: 55,
          width: 60,
          decoration: BoxDecoration(
              color: (activated) ? Colors.greenAccent : const Color(0xFF00192E),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.thermostat, color: Colors.white, size: 35),
            Column(children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.white))
            ])
          ]));
    }));
  }
}
