import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_log.dart';
import 'processing_status.dart';

/// Observes [WidgetsBinding] lifecycle transitions and logs them so a bug
/// report can tell "killed by the OS" apart from "user navigated away"
/// (Crash vs Navigation Investigation). When the app is backgrounded mid-run it
/// also notes that a foreground service should be keeping work alive.
///
/// Wrap the app with this once, near the root.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        NavLog.event(NavEvent.appMovedToBackground, state.name);
        final engine = ref.read(processingStatusProvider);
        if (engine != null) {
          NavLog.event(NavEvent.foregroundServiceActive, engine.name);
        }
      case AppLifecycleState.resumed:
        NavLog.event(NavEvent.appResumed);
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
