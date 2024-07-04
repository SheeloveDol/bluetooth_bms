import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:flutter/material.dart';

class TuningSection extends StatefulWidget {
  const TuningSection(
      {super.key, required this.title, required this.settingsElements});
  final String title;
  final List<SettingsElement> settingsElements;
  @override
  State<TuningSection> createState() => _MyTuningSection();
}

class _MyTuningSection extends State<TuningSection> {
  final Divider divider = const Divider();
  final TextStyle titleStyle = const TextStyle(
      fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    return Card(
        color: const Color(0xBC002A4D),
        elevation: 3,
        margin: const EdgeInsets.all(10),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      textAlign: TextAlign.left, style: titleStyle),
                  divider,
                  ...widget.settingsElements,
                  const Padding(padding: EdgeInsets.only(top: 3))
                ])));
  }
}
