import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../services/consent_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() =>
      _signIn((auth) => auth.signInWithGoogle());

  Future<void> _signInWithApple() => _signIn((auth) => auth.signInWithApple());

  /// Explains what linking a guest account does, then runs [signIn].
  ///
  /// Shared by both providers so Sign in with Apple and Sign in with Google are
  /// equivalent options, as guideline 4.8 requires. A user backing out of the
  /// provider's own sheet is a normal outcome, not a failure, so cancellations
  /// pass silently instead of raising an error.
  Future<void> _signIn(Future<void> Function(AuthService auth) signIn) async {
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // The body runs to two paragraphs (longer still in German), which an
        // AlertDialog clips rather than scrolls on a short screen or at a large
        // text scale. `scrollable` puts title and content in a scroll view so
        // the whole explanation stays reachable.
        scrollable: true,
        title: Text(l10n.profileSignInInfoTitle),
        content: Text(l10n.profileSignInInfoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionContinue),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await signIn(ref.read(authServiceProvider));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSignedIn)),
        );
      }
    } catch (e) {
      if (mounted && !_isCancellation(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSignInFailed(_describe(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Whether [error] is the user dismissing a provider's sign-in sheet.
  ///
  /// Apple's `ASAuthorizationController` reports a dismissal as `canceled`, and
  /// as `not-handled` when the sheet is torn down before it can present (for
  /// example when the app is backgrounded mid-flow). Neither is a failure the
  /// user should be told about.
  bool _isCancellation(Object error) =>
      (error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled) ||
      (error is FirebaseAuthException &&
          (error.code == 'canceled' ||
              error.code == 'web-context-canceled' ||
              error.code == 'user-canceled' ||
              error.code == 'not-handled'));

  /// A readable one-line description of a sign-in failure.
  ///
  /// `FirebaseAuthException.toString()` renders as a bracketed plugin dump,
  /// which reads as a crash to anyone who sees it. The provider's own message
  /// is shown instead, with the code kept in parentheses so a report of the
  /// failure is still enough to identify it.
  String _describe(Object error) {
    if (error is FirebaseAuthException) {
      final message = error.message?.trim();
      return (message == null || message.isEmpty)
          ? error.code
          : '$message (${error.code})';
    }
    return error.toString();
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
        scrollable: true,
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

  Future<void> _editDisplayName() async {
    final l10n = AppLocalizations.of(context);
    final currentName = ref.read(currentAppUserProvider).value?.name ?? '';
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileEditNameTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileEditNameBody,
              style: const TextStyle(color: AppColors.textMuted, height: 1.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: l10n.profileDisplayNameLabel,
              ),
              onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == currentName || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).updateDisplayName(trimmed);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileNameUpdated)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.languagePickerTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Flexible(
              child: RadioGroup<Locale>(
                groupValue: current,
                onChanged: (v) => Navigator.pop(sheetContext, v),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final lang in supportedLanguages)
                      RadioListTile<Locale>(
                        value: lang.locale,
                        title: Text(lang.name),
                      ),
                  ],
                ),
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
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: (user?.photoUrl != null)
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: (user?.photoUrl == null)
                        ? Text(
                            isGuest ? '🥐' : _initial(user?.name),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Balances the edit button so the name stays centered.
                      const SizedBox(width: 40),
                      Flexible(
                        child: Text(
                          user?.name ?? l10n.profileGuestName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.textMuted,
                        tooltip: l10n.profileEditName,
                        onPressed: _busy ? null : _editDisplayName,
                      ),
                    ],
                  ),
                  if (user?.email != null)
                    Text(user!.email!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book,
                            size: 16, color: AppColors.primaryDeep),
                        const SizedBox(width: 6),
                        Text(
                          l10n.profileRecipeCount(recipeCount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.primaryDeep),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.profileGuestCardTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profileGuestCardBody,
                      style: const TextStyle(
                          color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Sign in with Apple sits first on Apple platforms, where
                    // guideline 4.8 requires it to be offered as an equivalent
                    // option to the third-party (Google) login.
                    if (AuthService.supportsAppleSignIn) ...[
                      _AppleButton(onPressed: _busy ? null : _signInWithApple),
                      const SizedBox(height: 10),
                    ],
                    _GoogleButton(onPressed: _busy ? null : _signInWithGoogle),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              l10n.profileSettings,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.profileLanguage),
                  subtitle: Text(currentLanguageName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _pickLanguage,
                ),
                // Google requires this entry point wherever the configured
                // consent message offers privacy options — and requires it to
                // be absent elsewhere, so it only appears when the SDK says so.
                // The value arrives once the consent flow resolves, hence the
                // builder.
                ValueListenableBuilder<bool>(
                  valueListenable:
                      ConsentService.instance.privacyOptionsRequired,
                  builder: (context, required, _) {
                    if (!required) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const Divider(indent: 56),
                        ListTile(
                          leading: const Icon(Icons.tune),
                          title: Text(l10n.profileAdPrivacy),
                          subtitle: Text(l10n.profileAdPrivacySubtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _busy
                              ? null
                              : ConsentService.instance.showPrivacyOptions,
                        ),
                      ],
                    );
                  },
                ),
                if (!isGuest) ...[
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.profileSignOut),
                    onTap: _busy ? null : _signOut,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _busy ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever, size: 20),
              label: Text(l10n.profileDeleteAccount),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
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

/// Standard Sign in with Apple button: black fill, white label, Apple logo.
///
/// The logo is the U+F8FF glyph, which the system font renders as the Apple
/// mark — safe here because the button is only built on Apple platforms.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Text(
          '',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        label: Text(AppLocalizations.of(context).profileSignInWithApple),
      ),
    );
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
        icon: const Icon(Icons.login, color: AppColors.primaryDeep),
        label: Text(AppLocalizations.of(context).profileSignInWithGoogle),
      ),
    );
  }
}
