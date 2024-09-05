import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/settings/SwitchField.dart';
import 'package:bluetooth_bms/settings/ThreeInputField.dart';
import 'package:bluetooth_bms/settings/TwoInputField.dart';
import 'package:bluetooth_bms/settings/ntcInputField.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key, required this.tiles}) {
    Be.readSettings();
  }
  List<int> tiles;
  @override
  State<StatefulWidget> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  Map<int, Widget> tilesMap = {
    0: SettingsSection(key: UniqueKey(), title: "General", settingsElements: [
      OneInputField(text: "Number of Cells", initialValue: Data.cell_cnt, onChange: (v) {}),
      OneInputField(text: "Number of Sensors", initialValue: Data.ntc_cnt, onChange: (v) {}),
      NtcInputfield(text: "Activated Temperatue Sensors", onChange: (v) {}) //TODO
    ]),
    1: SettingsSection(key: UniqueKey(), title: "Capacity Configuration", settingsElements: [
      OneInputField(text: "Total Battery Capacity", initialValue: Data.param_design_cap, onChange: (v) {}),
      OneInputField(text: "Total Cycle Capacity", initialValue: Data.param_cycle_cap, onChange: (v) {}),
      OneInputField(text: "Cell Full Voltage", initialValue: Data.param_cell_full_mv, onChange: (v) {}),
      OneInputField(text: "Cell Minimal Voltage", initialValue: Data.param_cell_min_mv, onChange: (v) {}),
      OneInputField(text: "Cell Self Discharge", initialValue: Data.param_cell_d_perc, onChange: (v) {}),
      // OneInputField(text: "100% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "90% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "80% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "70% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "60% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "50% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "40% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "30% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "20% Capacity Voltage", onChange: (v) {}),
      // OneInputField(text: "10% Capacity Voltage", onChange: (v) {}),
    ]),
    2: SettingsSection(key: UniqueKey(), title: "Ballancer Configuration", settingsElements: [
      OneInputField(text: "Start Voltage", initialValue: Data.param_bal_start, onChange: (v) {}),
      OneInputField(text: "Delta to Balance", initialValue: Data.param_bal_delta, onChange: (v) {}),
      SwitchField(value: false, text: "Balancer Enabled", onChange: (v) {}), //TODO
      SwitchField(value: true, text: "Balance only while charging", onChange: (v) {}) //TODO
    ]),
    3: SettingsSection(key: UniqueKey(), title: "Function Configuration", settingsElements: [
      SwitchField(value: false, text: "SW switch circuit", onChange: (v) {}),
      OneInputField(text: "Mosfet switch delay", initialValue: Data.param_del_fet_ctrl_sw, onChange: (v) {}),
      OneInputField(text: "LED delay", initialValue: Data.param_del_led, onChange: (v) {})
    ]),
    4: SettingsSection(key: UniqueKey(), title: "Protection", settingsElements: [
      ThreeInputField(
          text: "Charging Over temp",
          firstOnChange: (v) {},
          secondOnChange: (v) {},
          thirdOnChange: (v) {},
          firstHeader: "Trigger",
          secondHeader: "Release",
          thirdHeader: "Delay")
    ]),
    5: SettingsSection(key: UniqueKey(), title: "Advanced Protection", settingsElements: [
      TwoInputField(
        text: "OverVoltage II",
        firstOnChange: (v) {},
        secondOnChange: (v) {},
        firstHeader: "Trigger",
        secondHeader: "Delay",
      ),
      TwoInputField(text: "Undervoltage II", firstOnChange: (v) {}, secondOnChange: (v) {}),
      TwoInputField(text: "Overcurrent II", firstOnChange: (v) {}, secondOnChange: (v) {})
    ]),
  };

  List<Widget> tiles = [];
  @override
  void initState() {
    for (var i = 0; i < widget.tiles.length; i++) {
      tiles.add(tilesMap[widget.tiles[i]]!);
    }
    super.initState();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final tileIndex = widget.tiles.removeAt(oldIndex);
    widget.tiles.insert(newIndex, tileIndex);
    final tile = tiles.removeAt(oldIndex);
    tiles.insert(newIndex, tile);
    setState(() {});
  }

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return const Card(
              color: Color(0xFF002A4D),
              elevation: 3,
              margin: EdgeInsets.all(10),
              child: Padding(
                  padding: EdgeInsets.all(70),
                  child: Center(child: Text("Drag", style: TextStyle(color: Color(0xFF00233F), fontSize: 50)))));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            height: MediaQuery.sizeOf(context).height,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Color(0xFF002A4D)])),
            child: ReorderableListView(
                onReorder: reorder,
                proxyDecorator: proxyDecorator,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 180, top: 80),
                children: tiles)),
        if (!Data.availableData)
          Positioned(
              top: 30,
              right: 30,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                      color: Color(0xFF003F73),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 5, offset: Offset(4, 4))]),
                  child: const Row(children: [
                    Text("Getting Data", style: TextStyle(color: Colors.white, fontSize: 20)),
                    SizedBox(width: 10),
                    CircularProgressIndicator.adaptive(strokeWidth: 6, backgroundColor: Color(0xFF002A4D))
                  ])))
      ],
    );
  }
}
