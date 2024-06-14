import 'package:bluetooth_bms/dashboard/Dashboard.dart';
import 'package:bluetooth_bms/dashboard/Devices.dart';
import 'package:bluetooth_bms/dashboard/Scan.dart';
import 'package:bluetooth_bms/settings/settingsPage.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/tuning/TuningPage.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(MaterialApp(home: Main()));
}

class Main extends StatefulWidget {
  Main({super.key});
  @override
  State<Main> createState() => _MainState();
}

enum _SelectedTab { scan, dashboard, settings, tune }

class _MainState extends State<Main> {
  PageController _controller = PageController();
  var _selectedTab = _SelectedTab.scan;
  double sScreen = 0;

  void _handleIndexChanged(int i) {
    setState(() {
      _selectedTab = _SelectedTab.values[i];
    });
    switch (_selectedTab) {
      case _SelectedTab.scan:
        try {
          Data.setAvailableData(false);
          Be.disconnect(totaly: true).then((value) {
            if (Be.savedDevice != null) {
              quicktell(context, "Disconnected from ${Be.title}");
            }
          });
          Data.clear();
        } catch (e) {
          print("failed to properly disconnect");
        }
        _controller.animateToPage(0,
            duration: Durations.medium1, curve: Curves.linear);
        break;
      case _SelectedTab.dashboard:
        _controller.animateToPage(1,
            duration: Durations.medium1, curve: Curves.linear);
        break;
      case _SelectedTab.settings:
        _controller.animateToPage(2,
            duration: Durations.medium1, curve: Curves.linear);
        break;
      case _SelectedTab.tune:
        _controller.animateToPage(3,
            duration: Durations.medium1, curve: Curves.linear);
        break;
    }
  }

  void gotoDashboard() {
    setState(() {
      _selectedTab = _SelectedTab.dashboard;
    });
    _controller.animateToPage(1,
        duration: Durations.medium1, curve: Curves.linear);
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      systemNavigationBarColor: Colors.transparent, // Navigation bar color
    ));
    Be.setCurrentContext(context);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    sScreen = MediaQuery.sizeOf(context).width;
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            bottom: false,
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: _controller,
              children: [
                ScanPage(gotoDashboard: gotoDashboard),
                DashBoard(),
                SettingsPage(),
                TuningPage(),
              ],
            )),
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: DotNavigationBar(
            marginR: const EdgeInsets.symmetric(horizontal: 10),
            paddingR: EdgeInsets.zero,
            itemPadding:
                EdgeInsets.symmetric(horizontal: sScreen / 30, vertical: 7),
            currentIndex: _SelectedTab.values.indexOf(_selectedTab),
            unselectedItemColor: Colors.grey[300],
            enablePaddingAnimation: false,
            dotIndicatorColor: Colors.transparent,
            onTap: _handleIndexChanged,
            items: [
              /// ScanPage
              DotNavigationBarItem(
                icon: Icon(
                  Icons.bluetooth_rounded,
                  size: sScreen / 10,
                ),
                selectedColor: const Color(0xFF002A4D),
              ),

              /// Dashboard
              DotNavigationBarItem(
                icon: Icon(
                  Icons.dashboard_rounded,
                  size: sScreen / 10,
                ),
                selectedColor: const Color(0xFF002A4D),
              ),

              /// Settings
              DotNavigationBarItem(
                icon: Icon(
                  Icons.settings,
                  size: sScreen / 10,
                ),
                selectedColor: const Color(0xFF002A4D),
              ),

              /// Tune
              DotNavigationBarItem(
                icon: Icon(
                  Icons.settings_input_composite_rounded,
                  size: sScreen / 10,
                ),
                selectedColor: const Color(0xFF002A4D),
              )
            ],
          ),
        ));
  }
}
