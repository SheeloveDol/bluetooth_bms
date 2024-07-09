import 'package:bluetooth_bms/settings/OneInputField.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/tuning/GroupButton.dart';
import 'package:bluetooth_bms/tuning/TuningSection.dart';
import 'package:flutter/material.dart';

class TuningPage extends StatefulWidget {
  const TuningPage({super.key});

  @override
  State<TuningPage> createState() => _TuningPageStae();
}

class _TuningPageStae extends State<TuningPage> {
  final PageController _controller = PageController();
  Function? setSpecificState;
  int index = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OneInputField cellmV(String title, int index) {
    Color color = Colors.black;
    Color titleColor = Colors.black;
    FontWeight weight = FontWeight.normal;
    FontWeight titleWeight = FontWeight.normal;
    if (Data.bal[index]) {
      titleColor = Colors.blue;
      titleWeight = FontWeight.bold;
    }
    if (Data.cell_mv[index] > Data.bal_start) {
      color = Color(0xFFCA5100);
      weight = FontWeight.bold;
    }
    if (Data.cell_mv[index] < Data.bal_start) {
      color = Colors.yellow;
      weight = FontWeight.bold;
    }
    return OneInputField(
        text: title,
        initialValue: "${Data.cell_mv[index].toStringAsFixed(3)}",
        onChange: (v) {});
  }

  OneInputField cellmA(String title, int index) {
    Color color = Colors.black;
    Color titleColor = Colors.black;
    FontWeight weight = FontWeight.normal;
    FontWeight titleWeight = FontWeight.normal;
    if (Data.bal[index]) {
      titleColor = Colors.blue;
      titleWeight = FontWeight.bold;
    }
    if (Data.cell_mv[index] > Data.bal_start) {
      color = Color(0xFFCA5100);
      weight = FontWeight.bold;
    }
    if (Data.cell_mv[index] < Data.bal_start) {
      color = Colors.yellow;
      weight = FontWeight.bold;
    }
    return OneInputField(
        text: title, initialValue: "cell ma $index", onChange: (v) {});
  }

  OneInputField temp(String title, int index) {
    return OneInputField(
        text: title, initialValue: Data.ntc_temp[index], onChange: (v) {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
            padding: EdgeInsets.only(top: 70),
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
            child: Column(children: [
              Container(
                  height: 5 * MediaQuery.sizeOf(context).height / 9,
                  child: PageView(
                      key: UniqueKey(),
                      onPageChanged: (value) {
                        index = value;
                        setSpecificState!();
                      },
                      controller: _controller,
                      children: [
                        TuningSection(
                            title: "Modify Cell Voltage",
                            settingsElements: [
                              for (int i = 0; i < Data.cell_cnt; i++)
                                cellmV("cell${i + 1}", i)
                            ]),
                        TuningSection(
                            title: "Modify Cell Amperage",
                            settingsElements: [
                              for (int i = 0; i < Data.cell_cnt; i++)
                                cellmA("cell${i + 1}", i)
                            ]),
                        TuningSection(
                            title: "Modify Temperature Sensor",
                            settingsElements: [
                              for (int i = 0; i < Data.ntc_cnt; i++)
                                cellmV("T${i + 1}", i)
                            ])
                      ])),
              StatefulBuilder(builder: (BuildContext context, setThisState) {
                setSpecificState = () => setThisState(() {});
                return GroupButton(
                    index: index,
                    onChanged: (int i) {
                      _controller.animateToPage(i,
                          duration: Durations.long4, curve: Easing.standard);
                    });
              })
            ])));
  }
}
