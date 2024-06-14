import 'package:flutter/material.dart';

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
            child: widget.child,
          );
        });
  }
}

quicktell(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
