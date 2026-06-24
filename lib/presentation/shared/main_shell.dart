import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'navigation/nav_log.dart';
import 'processing_banner.dart';

/// Bottom-navigation scaffold hosting the five top-level destinations
/// (Home, Record, Profiles, History, Settings) — SRS §12. Mobile-only layout.
/// Destination order must mirror the branch order in [appRouter].
///
/// Owns root-level back handling: a back press on a non-Home tab returns to
/// Home first, and a back press on Home arms a 2-second "press again to exit"
/// window (App-Wide Navigation Safety → Double Back To Exit). Pushed routes sit
/// above this shell with their own guards, so this only fires when a tab is the
/// topmost route.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Time since the exit window was armed; back exits only if pressed twice
  /// within [_exitWindow].
  final Stopwatch _backWindow = Stopwatch();
  bool _exitArmed = false;

  static const _exitWindow = Duration(seconds: 2);

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.mic_none_outlined), selectedIcon: Icon(Icons.mic), label: 'Record'),
    NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Backdrops'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  void _handleBack() {
    final shell = widget.navigationShell;

    // Not on Home → return to Home first (standard bottom-nav back behavior).
    if (shell.currentIndex != 0) {
      NavLog.event(NavEvent.backButtonPressed, 'shell/tab-${shell.currentIndex}');
      shell.goBranch(0);
      _disarm();
      return;
    }

    NavLog.event(NavEvent.backButtonPressed, 'shell/home');
    if (_exitArmed && _backWindow.elapsed < _exitWindow) {
      NavLog.event(NavEvent.appExitRequested);
      SystemNavigator.pop(); // Android exits; no-op on iOS.
      return;
    }

    _exitArmed = true;
    _backWindow
      ..reset()
      ..start();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Press back again to exit'),
        duration: _exitWindow,
      ),
    );
  }

  void _disarm() {
    _exitArmed = false;
    _backWindow.stop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // We always handle back ourselves at the shell level.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: Column(
          children: [
            const ProcessingBanner(),
            Expanded(child: widget.navigationShell),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          destinations: _destinations,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
