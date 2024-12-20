import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class DelayedBuilder extends StatefulWidget {
  Duration? duration;
  Duration? opacityDuration;
  int? index = 0;
  Widget child;
  Function()? onEnd;

  DelayedBuilder(
      {super.key,
      this.duration,
      this.opacityDuration,
      this.index,
      this.onEnd,
      required this.child});
  @override
  State<StatefulWidget> createState() => _DelayedBuilderState();
}

class _DelayedBuilderState extends State<DelayedBuilder> {
  @override
  void initState() {
    super.initState();
  }

  double opacity = 0;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: Future.delayed(
            (widget.duration == null) ? Durations.short4 : widget.duration!,
            (() => true)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (widget.onEnd != null) widget.onEnd!();
            opacity = 1;
          }
          return AnimatedOpacity(
              duration: (widget.opacityDuration == null)
                  ? Durations.long1
                  : widget.opacityDuration!,
              opacity: opacity,
              child: widget.child);
        });
  }
}

void showDialogAdaptive(
  BuildContext context, {
  required Text title,
  required Text content,
  required List<Widget> actions,
}) {
  Platform.isIOS
      ? showCupertinoDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) => CupertinoAlertDialog(
              title: title, content: content, actions: actions))
      : showDialog(
          context: context,
          builder: (BuildContext context) =>
              AlertDialog(title: title, content: content, actions: actions));
}

void quicktell(BuildContext? context, String message) {
  if (context == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
