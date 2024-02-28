import 'dart:async';

import 'package:bluetooth_bms/Dashboard.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device extends StatefulWidget {
  Device({
    super.key,
    required this.title,
    required this.device,
    required this.scafoldContextKey,
  });
  final BluetoothDevice device;
  final String title;
  final GlobalKey scafoldContextKey;
  @override
  State<StatefulWidget> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  bool connecting = false;

  onConnect(BuildContext context) async {
    connecting = true;
    await Be.stopScan();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 600)).then((value) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DashBoard(device: widget.device, title: widget.title)));
    });
  }

  @override
  void initState() {
    connecting = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3,
        margin: const EdgeInsets.all(5),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.bluetooth),
                  Text(
                    widget.title,
                    style: TextStyle(
                        fontSize: (widget.title.length < 20) ? 17 : 12),
                  )
                ]),
                CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    borderRadius: BorderRadius.circular(15),
                    color: Color.fromARGB(255, 13, 22, 50),
                    onPressed: (connecting) ? null : () => onConnect(context),
                    child: Text((connecting) ? "Connecting" : "Connect"))
              ],
            )));
  }
}
