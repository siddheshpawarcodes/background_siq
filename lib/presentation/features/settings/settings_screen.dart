import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/auth_providers.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/entities/enums.dart';
import '../../router/app_router.dart';
import '../../shared/user_avatar.dart';

/// Settings — export folder/format, theme, auto-open, logging, cache, reset
/// (SRS §11.6). Persisted via the settings repository.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(WidgetRef ref, AppSettings next) =>
      ref.read(updateSettingsUseCaseProvider).call(next);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load settings: $e')),
        data: (s) => ListView(
          children: [
            _sectionHeader(context, 'Account'),
            ..._accountTiles(context, ref, user),
            const Divider(),
            _sectionHeader(context, 'Export'),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Default export folder'),
              subtitle: Text(s.defaultExportFolder ?? 'Same folder as source (when allowed)'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final dir = await ref.read(filePickServiceProvider).pickDirectory();
                if (dir != null) await _update(ref, s.copyWith(defaultExportFolder: dir));
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack_outlined),
              title: const Text('Default export format'),
              subtitle: Text(s.defaultExportFormat.label),
              trailing: DropdownButton<ExportFormat>(
                value: s.defaultExportFormat,
                underline: const SizedBox.shrink(),
                items: [
                  for (final f in ExportFormat.values)
                    DropdownMenuItem(value: f, child: Text(f.label)),
                ],
                onChanged: (f) {
                  if (f != null) _update(ref, s.copyWith(defaultExportFormat: f));
                },
              ),
            ),
            const Divider(),
            _sectionHeader(context, 'Appearance'),
            RadioGroup<ThemeMode>(
              groupValue: s.themeMode,
              onChanged: (mode) {
                if (mode != null) _update(ref, s.copyWith(themeMode: mode));
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(title: Text('System'), value: ThemeMode.system),
                  RadioListTile<ThemeMode>(title: Text('Light'), value: ThemeMode.light),
                  RadioListTile<ThemeMode>(title: Text('Dark'), value: ThemeMode.dark),
                ],
              ),
            ),
            const Divider(),
            _sectionHeader(context, 'General'),
            SwitchListTile(
              secondary: const Icon(Icons.open_in_new),
              title: const Text('Auto-open output folder'),
              subtitle: const Text('Reveal the file after export'),
              value: s.autoOpenOutputFolder,
              onChanged: (v) => _update(ref, s.copyWith(autoOpenOutputFolder: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined),
              title: const Text('Enable logging'),
              subtitle: const Text('Record diagnostics for troubleshooting'),
              value: s.loggingEnabled,
              onChanged: (v) => _update(ref, s.copyWith(loggingEnabled: v)),
            ),
            const Divider(),
            _sectionHeader(context, 'Storage'),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear cache'),
              subtitle: const Text('Remove temporary preview files'),
              onTap: () => _clearCache(context, ref),
            ),
            ListTile(
              leading: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
              title: Text('Reset app',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Restore defaults and clear all data'),
              onTap: () => _resetApp(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Account section — sign in when signed out; profile summary, edit, and
  /// sign out when signed in. Sign-in is optional (SRS §11).
  List<Widget> _accountTiles(BuildContext context, WidgetRef ref, AuthUser? user) {
    if (user == null) {
      return [
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('Sign in with Google'),
          subtitle: const Text('Personalise the app and manage your profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.login),
        ),
      ];
    }
    return [
      ListTile(
        leading: UserAvatar(user: user, radius: 22),
        title: Text(user.effectiveName),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => context.push(Routes.editProfile),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sign out'),
        onTap: () => _signOut(context, ref),
      ),
    ];
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your profile stays on this device and is restored '
            'when you sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(signOutUseCaseProvider).call();
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(maintenanceServiceProvider).clearCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $count cached preview file(s).')),
      );
    }
  }

  Future<void> _resetApp(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset app?'),
        content: const Text(
            'This clears all backdrops, settings, history, and recent files, then '
            'restores the built-in backdrops. Exported files are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if ((ok ?? false)) {
      await ref.read(maintenanceServiceProvider).resetApp();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App reset to defaults.')),
        );
      }
    }
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2,
              ),
        ),
      );
}
