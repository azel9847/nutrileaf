import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/scan_result.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'scan_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

/// Persistent shell that hosts the bottom navigation bar and all main tab screens.
///
/// Uses [IndexedStack] to preserve the state of each tab when switching,
/// preventing unnecessary rebuilds and data reloads. All five screens remain
/// alive in memory so switching is instant and state is never lost.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Keep GlobalKeys for screens to trigger internal methods and refresh state
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();
  final GlobalKey<ScanScreenState> _scanKey = GlobalKey<ScanScreenState>();

  late final List<Widget> _screens;

  // Fade animation for tab transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      HistoryScreen(key: _historyKey),
      ScanScreen(key: _scanKey),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: 1.0, // Start fully visible
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Switch the active bottom tab with a smooth fade animation, optionally
  /// passing a crop filter for the History screen, or triggering a gallery image upload.
  void switchTab(int index, {CropType? initialCropFilter, bool triggerUpload = false}) {
    // If tapping the same tab
    if (index == _currentIndex) {
      if (index == 1 && initialCropFilter != null) {
        _historyKey.currentState?.setCropFilter(initialCropFilter);
      }
      return;
    }

    // Quick fade out → switch → fade in
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
      });

      // Invoke tab-specific setups or refreshes
      if (index == 0) {
        _homeKey.currentState?.refreshData();
      } else if (index == 1) {
        _historyKey.currentState?.refreshData();
        if (initialCropFilter != null) {
          _historyKey.currentState?.setCropFilter(initialCropFilter);
        }
      } else if (index == 2 && triggerUpload) {
        _scanKey.currentState?.pickImage();
      }

      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: switchTab,
      ),
    );
  }
}
