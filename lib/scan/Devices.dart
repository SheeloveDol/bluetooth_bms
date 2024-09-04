import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device extends StatefulWidget {
  Device({
    super.key,
    required this.title,
    required this.device,
    required this.goToDashboard,
  });
  final Function goToDashboard;
  final BluetoothDevice device;
  final String title;
  @override
  State<StatefulWidget> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  bool connecting = false;
  String textValue = "Connect";

  onConnect() {
    connecting = true;
    textValue = "Connecting";
    Be.stopScan().then((v) {
      if (this.mounted) setState(() {});
    });
    Future.delayed(Durations.medium2, () {
      Be.title = widget.title;
      Be.setDeviceTitle(widget.title);
      Be.setConnectionState(DeviceConnectionState.connecting);
      widget.goToDashboard();
      Be.connect(widget.device);
    });
  }

  @override
  void initState() {
    connecting = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.sizeOf(context).width;
    return GestureDetector(
        onLongPress: () => onConnect(),
        child: Card(
            elevation: 3,
            margin: const EdgeInsets.all(5),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.bluetooth),
                      Container(
                          width: size - 210,
                          child: Text(widget.title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15)))
                    ]),
                    CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        borderRadius: BorderRadius.circular(15),
                        color: Color.fromARGB(255, 13, 22, 50),
                        onPressed: (connecting) ? null : () => onConnect(),
                        child: Text(textValue))
                  ],
                ))));
  }
}
