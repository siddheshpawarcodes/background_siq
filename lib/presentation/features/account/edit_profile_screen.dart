import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/auth_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/auth_user.dart';
import '../../router/app_router.dart';
import '../../shared/user_avatar.dart';

/// Edit profile (SRS §11) — lets the signed-in user override their display
/// name and photo and add a phone number and company/role. Email comes from
/// Google and is shown read-only. All changes are stored locally.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _role;

  AuthUser? _user;
  String? _photoPath; // pending photo (null until changed)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).current;
    _user = user;
    _photoPath = user?.photoPath;
    _name = TextEditingController(text: user?.displayNameOverride ?? user?.googleDisplayName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _company = TextEditingController(text: user?.company ?? '');
    _role = TextEditingController(text: user?.role ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _role.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await ref.read(filePickServiceProvider).pickImagePath();
    if (path != null) setState(() => _photoPath = path);
  }

  void _removePhoto() => setState(() => _photoPath = null);

  Future<void> _save() async {
    final user = _user;
    if (user == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String? trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();
    // Only store a name override when it differs from the Google name.
    final typedName = _name.text.trim();
    final nameOverride =
        (typedName.isEmpty || typedName == (user.googleDisplayName ?? '')) ? null : typedName;

    final updated = user.copyWith(
      displayNameOverride: nameOverride,
      photoPath: _photoPath,
      phone: trimOrNull(_phone.text),
      company: trimOrNull(_company.text),
      role: trimOrNull(_role.text),
    );
    await ref.read(updateProfileUseCaseProvider).call(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    // Return to where we came from (Settings). Fall back to an explicit
    // navigation if this route can't be popped (e.g. opened via deep link).
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: const Center(child: Text('You need to sign in to edit your profile.')),
      );
    }

    // A live copy reflecting the pending photo, for the avatar preview.
    final preview = user.copyWith(photoPath: _photoPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Center(
              child: Column(
                children: [
                  UserAvatar(user: preview, radius: 48),
                  Spacing.sm.verticalSpace,
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('Change photo'),
                      ),
                      if (_photoPath != null)
                        TextButton.icon(
                          onPressed: _removePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Spacing.sm.verticalSpace,
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Display name cannot be empty' : null,
            ),
            Spacing.md.verticalSpace,
            TextFormField(
              initialValue: user.email,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (from Google)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            Spacing.md.verticalSpace,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            Spacing.md.verticalSpace,
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            Spacing.md.verticalSpace,
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Role / job title',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            Spacing.lg.verticalSpace,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
