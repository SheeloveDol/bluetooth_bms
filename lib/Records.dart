import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'src.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});
  @override
  State<StatefulWidget> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  PageController controller = PageController();
  bool bg = false;
  Column first() {
    List<Widget> data = [];
    data.addAll([
      Text("Manufacturer: ${Data.mfg_name}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      const Padding(padding: EdgeInsets.only(bottom: 10)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Battery Overvoltage Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.povp_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Battery Undervoltage Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.puvp_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Charging Over-Temp Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.chgot_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Charging Under-Temp Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.chgut_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Discharging Over-Temp Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.dsgot_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Discharging Under-Temp Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.dsgut_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ])
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: data);
  }

  Column second() {
    List<Widget> data = [];
    data.addAll([
      Text("Device Name: ${Data.device_name}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      const Padding(padding: EdgeInsets.only(bottom: 10)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Short Circuit Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.sc_err_cnt}", style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Charging Overcurrent Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.chgoc_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Discharging Overcurrent Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.dsgoc_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Cell Overvoltage Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.covp_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Cell Undervoltage Times :",
            style: TextStyle(color: Colors.white)),
        Text("${Data.cuvp_err_cnt}",
            style: const TextStyle(color: Colors.white))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Unknown Error :", style: TextStyle(color: Colors.white)),
        Text("${Data.unknown}", style: const TextStyle(color: Colors.white))
      ])
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: data);
  }

  Column third() {
    List<Widget> data = [];
    data.addAll([
      Text("MFG Date: ${Data.date}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      const Padding(padding: EdgeInsets.only(bottom: 10)),
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        const Text("Cycle Count : ", style: TextStyle(color: Colors.white)),
        Text(Data.cycle_cnt, style: const TextStyle(color: Colors.white))
      ]),
      Image.asset("assets/logo.png", height: 100)
    ]);
    return Column(children: data);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0x2EFFFFFF)),
        child: Stack(children: [
          Align(
              alignment: Alignment.topLeft,
              child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  child: PageView(
                      controller: controller,
                      children: [first(), second(), third()]))),
          Positioned(
              top: 10,
              right: 20,
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (controller.page == 2) {
                      controller.animateTo(0,
                          curve: Easing.standard,
                          duration: Durations.extralong1);
                    } else {
                      controller.nextPage(
                          duration: Durations.extralong1,
                          curve: Easing.standard);
                    }
                  },
                  child: const Row(children: [
                    Text("Next",
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white)
                  ])))
        ]));
  }
}
