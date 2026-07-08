import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSignedIn)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSignInFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: Text(l10n.profileDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).deleteAccount();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileAccountDeleted)),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.code == 'requires-recent-login'
              ? l10n.profileReauthNeeded
              : l10n.profileDeleteFailed(e.message ?? '')),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileDeleteFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(localeControllerProvider);
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.languagePickerTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            RadioGroup<Locale>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(sheetContext, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final lang in supportedLanguages)
                    RadioListTile<Locale>(
                      value: lang.locale,
                      title: Text(lang.name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).value;
    final isGuest = ref.watch(isGuestProvider);
    final recipeCount = ref.watch(userRecipesProvider).value?.length ?? 0;
    final currentLocale = ref.watch(localeControllerProvider);
    final currentLanguageName = supportedLanguages
        .firstWhere((l) => l.locale == currentLocale,
            orElse: () => supportedLanguages.first)
        .name;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              backgroundImage: (user?.photoUrl != null)
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: (user?.photoUrl == null)
                  ? Text(
                      isGuest ? '🥐' : _initial(user?.name),
                      style: const TextStyle(fontSize: 34, color: Colors.white),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? l10n.profileGuestName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          if (user?.email != null)
            Center(
              child: Text(user!.email!,
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(l10n.profileRecipeCount(recipeCount),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 32),
          if (isGuest) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profileGuestCardTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.profileGuestCardBody,
                      style: const TextStyle(
                          color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _GoogleButton(onPressed: _busy ? null : _signInWithGoogle),
                  ],
                ),
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: Text(l10n.profileSignOut),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.textMuted),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(l10n.profileLanguage),
              subtitle: Text(currentLanguageName),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : _pickLanguage,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever, size: 20),
            label: Text(l10n.profileDeleteAccount),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    if (name == null || name.isEmpty) return '🥐';
    return name.characters.first.toUpperCase();
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.login, color: AppColors.primary),
        label: Text(AppLocalizations.of(context).profileSignInWithGoogle),
      ),
    );
  }
}
