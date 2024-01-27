import 'package:bluetooth_bms/BState.dart';
import 'package:bluetooth_bms/CState.dart';
import 'package:bluetooth_bms/Control.dart';
import 'package:bluetooth_bms/Records.dart';
import 'package:bluetooth_bms/TempData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth BMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController controller = ScrollController();
  double height = 0;
  @override
  void initState() {
    controller.addListener(() {
      if (controller.offset < 38) {
        setState(() {
          height = 0;
        });
      } else {
        setState(() {
          height = 105;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/bg.jpeg"), fit: BoxFit.cover)),
            child: Stack(children: [
              ListView(
                  padding: EdgeInsets.only(top: 230 - height),
                  physics: const ClampingScrollPhysics(),
                  controller: controller,
                  children: <Widget>[
                    BatteryState(),
                    CellsState(),
                    Temperatures(),
                    Reports()
                  ]),
              BatteryControl(height: height)
            ])));
  }
}
