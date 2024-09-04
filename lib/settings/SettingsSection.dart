import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key, required this.title, required this.settingsElements});
  final String title;
  final List<SettingsElement> settingsElements;
  @override
  State<SettingsSection> createState() => _MySettingsSection();
}

class _MySettingsSection extends State<SettingsSection> {
  final Divider divider = const Divider();
  final TextStyle titleStyle = const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent,
        child: Card(
            color: const Color(0xBC002A4D),
            elevation: 3,
            margin: const EdgeInsets.all(10),
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  Text(widget.title, style: titleStyle),
                  divider,
                  ...widget.settingsElements,
                  const Padding(padding: EdgeInsets.only(top: 3))
                ]))));
  }
}

abstract class SettingsElement extends StatelessWidget {
  const SettingsElement({super.key});
}

abstract class SettingsField extends StatelessWidget {
  const SettingsField({super.key});

  void ontap(BuildContext con) {
    print("tapped");
    if (Be.locked) {
      showDialogAdaptive(con,
          title: Text("Unable to modify"), content: Text(" Modification is currently locked"), actions: []);
    }
  }
}
