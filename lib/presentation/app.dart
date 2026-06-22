import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/di/app_providers.dart';
import '../core/di/repository_providers.dart';
import '../core/logging/app_logger.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Root application widget (SRS §9, §12).
class EchoBugApp extends ConsumerWidget {
  const EchoBugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Reflect the persisted "Enable logging" preference at runtime.
    ref.listen(settingsStreamProvider, (_, next) {
      final enabled = next.valueOrNull?.loggingEnabled;
      if (enabled != null) AppLogger.setVerbose(enabled);
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
