import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/auth_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_theme.dart';

/// Sign-in / sign-up screen — Google only (SRS §11). With Google there is no
/// separate "create account" step: the first sign-in registers the user, later
/// sign-ins log them back in. Sign-in is optional, so this screen is reached
/// from Settings and simply pops on success.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final result = await ref.read(signInWithGoogleUseCaseProvider).call();
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${user.email}')),
        );
        if (context.canPop()) context.pop();
      },
      (failure) {
        // A cancelled picker is a no-op — don't nag the user.
        if (failure is SignInCancelledFailure) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 40,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.graphic_eq, size: 40, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Sign in to ${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Sign in with Google to personalise the app and manage your '
                'profile. Your details stay on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              _GoogleButton(busy: _busy, onPressed: _busy ? null : _signIn),
              const SizedBox(height: Spacing.md),
              Text(
                'New here? Signing in with Google also creates your account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: Spacing.lg),
              _DemoNotice(scheme: scheme, textTheme: theme.textTheme),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login),
      label: Text(busy ? 'Signing in…' : 'Continue with Google'),
    );
  }
}

/// Visible only while the stub provider is wired — makes the demo behaviour
/// obvious. Remove once real Google sign-in is configured.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.scheme, required this.textTheme});

  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Demo sign-in: a sample Google account is used. Add OAuth client '
              'ids to enable real Google sign-in (no backend needed).',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
