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

/// Endonyms for *content* language selection. Recipe content can be authored in
/// any language — not only the six the UI ships in ([supportedLanguages]) — so
/// the recipe editor's language picker and the Discover badges draw their names
/// from this far broader list. Names are endonyms (each in its own language),
/// the convention for a language picker, and stay stable regardless of the
/// active UI locale.
const contentLanguages = <AppLanguage>[
  AppLanguage(Locale('af'), 'Afrikaans'),
  AppLanguage(Locale('sq'), 'Shqip'),
  AppLanguage(Locale('am'), 'አማርኛ'),
  AppLanguage(Locale('ar'), 'العربية'),
  AppLanguage(Locale('hy'), 'Հայերեն'),
  AppLanguage(Locale('az'), 'Azərbaycan'),
  AppLanguage(Locale('eu'), 'Euskara'),
  AppLanguage(Locale('be'), 'Беларуская'),
  AppLanguage(Locale('bn'), 'বাংলা'),
  AppLanguage(Locale('bs'), 'Bosanski'),
  AppLanguage(Locale('bg'), 'Български'),
  AppLanguage(Locale('ca'), 'Català'),
  AppLanguage(Locale('zh'), '中文'),
  AppLanguage(Locale('hr'), 'Hrvatski'),
  AppLanguage(Locale('cs'), 'Čeština'),
  AppLanguage(Locale('da'), 'Dansk'),
  AppLanguage(Locale('nl'), 'Nederlands'),
  AppLanguage(Locale('en'), 'English'),
  AppLanguage(Locale('et'), 'Eesti'),
  AppLanguage(Locale('fil'), 'Filipino'),
  AppLanguage(Locale('fi'), 'Suomi'),
  AppLanguage(Locale('fr'), 'Français'),
  AppLanguage(Locale('gl'), 'Galego'),
  AppLanguage(Locale('ka'), 'ქართული'),
  AppLanguage(Locale('de'), 'Deutsch'),
  AppLanguage(Locale('el'), 'Ελληνικά'),
  AppLanguage(Locale('gu'), 'ગુજરાતી'),
  AppLanguage(Locale('he'), 'עברית'),
  AppLanguage(Locale('hi'), 'हिन्दी'),
  AppLanguage(Locale('hu'), 'Magyar'),
  AppLanguage(Locale('is'), 'Íslenska'),
  AppLanguage(Locale('id'), 'Indonesia'),
  AppLanguage(Locale('ga'), 'Gaeilge'),
  AppLanguage(Locale('it'), 'Italiano'),
  AppLanguage(Locale('ja'), '日本語'),
  AppLanguage(Locale('kn'), 'ಕನ್ನಡ'),
  AppLanguage(Locale('kk'), 'Қазақ'),
  AppLanguage(Locale('km'), 'ខ្មែរ'),
  AppLanguage(Locale('ko'), '한국어'),
  AppLanguage(Locale('ku'), 'Kurdî'),
  AppLanguage(Locale('lo'), 'ລາວ'),
  AppLanguage(Locale('lv'), 'Latviešu'),
  AppLanguage(Locale('lt'), 'Lietuvių'),
  AppLanguage(Locale('lb'), 'Lëtzebuergesch'),
  AppLanguage(Locale('mk'), 'Македонски'),
  AppLanguage(Locale('ms'), 'Melayu'),
  AppLanguage(Locale('ml'), 'മലയാളം'),
  AppLanguage(Locale('mt'), 'Malti'),
  AppLanguage(Locale('mr'), 'मराठी'),
  AppLanguage(Locale('mn'), 'Монгол'),
  AppLanguage(Locale('ne'), 'नेपाली'),
  AppLanguage(Locale('no'), 'Norsk'),
  AppLanguage(Locale('fa'), 'فارسی'),
  AppLanguage(Locale('pl'), 'Polski'),
  AppLanguage(Locale('pt'), 'Português'),
  AppLanguage(Locale('pa'), 'ਪੰਜਾਬੀ'),
  AppLanguage(Locale('ro'), 'Română'),
  AppLanguage(Locale('ru'), 'Русский'),
  AppLanguage(Locale('sr'), 'Српски'),
  AppLanguage(Locale('si'), 'සිංහල'),
  AppLanguage(Locale('sk'), 'Slovenčina'),
  AppLanguage(Locale('sl'), 'Slovenščina'),
  AppLanguage(Locale('es'), 'Español'),
  AppLanguage(Locale('sw'), 'Kiswahili'),
  AppLanguage(Locale('sv'), 'Svenska'),
  AppLanguage(Locale('ta'), 'தமிழ்'),
  AppLanguage(Locale('te'), 'తెలుగు'),
  AppLanguage(Locale('th'), 'ไทย'),
  AppLanguage(Locale('tr'), 'Türkçe'),
  AppLanguage(Locale('uk'), 'Українська'),
  AppLanguage(Locale('ur'), 'اردو'),
  AppLanguage(Locale('uz'), 'Oʻzbek'),
  AppLanguage(Locale('vi'), 'Tiếng Việt'),
  AppLanguage(Locale('cy'), 'Cymraeg'),
  AppLanguage(Locale('yi'), 'ייִדיש'),
  AppLanguage(Locale('zu'), 'isiZulu'),
];

