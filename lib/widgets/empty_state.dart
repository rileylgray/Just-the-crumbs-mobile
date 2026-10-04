import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A friendly placeholder for an empty list or a missing item: a soft badge
/// (an [emoji] or an [icon]), a [title], an optional [message], and an
/// optional [action] button that offers the obvious next step.
///
/// Scrolls rather than overflows, so it stays intact when the keyboard takes
/// up most of the screen (e.g. while searching).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon,
    this.emoji,
    this.message,
    this.action,
  }) : assert(icon != null || emoji != null);

  /// Builds from a localized "Headline.\nMore detail." string: the first line
  /// becomes the [title] and the rest the [message].
  EmptyState.fromText(
    String text, {
    super.key,
    this.icon,
    this.emoji,
    this.action,
  })  : assert(icon != null || emoji != null),
        title = _headline(text),
        message = _detail(text);

  static String _headline(String text) {
    final i = text.indexOf('\n');
    return i < 0 ? text : text.substring(0, i);
  }

  static String? _detail(String text) {
    final i = text.indexOf('\n');
    return i < 0 ? null : text.substring(i + 1).trim();
  }

  final String title;
  final IconData? icon;
  final String? emoji;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 40))
                  : Icon(icon, size: 40, color: AppColors.primaryDeep),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
