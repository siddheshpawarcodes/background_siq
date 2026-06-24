import 'package:flutter/material.dart';

/// What the user chose in a "processing is running" back-press dialog.
enum LeaveAction {
  /// Leave the screen but keep the job running in the background.
  background,

  /// Cancel the job (the engine stops gracefully).
  cancel,

  /// Remain on the current screen.
  stay,
}

/// "Leave Setup?" confirmation — shown when the user backs out of a setup
/// screen that still holds unsaved configuration. Returns true to leave
/// (discard), false to stay. Styled to match the app's other confirmations
/// (see `profile_wizard_screen.dart`).
Future<bool> confirmLeaveSetup(
  BuildContext context, {
  String title = 'Leave Dataset Setup?',
  String message = 'You have unsaved dataset configuration.',
}) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Stay'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// "Processing Running" dialog — shown when the user backs out while a job is
/// active. With [canBackground] true the full three-button dialog is shown (the
/// job can keep running detached, surviving via the foreground service);
/// otherwise only Cancel / Stay are offered so we never promise a background
/// mode that isn't real. Returns [LeaveAction.stay] if dismissed.
Future<LeaveAction> showProcessingRunningDialog(
  BuildContext context, {
  required bool canBackground,
  String title = 'Audio Processing Running',
  String message = 'Processing is still in progress.\n'
      'What would you like to do?',
}) async {
  final action = await showDialog<LeaveAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (canBackground)
          TextButton(
            onPressed: () => Navigator.of(context).pop(LeaveAction.background),
            child: const Text('Keep Processing In Background'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(LeaveAction.cancel),
          child: const Text('Cancel Processing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(LeaveAction.stay),
          child: const Text('Stay Here'),
        ),
      ],
    ),
  );
  return action ?? LeaveAction.stay;
}

/// Shown when the user tries to start a job while another processing engine is
/// already active (Processing-Aware Navigation).
void showAlreadyRunningMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'A processing task is already running.\n'
        'Please wait for it to complete or cancel it first.',
      ),
    ),
  );
}
