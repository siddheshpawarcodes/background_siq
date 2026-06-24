import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/edit_profile_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/batch/batch_screen.dart';
import '../features/dataset_batch/dataset_batch_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/player/player_screen.dart';
import '../features/processing/processing_screen.dart';
import '../features/record/record_screen.dart';
import '../features/profile_wizard/profile_wizard_screen.dart';
import '../features/profiles/profiles_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/main_shell.dart';

/// Route path constants (SRS §12).
abstract class Routes {
  static const splash = '/splash'; // animated launch screen
  static const home = '/';
  static const record = '/record';
  static const profiles = '/profiles';
  static const history = '/history';
  static const settings = '/settings';
  static const processing = '/processing'; // + /:jobId
  static const profileEdit = '/profiles/edit'; // + /:id (optional)
  static const batch = '/batch';
  static const datasetBatch = '/dataset-batch';
  static const player = '/player'; // music-player preview of finished files
  static const login = '/login'; // Google sign-in / sign-up
  static const editProfile = '/account/edit'; // user profile editor
}

final _rootKey = GlobalKey<NavigatorState>();

/// Application router: a stateful bottom-nav shell for the four top-level
/// destinations, plus pushed routes for processing and the profile editor.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const SplashScreen(),
    ),
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
              path: Routes.record,
              builder: (context, state) => const RecordScreen(),
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
      builder: (context, state) => const ProcessingScreen(),
    ),
    GoRoute(
      path: Routes.batch,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const BatchScreen(),
    ),
    GoRoute(
      path: Routes.datasetBatch,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const DatasetBatchScreen(),
    ),
    GoRoute(
      path: Routes.player,
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          PlayerScreen(initialTrackId: state.extra as String?),
    ),
    GoRoute(
      path: Routes.login,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.editProfile,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
);
