import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/batch/batch_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/processing/processing_screen.dart';
import '../features/profile_wizard/profile_wizard_screen.dart';
import '../features/profiles/profiles_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/main_shell.dart';

/// Route path constants (SRS §12).
abstract class Routes {
  static const home = '/';
  static const profiles = '/profiles';
  static const history = '/history';
  static const settings = '/settings';
  static const processing = '/processing'; // + /:jobId
  static const profileEdit = '/profiles/edit'; // + /:id (optional)
  static const batch = '/batch';
}

final _rootKey = GlobalKey<NavigatorState>();

/// Application router: a stateful bottom-nav shell for the four top-level
/// destinations, plus pushed routes for processing and the profile editor.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profiles,
              builder: (context, state) => const ProfilesScreen(),
              routes: [
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => ProfileWizardScreen(
                    profileId: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const ProfileWizardScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.history,
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.processing,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => ProcessingScreen(args: state.extra as ApplyArgs),
    ),
    GoRoute(
      path: Routes.batch,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const BatchScreen(),
    ),
  ],
);
