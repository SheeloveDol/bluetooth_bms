import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.black, Color(0xFF002A4D)])),
        child: ListView(children: [
          SettingsSection(title: "General", settingsElements: [
            OneInputField(text: "Number of Cells", onChange: (v) {}),
          ]),
          SettingsSection(title: "Capacity Configuration", settingsElements: [
            OneInputField(text: "Total Battery Capacity", onChange: (v) {}),
            OneInputField(text: "...", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
          ]),
          SettingsSection(title: "Ballancer Configuration", settingsElements: [
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            OneInputField(text: "Number of Cells", onChange: (v) {}),
            //switch SettingsElement
            //switch SettingsElement
          ]),
          SettingsSection(title: "Function Configuration", settingsElements: [
            //switch SettingsElement
            //switch SettingsElement
          ]),
          SettingsSection(title: "Protection", settingsElements: [
            //twoInputField SettingsElement
            //twoInputField SettingsElement
            //twoInputField SettingsElement
            //ThreeInputField SettingsElement
          ]),
          SettingsSection(title: "Advanced Protection", settingsElements: [
            //Check SettingsElement
          ]),
          SettingsSection(title: "Temperature Sensor", settingsElements: [
            //Check SettingsElement
          ]),
        ]));
  }
}
