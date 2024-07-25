import 'package:bluetooth_bms/src.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LockButton extends StatefulWidget {
  bool visible;
  LockButton({
    super.key,
    required this.visible,
  });

  @override
  State<LockButton> createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton> {
  Icon icon = const Icon(Icons.lock);
  bool visi = true;
  TextStyle textStyle = const TextStyle(color: Color(0xFF002A4D));
  @override
  Widget build(BuildContext context) {
    icon = (Be.locked)
        ? Icon(
            Icons.lock,
            size: 40,
            color: Colors.grey[300],
          )
        : const Icon(
            Icons.lock_open,
            size: 40,
            color: Colors.amber,
          );

    return Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.only(left: 40),
        width: 320,
        child: AnimatedOpacity(
            duration: Durations.long1,
            opacity: (widget.visible) ? 1.0 : 0,
            onEnd: () {
              visi = widget.visible;
              setState(() {});
            },
            child: Visibility(
                visible: (widget.visible) ? true : visi,
                child: (Be.locked)
                    ? FloatingActionButton(
                        splashColor: Colors.transparent,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          if (!Be.warantyVoided) {
                            var result = showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog.adaptive(
                                    title: Text("Warranty Waiving Action"),
                                    icon: Icon(Icons.warning),
                                    content: const Column(children: [
                                      Divider(),
                                      Text(
                                          "By pushing and getting values directly to the battery you agree that this will void your waranty")
                                    ]),
                                    actions: [
                                      CupertinoButton(
                                          onPressed: () {
                                            Be.voidWaranty();
                                            Be.unLock();
                                            Navigator.pop(context, true);
                                          },
                                          child: Text("I Agree")),
                                      CupertinoButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("I Disagree"))
                                    ],
                                  );
                                });
                          } else {
                            Be.unLock();
                          }
                          setState(() {});
                        },
                        child: icon)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            FloatingActionButton.extended(
                                splashColor: Colors.transparent,
                                backgroundColor: Colors.white,
                                onPressed: () {},
                                label: Text("Push", style: textStyle),
                                icon: const Icon(Icons.upload_rounded,
                                    color: const Color(0xFF002A4D))),
                            FloatingActionButton.extended(
                                splashColor: Colors.transparent,
                                backgroundColor: Colors.white,
                                onPressed: () {},
                                label: Text("Get", style: textStyle),
                                icon: const Icon(Icons.download_rounded,
                                    color: const Color(0xFF002A4D))),
                            FloatingActionButton(
                                splashColor: Colors.transparent,
                                backgroundColor: Colors.white,
                                onPressed: () => setState(() => Be.lock()),
                                child: icon)
                          ]))));
  }
}
