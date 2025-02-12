import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:flutter/material.dart';

class LoadingBadge extends StatelessWidget {
  const LoadingBadge({super.key});

  String getMessage() {
    return Be.currentMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 40,
        right: 10,
        child: DelayedBuilder(
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF003F73),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 5, offset: Offset(4, 4))]),
                child: Row(children: [
                  Text(getMessage(), style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(width: 10),
                  const CircularProgressIndicator.adaptive(strokeWidth: 6, backgroundColor: Color(0xFF002A4D))
                ]))));
  }
}
