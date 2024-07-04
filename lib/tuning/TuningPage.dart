import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/tuning/GroupButton.dart';
import 'package:bluetooth_bms/tuning/TuningSection.dart';
import 'package:flutter/material.dart';

class TuningPage extends StatelessWidget {
  const TuningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
            padding: EdgeInsets.only(top: 80),
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
            child: ListView(children: [
              Container(
                  child: PageView(key: UniqueKey(), children: [
                TuningSection(title: "Modify Cell Voltage", settingsElements: [
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                  OneInputField(text: "Number of Cells", onChange: (v) {}),
                ]),
                TuningSection(
                    title: "Modify Cell Amperage", settingsElements: []),
                TuningSection(
                    title: "Modify Temperature Sensor", settingsElements: []),
              ])),
              GroupButton()
            ])));
  }
}
