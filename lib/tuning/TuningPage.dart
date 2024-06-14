import 'package:flutter/material.dart';

class TuningPage extends StatelessWidget {
  const TuningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF002A4D), Colors.black])),
    );
  }
}
