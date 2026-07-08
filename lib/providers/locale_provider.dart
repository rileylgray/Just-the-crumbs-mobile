import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/gen/app_localizations.dart';

/// A selectable UI language: the [locale] plus its own-language display name
/// (endonym) shown in the picker.
class AppLanguage {
  const AppLanguage(this.locale, this.name);
  final Locale locale;
  final String name;
}

/// The six languages the app ships with. English is the default (first).
/// Names are endonyms (shown in their own language), which is the convention
/// for a language picker and keeps them stable regardless of the active locale.
const supportedLanguages = <AppLanguage>[
  AppLanguage(Locale('en'), 'English'),
  AppLanguage(Locale('es'), 'Español'),
  AppLanguage(Locale('fr'), 'Français'),
  AppLanguage(Locale('de'), 'Deutsch'),
  AppLanguage(Locale('pt'), 'Português'),
  AppLanguage(Locale('it'), 'Italiano'),
];

/// A human-readable name for a BCP-47 language [code], for badging and
/// filtering recipes in the Discover feed. Recipe content can be in any
/// language — not only the six the UI ships in — so unknown codes fall back to
/// the uppercased code (e.g. `ja` → `JA`) rather than failing.
String languageDisplayName(String code) {
  final normalized = code.trim().toLowerCase();
  for (final lang in supportedLanguages) {
    if (lang.locale.languageCode == normalized) return lang.name;
  }
  return normalized.isEmpty ? '—' : normalized.toUpperCase();
}

/// Holds the live [SharedPreferences] instance. Overridden in `main()` with the
/// real instance loaded before `runApp`, so the saved locale is available
/// synchronously (no flash of the default language at launch).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// The current UI locale, persisted across restarts. Defaults to English when
/// nothing is saved or the saved code isn't one we support.
class LocaleController extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    return _localeForCode(code);
  }

  /// Selects [locale] and persists the choice.
  Future<void> setLocale(Locale locale) async {
    await ref.read(sharedPreferencesProvider).setString(
          _prefsKey,
          locale.languageCode,
        );
    state = locale;
  }

  static Locale _localeForCode(String? code) {
    final match = AppLocalizations.supportedLocales
        .where((l) => l.languageCode == code)
        .firstOrNull;
    return match ?? const Locale('en');
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
