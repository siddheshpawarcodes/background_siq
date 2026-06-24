import 'package:flutter/material.dart';

import 'nav_log.dart';

/// Reusable back-navigation guard. Wraps [PopScope] and centralizes the
/// investigation logging plus the confirm-then-pop dance, so individual
/// screens don't reimplement it (App-Wide Navigation Safety).
///
/// When [canPop] is true a back press pops immediately (logged as
/// `ROUTE_POPPED`). When false the back press is intercepted: [onConfirmLeave]
/// is awaited — typically showing a dialog — and returning true pops the route
/// while false keeps the user in place. The guard performs the pop itself via
/// the enclosing [Navigator], mirroring the proven pattern in
/// `profile_wizard_screen.dart`.
///
/// It intercepts every back affordance Flutter routes through [PopScope]: the
/// Android system/gesture back and the AppBar back button.
class NavigationGuard extends StatelessWidget {
  const NavigationGuard({
    super.key,
    required this.canPop,
    required this.onConfirmLeave,
    required this.child,
    this.debugLabel = '',
  });

  /// When true, a back press is allowed through without prompting.
  final bool canPop;

  /// Invoked when a blocked back press is intercepted. Return true to leave
  /// (the guard pops), false to stay. May perform side effects first (e.g.
  /// request cancellation, discard a draft).
  final Future<bool> Function() onConfirmLeave;

  /// Short label used to disambiguate this screen's events in the logs.
  final String debugLabel;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        NavLog.event(NavEvent.backButtonPressed, debugLabel);
        if (didPop) {
          NavLog.event(NavEvent.routePopped, debugLabel);
          return;
        }
        NavLog.event(NavEvent.navigationGuardTriggered, debugLabel);
        final leave = await onConfirmLeave();
        if (leave) {
          NavLog.event(NavEvent.userChoseLeave, debugLabel);
          if (context.mounted) Navigator.of(context).pop();
        } else {
          NavLog.event(NavEvent.userChoseStay, debugLabel);
        }
      },
      child: child,
    );
  }
}
