import 'package:flutter/material.dart';

class DelayedBuilder extends StatefulWidget {
  Duration? duration;
  Duration? opacityDuration;
  Widget child;
  Function()? onEnd;

  DelayedBuilder(
      {super.key,
      this.duration,
      this.opacityDuration,
      this.onEnd,
      required this.child});
  @override
  State<StatefulWidget> createState() => _DelayedBuilderState();
}

class _DelayedBuilderState extends State<DelayedBuilder> {
  double opacity = 0;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: Future.delayed(
            (widget.duration == null)
                ? const Duration(seconds: 1)
                : widget.duration!,
            (() => true)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (widget.onEnd != null) widget.onEnd!();
            opacity = 1;
          }
          return AnimatedOpacity(
            duration: (widget.opacityDuration == null)
                ? Duration.zero
                : widget.opacityDuration!,
            opacity: opacity,
            child: widget.child,
          );
        });
  }
}
