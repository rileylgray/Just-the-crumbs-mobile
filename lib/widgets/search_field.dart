import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// The search box at the top of a recipe list. Shows a clear button once
/// something has been typed, so a search can be reset in one tap.
///
/// The [controller] belongs to the screen, so the screen can clear the search
/// too (e.g. from an empty state's "Clear filters").
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: AppLocalizations.of(context).actionClear,
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
    );
  }
}
