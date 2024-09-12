import 'package:bluetooth_bms/dashboard/Dashboard.dart';
import 'package:bluetooth_bms/dashboard/lockButton.dart';
import 'package:bluetooth_bms/scan/Scan.dart';
import 'package:bluetooth_bms/settings/settingsPage.dart';
import 'package:bluetooth_bms/src.dart';
import 'package:bluetooth_bms/tuning/TuningPage.dart';
import 'package:bluetooth_bms/utils.dart';
import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  final List<int> settingTiles = [0, 1, 2, 3, 4];

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent, // Navigation bar color
  ));
  runApp(MaterialApp(
      theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002A4D))),
      home: Main(settingTiles: settingTiles)));
}

class Main extends StatefulWidget {
  const Main({super.key, required this.settingTiles});
  final List<int> settingTiles;
  @override
  State<Main> createState() => _MainState();
}

enum _SelectedTab { scan, dashboard, settings, tune }

class _MainState extends State<Main> {
  final PageController _controller = PageController();
  var _selectedTab = _SelectedTab.scan;
  double sScreen = 0;
  bool showbar = false;
  late List<Widget> pages;

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
        _controller.animateToPage(0, duration: Durations.long3, curve: Curves.ease);
        break;
      case _SelectedTab.dashboard:
        _controller.animateToPage(1, duration: Durations.long3, curve: Curves.ease);
        break;
      case _SelectedTab.settings:
        _controller.animateToPage(2, duration: Durations.long3, curve: Curves.ease);
        break;
      case _SelectedTab.tune:
        _controller.animateToPage(3, duration: Durations.long3, curve: Curves.ease);
        break;
    }
  }

  void gotoDashboard() {
    setState(() {
      _selectedTab = _SelectedTab.dashboard;
    });
    _controller.animateToPage(1, duration: Durations.long3, curve: Curves.ease);
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Be.setCurrentContext(context);
    Be.setUpdater(() => setState(() {}));
    pages = [ScanPage(gotoDashboard: gotoDashboard), DashBoard(), SettingsPage(tiles: widget.settingTiles), TuningPage()];
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    sScreen = MediaQuery.sizeOf(context).width;
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return GestureDetector(
        onTap: () {
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        },
        child: Scaffold(
            backgroundColor: Colors.black,
            body: Container(
                color: const Color(0xFF002A4D),
                child: PageView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _controller,
                    itemBuilder: (BuildContext context, int index) {
                      return pages[index];
                    })),
            extendBody: true,
            resizeToAvoidBottomInset: (_selectedTab == _SelectedTab.scan) ? false : true,
            floatingActionButton: LockButton(
                visible: (_selectedTab != _SelectedTab.scan && _selectedTab != _SelectedTab.dashboard && !keyboardIsOpen)),
            bottomNavigationBar: AnimatedOpacity(
              duration: Durations.long1,
              opacity: (_selectedTab == _SelectedTab.scan) ? 0 : 1,
              onEnd: () => (_selectedTab == _SelectedTab.scan)
                  ? setState(
                      () => showbar = false,
                    )
                  : setState(
                      () => showbar = true,
                    ),
              child: AnimatedContainer(
                  duration: Durations.long1,
                  color: Colors.white,
                  child: Visibility(
                      //visible: showbar,
                      child: DotNavigationBar(
                    enableFloatingNavBar: false,
                    marginR: const EdgeInsets.symmetric(horizontal: 10),
                    paddingR: EdgeInsets.zero,
                    itemPadding: EdgeInsets.symmetric(horizontal: sScreen / 30, vertical: 0),
                    currentIndex: _SelectedTab.values.indexOf(_selectedTab),
                    unselectedItemColor: Colors.grey[300],
                    splashColor: Colors.transparent,
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
                      // DotNavigationBarItem(
                      //   icon: Icon(
                      //     Icons.settings_input_composite_rounded,
                      //     size: sScreen / 10,
                      //   ),
                      //   selectedColor: const Color(0xFF002A4D),
                      // )
                    ],
                  ))),
            )));
  }
}