/// Fast lookup of a content language's endonym by its code.
final Map<String, String> _contentLanguageNames = {
  for (final lang in contentLanguages) lang.locale.languageCode: lang.name,
};

/// A human-readable name for a BCP-47 language [code], for badging and
/// filtering recipes in the Discover feed and labelling the recipe editor's
/// language picker. Recipe content can be in any language, so a code we don't
/// know an endonym for falls back to the uppercased code (e.g. `xx` → `XX`)
/// rather than failing.
String languageDisplayName(String code) {
  final normalized = code.trim().toLowerCase();
  final name = _contentLanguageNames[normalized];
  if (name != null) return name;
  return normalized.isEmpty ? '—' : normalized.toUpperCase();
}

/// The selectable content-language codes for the recipe editor: every language
/// in [contentLanguages], sorted by display name, with [extra] (e.g. a recipe's
/// existing code that isn't in the list) folded in so an existing value is never
/// dropped from the picker.
List<String> contentLanguageCodes({String? extra}) {
  final codes = <String>{
    for (final lang in contentLanguages) lang.locale.languageCode,
    if (extra != null && extra.trim().isNotEmpty) extra.trim().toLowerCase(),
  }.toList();
  codes.sort(
    (a, b) => languageDisplayName(a)
        .toLowerCase()
        .compareTo(languageDisplayName(b).toLowerCase()),
  );
  return codes;
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

/// The viewer's persisted content-language preference for the Discover feed.
///
/// [chosen] is false until the user first taps a language chip; while false the
/// feed falls back to the viewer's UI language (see the feed's effective-language
/// logic). Once [chosen], [language] is the explicit selection — `null` meaning
/// "All languages".
class ContentLanguagePref {
  const ContentLanguagePref({required this.chosen, required this.language});

  /// The initial state before the user has ever picked a language.
  static const unset = ContentLanguagePref(chosen: false, language: null);

  final bool chosen;
  final String? language;
}

/// Persists the Discover feed's content-language filter across restarts.
///
/// Stored as a single string under [_prefsKey]: absent means "never chosen",
/// [_allSentinel] means the user explicitly picked "All languages", and any
/// other value is a BCP-47 language code.
class ContentLanguageController extends Notifier<ContentLanguagePref> {
  static const _prefsKey = 'public_content_language';
  static const _allSentinel = '__all__';

  @override
  ContentLanguagePref build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) return ContentLanguagePref.unset;
    if (raw == _allSentinel) {
      return const ContentLanguagePref(chosen: true, language: null);
    }
    return ContentLanguagePref(chosen: true, language: raw);
  }

  /// Selects [code] (`null` for "All languages") and persists it.
  Future<void> setLanguage(String? code) async {
    await ref.read(sharedPreferencesProvider).setString(
          _prefsKey,
          code ?? _allSentinel,
        );
    state = ContentLanguagePref(chosen: true, language: code);
  }
}

final contentLanguageProvider =
    NotifierProvider<ContentLanguageController, ContentLanguagePref>(
  ContentLanguageController.new,
);

/// How to display measurements in a recipe: exactly as written, or converted to
/// metric or imperial. The choice is remembered across recipes and restarts.
enum MeasurementSystem { asWritten, metric, imperial }

/// Persists the reader's preferred measurement system for recipe pages.
///
/// Defaults to [MeasurementSystem.asWritten] so a recipe's original text is
/// never converted until the reader explicitly asks for it.
class MeasurementSystemController extends Notifier<MeasurementSystem> {
  static const _prefsKey = 'measurement_system';

  @override
  MeasurementSystem build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    return MeasurementSystem.values
            .where((s) => s.name == raw)
            .firstOrNull ??
        MeasurementSystem.asWritten;
  }

  Future<void> set(MeasurementSystem system) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, system.name);
    state = system;
  }
}

final measurementSystemProvider =
    NotifierProvider<MeasurementSystemController, MeasurementSystem>(
  MeasurementSystemController.new,
);
