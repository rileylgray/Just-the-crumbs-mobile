import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

/// A slim bar shown while the device can't reach the backend. The default
/// message suits browsing (the list is cached); pass [message] to tailor it,
/// e.g. on the edit form where changes still save locally and sync later.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.primarySoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18, color: AppColors.primaryDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message ?? l10n.offlineBanner,
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
