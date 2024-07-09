import 'package:bluetooth_bms/settings/OneInputField.dart';
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
                              OneInputField(
                                  text: "Number of Cells", onChange: (v) {}),
                              OneInputField(
                                  text: "Number of Cells", onChange: (v) {}),
                              OneInputField(
                                  text: "Number of Cells", onChange: (v) {}),
                            ]),
                        TuningSection(
                            title: "Modify Cell Amperage",
                            settingsElements: []),
                        TuningSection(
                            title: "Modify Temperature Sensor",
                            settingsElements: []),
                      ])),
              StatefulBuilder(
                builder: (BuildContext context, setThisState) {
                  setSpecificState = () => setThisState(() {});
                  return GroupButton(
                      index: index,
                      onChanged: (int i) {
                        _controller.animateToPage(i,
                            duration: Durations.long4, curve: Easing.standard);
                      });
                },
              ),
            ])));
  }
}
