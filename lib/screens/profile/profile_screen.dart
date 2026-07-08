import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in — your recipes are saved to your account')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and your data — your recipes, '
          'their comments, your categories, and your shared links. This cannot '
          'be undone.\n\nYou may be asked to sign in again to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
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
        const SnackBar(content: Text('Your account and data were deleted')),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.code == 'requires-recent-login'
              ? 'Please sign in again, then retry deleting your account.'
              : 'Could not delete account: ${e.message}'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete account: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).value;
    final isGuest = ref.watch(isGuestProvider);
    final recipeCount = ref.watch(userRecipesProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
              user?.name ?? 'Guest',
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
            child: Text('$recipeCount recipe${recipeCount == 1 ? '' : 's'}',
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
                    const Text('You’re browsing as a guest',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in with Google to keep your recipes safe and access '
                      'them on any device. Recipes you’ve already made will carry over.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
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
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.textMuted),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever, size: 20),
            label: const Text('Delete account'),
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
        label: const Text('Sign in with Google'),
      ),
    );
  }
}
