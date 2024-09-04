import 'package:flutter/material.dart';

class GroupButton extends StatefulWidget {
  GroupButton({super.key, required this.index, required this.onChanged});
  int index;
  final Function(int) onChanged;
  @override
  State<GroupButton> createState() => _GroupButtonState();
}

class _GroupButtonState extends State<GroupButton> {
  List<bool> selected = [true, false, false];

  @override
  Widget build(BuildContext context) {
    selected.setAll(0, [false, false, false]);
    selected[widget.index] = true;
    return Padding(
        padding: EdgeInsets.all(20),
        child: ToggleButtons(
            isSelected: selected,
            fillColor: Colors.white,
            selectedBorderColor: Colors.amber[50],
            borderColor: Colors.amber[50],
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.transparent,
            children: [
              VoltsTuning(selected: selected[0]),
              AmpsTuning(selected: selected[1]),
              TempTuning(selected: selected[2])
            ],
            onPressed: (index) => widget.onChanged(index)));
  }
}

class VoltsTuning extends StatelessWidget {
  const VoltsTuning({super.key, required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.electric_bolt_rounded, color: Colors.amber, size: 30),
          if (selected) Text("Volts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25))
        ]));
  }
}

class AmpsTuning extends StatelessWidget {
  const AmpsTuning({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.electric_bolt_rounded, color: Colors.blueAccent, size: 30),
          if (selected) Text("Amps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25))
        ]));
  }
}

class TempTuning extends StatelessWidget {
  const TempTuning({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.thermostat, color: Colors.greenAccent, size: 30),
          if (selected) Text("Temps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25))
        ]));
  }
}
