import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// App-level Riverpod providers (SRS §9).
///
/// Theme mode is derived from the persisted settings; defaults to the system
/// theme while settings are loading or unset.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsStreamProvider).valueOrNull?.themeMode ?? ThemeMode.system;
});
