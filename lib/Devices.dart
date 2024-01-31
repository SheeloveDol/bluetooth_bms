import 'dart:async';

import 'package:bluetooth_bms/Dashboard.dart';
import 'package:bluetooth_bms/main.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device extends StatefulWidget {
  Device({super.key, required this.title, required this.device});
  final BluetoothDevice device;
  final String title;
  @override
  State<StatefulWidget> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  onConnect(BuildContext context) {
    Be.connect(widget.device).then((value) {
      if (!value) {
        quicktell(context, "Could not connect to ${widget.title}");
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DashBoard(device: widget.device, title: widget.title)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3,
        margin: const EdgeInsets.all(5),
        child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.bluetooth),
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 17),
                  )
                ]),
                CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    borderRadius: BorderRadius.circular(15),
                    color: Color.fromARGB(255, 13, 22, 50),
                    child: const Text("Connect"),
                    onPressed: () => onConnect(context))
              ],
            )));
  }
}
