import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/settings/SwitchField.dart';
import 'package:bluetooth_bms/settings/ThreeInputField.dart';
import 'package:bluetooth_bms/settings/TwoInputField.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Be.read_design_cap();
    return Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.black, Color(0xFF002A4D)])),
        child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 180, top: 80),
            children: [
              SettingsSection(title: "General", settingsElements: [
                OneInputField(text: "Number of Cells", onChange: (v) {}),
              ]),
              SettingsSection(
                  title: "Capacity Configuration",
                  settingsElements: [
                    OneInputField(
                        text: "Total Battery Capacity", onChange: (v) {}),
                    OneInputField(
                        text: "Total Cycle Capacity", onChange: (v) {}),
                    OneInputField(text: "Cell Full Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "Cell Minimal Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "Cell Self Discharge", onChange: (v) {}),
                    OneInputField(
                        text: "100% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "90% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "80% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "70% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "60% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "50% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "40% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "30% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "20% Capacity Voltage", onChange: (v) {}),
                    OneInputField(
                        text: "10% Capacity Voltage", onChange: (v) {}),
                  ]),
              SettingsSection(
                  title: "Ballancer Configuration",
                  settingsElements: [
                    OneInputField(text: "Start Voltage", onChange: (v) {}),
                    OneInputField(text: "Delta to Balance", onChange: (v) {}),
                    SwitchField(
                        value: false,
                        text: "Balancer Enabled",
                        onChange: (v) {}),
                    SwitchField(
                        value: true,
                        text: "Balance only while charging",
                        onChange: (v) {})
                  ]),
              SettingsSection(
                  title: "Function Configuration",
                  settingsElements: [
                    SwitchField(
                        value: false,
                        text: "SW switch circuit",
                        onChange: (v) {}),
                    SwitchField(
                        value: true, text: "Show Celsius", onChange: (v) {})
                  ]),
              SettingsSection(title: "Protection", settingsElements: [
                ThreeInputField(
                    text: "OverVoltage II",
                    firstOnChange: (v) {},
                    secondOnChange: (v) {},
                    thirdOnChange: (v) {},
                    firstHeader: "Trigger",
                    secondHeader: "Release",
                    thirdHeader: "Delay")
                //twoInputField SettingsElement
                //twoInputField SettingsElement
                //ThreeInputField SettingsElement
              ]),
              SettingsSection(title: "Advanced Protection", settingsElements: [
                TwoInputField(
                  text: "OverVoltage II",
                  firstOnChange: (v) {},
                  secondOnChange: (v) {},
                  firstHeader: "Trigger",
                  secondHeader: "Delay",
                ),
                TwoInputField(
                    text: "Undervoltage II",
                    firstOnChange: (v) {},
                    secondOnChange: (v) {}),
                TwoInputField(
                    text: "Overcurrent II",
                    firstOnChange: (v) {},
                    secondOnChange: (v) {})
              ]),
              SettingsSection(title: "Temperature Sensor", settingsElements: [
                OneInputField(text: "Number of Cells", onChange: (v) {}),
                //Check SettingsElement
              ]),
            ]));
  }
}
