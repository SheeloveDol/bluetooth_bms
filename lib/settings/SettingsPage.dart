import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/settings/SettingsSection.dart';
import 'package:bluetooth_bms/settings/SwitchField.dart';
import 'package:bluetooth_bms/settings/ThreeInputField.dart';
import 'package:bluetooth_bms/settings/TwoInputField.dart';
import 'package:bluetooth_bms/settings/ntcInputField.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key, required this.tiles, required this.registerWrites});
  final Map<int, dynamic> registerWrites;
  List<int> tiles;
  @override
  State<StatefulWidget> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  List<Widget> tiles = [];
  @override
  void initState() {
    Be.setUpdater(() => setState(() {}));
    Be.readSettings();
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
                  child: Center(
                      child: Text("Drag",
                          style: TextStyle(
                              color: Color(0xFF00233F), fontSize: 50)))));
        });
  }

  @override
  Widget build(BuildContext context) {
    Map<int, Widget> tilesMap = {
      0: SettingsSection(key: UniqueKey(), title: "General", settingsElements: [
        OneInputField(
            text: "Number of Cells",
            initialValue: Data.cell_cnt,
            onChange: (v) => (widget.registerWrites[Data.CELL_CNT] = v)),
        NtcInputfield(
            text: "Activated Temperatue Sensors",
            onChange: (v) => widget.registerWrites[Data.NTC_EN] = v) //TODO
      ]),
      1: SettingsSection(
          key: UniqueKey(),
          title: "Capacity Configuration",
          settingsElements: [
            OneInputField(
                text: "Total Battery Capacity",
                initialValue: Data.param_design_cap,
                onChange: (v) => (widget.registerWrites[Data.DESIGN_CAP] = v)),
            OneInputField(
                text: "Total Cycle Capacity",
                initialValue: Data.param_cycle_cap,
                onChange: (v) => (widget.registerWrites[Data.CYCLE_CAP] = v)),
            OneInputField(
                text: "Cell Full Voltage",
                initialValue: Data.param_cell_full_mv,
                onChange: (v) =>
                    (widget.registerWrites[Data.CELL_FULL_MV] = v)),
            OneInputField(
                text: "Cell Minimal Voltage",
                initialValue: Data.param_cell_min_mv,
                onChange: (v) => widget.registerWrites[Data.CELL_MIN_MV] = v),
            OneInputField(
                text: "Cell Self Discharge",
                initialValue: Data.param_cell_d_perc,
                onChange: (v) => widget.registerWrites[Data.CELL_D_PERC] = v),
            // OneInputField(text: "100% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV-] = v),
            // OneInputField(text: "90% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV-] = v),
            // OneInputField(text: "80% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV-] = v),
            // OneInputField(text: "70% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV-] = v),
            // OneInputField(text: "60% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV-] = v),
            // OneInputField(text: "50% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV] = v),
            // OneInputField(text: "40% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV] = v),
            // OneInputField(text: "30% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV] = v),
            // OneInputField(text: "20% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV] = v),
            // OneInputField(text: "10% Capacity Voltage", onChange: (v) => widget.registerWrites[Data.CELL_FULL_MV] = v),
          ]),
      2: SettingsSection(
          key: UniqueKey(),
          title: "Ballancer Configuration",
          settingsElements: [
            OneInputField(
                text: "Start Voltage",
                initialValue: Data.param_bal_start,
                onChange: (v) => widget.registerWrites[Data.BAL_START] = v),
            OneInputField(
                text: "Delta to Balance",
                initialValue: Data.param_bal_delta,
                onChange: (v) => widget.registerWrites[Data.BAL_DELTA] = v),
            SwitchField(
                value: false,
                text: "Balancer Enabled",
                onChange: (v) =>
                    widget.registerWrites[Data.FUNCTION] = v), //TODO
            SwitchField(
                value: true,
                text: "Balance only while charging",
                onChange: (v) =>
                    widget.registerWrites[Data.FUNCTION] = v) //TODO
          ]),
      3: SettingsSection(
          key: UniqueKey(),
          title: "Function Configuration",
          settingsElements: [
            OneInputField(
                text: "Mosfet switch delay",
                initialValue: Data.param_del_fet_ctrl_sw,
                onChange: (v) =>
                    widget.registerWrites[Data.DEL_FET_CTRL_SW] = v),
            OneInputField(
                text: "LED delay",
                initialValue: Data.param_del_led,
                onChange: (v) => widget.registerWrites[Data.DEL_LED] = v)
          ]),
      4: SettingsSection(
          key: UniqueKey(),
          title: "Protection",
          settingsElements: [
            ThreeInputField(
                text: "Charging Over temp",
                firstInitialValue: Data.param_prot_c_high_temp_trig,
                secondInitialValue: Data.param_prot_c_high_temp_rel,
                thirdInitialValue: Data.param_del_high_ch_temp,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_C_HIGH_TEMP_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_C_HIGH_TEMP_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_CH_TEMP] = v,
                firstHeader: "Trigger",
                secondHeader: "Release",
                thirdHeader: "Delay"),
            ThreeInputField(
                pair: true,
                text: "Charging under temp",
                firstInitialValue: Data.param_prot_c_low_temp_trig,
                secondInitialValue: Data.param_prot_c_low_temp_rel,
                thirdInitialValue: Data.param_del_low_ch_temp,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_C_LOW_TEMP_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_C_LOW_TEMP_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_CH_TEMP] = v),
            ThreeInputField(
                text: "Discharging Over temp",
                firstInitialValue: Data.param_prot_d_high_temp_trig,
                secondInitialValue: Data.param_prot_d_high_temp_rel,
                thirdInitialValue: Data.param_del_high_d_temp,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_D_HIGH_TEMP_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_D_HIGH_TEMP_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_D_TEMP] = v),
            ThreeInputField(
                pair: true,
                text: "Discharging under temp",
                firstInitialValue: Data.param_prot_d_low_temp_trig,
                secondInitialValue: Data.param_prot_d_low_temp_rel,
                thirdInitialValue: Data.param_del_low_d_temp,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_D_LOW_TEMP_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_D_LOW_TEMP_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_D_TEMP] = v),
            ThreeInputField(
                text: "Battery Over Voltage",
                firstInitialValue: Data.param_prot_bat_high_trig,
                secondInitialValue: Data.param_prot_bat_high_rel,
                thirdInitialValue: Data.param_del_high_bat_v,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_BAT_HIGH_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_BAT_HIGH_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_BAT_V] = v),
            ThreeInputField(
                pair: true,
                text: "Battery Under Voltage",
                firstInitialValue: Data.param_prot_bat_low_trig,
                secondInitialValue: Data.param_prot_bat_low_rel,
                thirdInitialValue: Data.param_del_low_bat_v,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_BAT_LOW_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_BAT_LOW_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_BAT_V] = v),
            ThreeInputField(
                text: "Cell Over Voltage",
                firstInitialValue: Data.param_prot_cell_high_trig,
                secondInitialValue: Data.param_prot_cell_high_rel,
                thirdInitialValue: Data.param_del_high_cell_v,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_CELL_HIGH_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_CELL_HIGH_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_CELL_V] = v),
            ThreeInputField(
                pair: true,
                text: "Cell Under Voltage",
                firstInitialValue: Data.param_prot_cell_low_trig,
                secondInitialValue: Data.param_prot_cell_low_rel,
                thirdInitialValue: Data.param_del_low_cell_v,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_CELL_LOW_TRIG] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.PROT_CELL_LOW_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_CELL_V] = v),
            ThreeInputField(
                text: "Charge Over Current",
                firstHeader: "Trigger\n",
                secondHeader: "Release\ndelay",
                thirdHeader: "Trigger\ndelay",
                firstInitialValue: Data.param_prot_ch_high_ma,
                secondInitialValue: Data.param_del_high_ma_rel,
                thirdInitialValue: Data.param_del_high_ma,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_CH_HIGH_MA] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_MA_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_HIGH_MA] = v),
            ThreeInputField(
                pair: true,
                text: "Discharge Over Current",
                firstInitialValue: Data.param_prot_d_high_ma,
                secondInitialValue: Data.param_del_low_ma_rel,
                thirdInitialValue: Data.param_del_low_ma,
                firstOnChange: (v) =>
                    widget.registerWrites[Data.PROT_D_HIGH_MA] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_MA_REL] = v,
                thirdOnChange: (v) =>
                    widget.registerWrites[Data.DEL_LOW_MA] = v),
          ]),
      5: SettingsSection(
          key: UniqueKey(),
          title: "Advanced Protection",
          settingsElements: [
            TwoInputField(
              text: "OverVoltage II",
              firstOnChange: (v) =>
                  widget.registerWrites[Data.CELL_FULL_MV] = v,
              secondOnChange: (v) =>
                  widget.registerWrites[Data.CELL_FULL_MV] = v,
              firstHeader: "Trigger",
              secondHeader: "Delay",
            ),
            TwoInputField(
                text: "Undervoltage II",
                firstOnChange: (v) =>
                    widget.registerWrites[Data.CELL_FULL_MV] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.CELL_FULL_MV] = v),
            TwoInputField(
                text: "Overcurrent II",
                firstOnChange: (v) =>
                    widget.registerWrites[Data.CELL_FULL_MV] = v,
                secondOnChange: (v) =>
                    widget.registerWrites[Data.CELL_FULL_MV] = v)
          ]),
    };
    tiles.clear();
    for (var i = 0; i < widget.tiles.length; i++) {
      tiles.add(tilesMap[widget.tiles[i]]!);
    }
    return Stack(
      children: [
        Container(
            height: MediaQuery.sizeOf(context).height,
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.black, Color(0xFF002A4D)])),
            child: ReorderableListView(
                onReorder: reorder,
                proxyDecorator: proxyDecorator,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 180, top: 80),
                children: tiles)),
        if (!Data.availableData)
          Positioned(
              top: 40,
              right: 10,
              child: DelayedBuilder(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF003F73),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black,
                                blurRadius: 5,
                                offset: Offset(4, 4))
                          ]),
                      child: const Row(children: [
                        Text("Getting Data",
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        SizedBox(width: 10),
                        CircularProgressIndicator.adaptive(
                            strokeWidth: 6, backgroundColor: Color(0xFF002A4D))
                      ]))))
      ],
    );
  }
}
