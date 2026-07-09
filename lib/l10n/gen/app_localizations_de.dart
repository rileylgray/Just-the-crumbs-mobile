// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'Meine Rezepte';

  @override
  String get navDiscover => 'Entdecken';

  @override
  String get navProfile => 'Profil';

  @override
  String get offlineBanner => 'Offline – gespeicherte Rezepte werden angezeigt';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get actionSubmit => 'Absenden';

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String get tooltipShare => 'Teilen';

  @override
  String get tooltipMore => 'Mehr';

  @override
  String errorWithMessage(String error) {
    return 'Fehler: $error';
  }

  @override
  String get profileGuestName => 'Gast';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rezepte',
      one: '1 Rezept',
      zero: 'Keine Rezepte',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Angemeldet – deine Rezepte werden in deinem Konto gespeichert';

  @override
  String profileSignInFailed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get profileGuestCardTitle => 'Du bist als Gast unterwegs';

  @override
  String get profileGuestCardBody =>
      'Melde dich mit Google an, um deine Rezepte sicher aufzubewahren und von jedem Gerät darauf zuzugreifen. Bereits erstellte Rezepte werden übernommen.';

  @override
  String get profileSignInWithGoogle => 'Mit Google anmelden';

  @override
  String get profileSignOut => 'Abmelden';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String get profileDeleteAccountTitle => 'Konto löschen?';

  @override
  String get profileDeleteAccountBody =>
      'Dies löscht dein Konto und deine Daten dauerhaft – deine Rezepte, deren Kommentare, deine Kategorien und deine geteilten Links. Dies kann nicht rückgängig gemacht werden.\n\nZur Bestätigung wirst du möglicherweise erneut zur Anmeldung aufgefordert.';

  @override
  String get profileAccountDeleted =>
      'Dein Konto und deine Daten wurden gelöscht';

  @override
  String get profileReauthNeeded =>
      'Bitte melde dich erneut an und versuche dann noch einmal, dein Konto zu löschen.';

  @override
  String profileDeleteFailed(String error) {
    return 'Konto konnte nicht gelöscht werden: $error';
  }

  @override
  String get profileLanguage => 'Sprache';

  @override
  String get languagePickerTitle => 'Sprache auswählen';

  @override
  String get profileEditName => 'Anzeigenamen bearbeiten';

  @override
  String get profileEditNameTitle => 'Anzeigename';

  @override
  String get profileEditNameBody =>
      'Dieser Name wird bei geteilten Rezepten und im öffentlichen Feed angezeigt.';

  @override
  String get profileDisplayNameLabel => 'Anzeigename';

  @override
  String get profileNameUpdated => 'Anzeigename aktualisiert';

  @override
  String get recipesAddRecipe => 'Rezept hinzufügen';

  @override
  String get recipesSearch => 'Rezepte suchen';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterAllLanguages => 'Alle Sprachen';

  @override
  String get recipesEmptyNoMatchTitle => 'Keine passenden Rezepte';

  @override
  String get recipesEmptyTitle => 'Noch keine Rezepte';

  @override
  String get recipesEmptyNoMatchBody =>
      'Versuche eine andere Suche oder Kategorie.';

  @override
  String get recipesEmptyBody =>
      'Tippe auf „Rezept hinzufügen“, um dein erstes zu erstellen oder zu importieren.';

  @override
  String get addSheetCreateTitle => 'Rezept erstellen';

  @override
  String get addSheetCreateSubtitle => 'Zutaten und Schritte von Hand eingeben';

  @override
  String get addSheetImportTitle => 'Aus URL importieren';

  @override
  String get addSheetImportSubtitle => 'Rezept- oder TikTok-Link einfügen';

  @override
  String get addSheetCodeTitle => 'Teilen-Code eingeben';

  @override
  String get addSheetCodeSubtitle =>
      'Ein Rezept öffnen, das jemand mit dir geteilt hat';

  @override
  String get shareCodeDialogTitle => 'Teilen-Code eingeben';

  @override
  String get shareCodeHint => 'z. B. K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Rezept nicht gefunden';

  @override
  String get menuEdit => 'Bearbeiten';

  @override
  String get menuMakePrivate => 'Privat machen';

  @override
  String get menuMakePublic => 'Öffentlich machen';

  @override
  String get menuDelete => 'Löschen';

  @override
  String couldNotShare(String error) {
    return 'Teilen nicht möglich: $error';
  }

  @override
  String get recipeNowPrivate => 'Das Rezept ist jetzt privat';

  @override
  String get recipeNowPublic => 'Das Rezept ist jetzt öffentlich';

  @override
  String get deleteRecipeTitle => 'Rezept löschen?';

  @override
  String get deleteRecipeBody => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get editRecipeTitle => 'Rezept bearbeiten';

  @override
  String get newRecipeTitle => 'Neues Rezept';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String get fieldDescriptionOptional => 'Beschreibung (optional)';

  @override
  String get fieldIngredients => 'Zutaten';

  @override
  String get helperOnePerLine => 'Eine pro Zeile';

  @override
  String get addAtLeastOneIngredient => 'Füge mindestens eine Zutat hinzu';

  @override
  String get fieldSteps => 'Schritte';

  @override
  String get addAtLeastOneStep => 'Füge mindestens einen Schritt hinzu';

  @override
  String get fieldSourceUrlOptional => 'Quell-URL (optional)';

  @override
  String get categoriesLabel => 'Kategorien';

  @override
  String get fieldPublic => 'Öffentlich';

  @override
  String get fieldPublicSubtitle => 'Im Entdecken-Feed teilen';

  @override
  String get recipeUpdated => 'Rezept aktualisiert';

  @override
  String get recipeCreated => 'Rezept erstellt';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get createRecipe => 'Rezept erstellen';

  @override
  String get recipeLanguageLabel => 'Sprache';

  @override
  String get importTitle => 'Rezept importieren';

  @override
  String get importIntro =>
      'Füge einen Link von einer Rezept-Website oder TikTok ein. Wir extrahieren die Zutaten und Schritte, damit du sie prüfen und speichern kannst.';

  @override
  String get importUrlLabel => 'Rezept-URL';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Bitte füge eine URL ein';

  @override
  String get importButton => 'Importieren';

  @override
  String get importingButton => 'Wird importiert…';

  @override
  String get importProgress => 'Seite wird abgerufen und analysiert…';

  @override
  String get categoriesTitle => 'Kategorien';

  @override
  String get newCategoryButton => 'Neue Kategorie';

  @override
  String get categoriesEmpty =>
      'Noch keine Kategorien.\nErstelle eine, um deine Rezepte zu organisieren.';

  @override
  String deleteCategoryTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteCategoryBody =>
      'Rezepte behalten ihren Inhalt; sie verlieren nur diese Markierung.';

  @override
  String get editCategoryTitle => 'Kategorie bearbeiten';

  @override
  String get newCategoryTitle => 'Neue Kategorie';

  @override
  String get fieldName => 'Name';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get fieldColor => 'Farbe';

  @override
  String get createCategory => 'Kategorie erstellen';

  @override
  String get discoverTitle => 'Entdecken';

  @override
  String get surpriseMe => 'Überrasch mich';

  @override
  String get discoverSearch => 'Öffentliche Rezepte suchen';

  @override
  String get discoverEmpty =>
      'Noch keine öffentlichen Rezepte.\nMach eines deiner Rezepte öffentlich, um es hier zu teilen.';

  @override
  String get recipeNotAvailable => 'Dieses Rezept ist nicht verfügbar.';

  @override
  String get menuReport => 'Melden';

  @override
  String get menuBlock => 'Blockieren / ausblenden';

  @override
  String get copyToMyRecipes => 'In meine Rezepte kopieren';

  @override
  String get copiedToRecipes => 'In deine Rezepte kopiert';

  @override
  String get commentsTitle => 'Kommentare';

  @override
  String get commentYourNameOptional => 'Dein Name (optional)';

  @override
  String get commentAddHint => 'Kommentar hinzufügen…';

  @override
  String get commentPostAnonymously => 'Anonym posten';

  @override
  String get commentPost => 'Posten';

  @override
  String get commentPosting => 'Wird gepostet…';

  @override
  String get commentsEmpty => 'Noch keine Kommentare. Sei der Erste!';

  @override
  String couldNotPost(String error) {
    return 'Posten nicht möglich: $error';
  }

  @override
  String get sharedRecipeTitle => 'Geteiltes Rezept';

  @override
  String get shareCodeNotFound =>
      'Diesen Teilen-Code gibt es nicht.\nÜberprüfe ihn und versuche es erneut.';

  @override
  String recipeByAuthor(String author) {
    return 'von $author';
  }

  @override
  String get ingredientsTitle => 'Zutaten';

  @override
  String get stepsTitle => 'Schritte';

  @override
  String recipeSource(String url) {
    return 'Quelle: $url';
  }

  @override
  String ingredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zutaten',
      one: '1 Zutat',
    );
    return '$_temp0';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '1 Schritt',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return '„$title“ ausgeblendet';
  }

  @override
  String couldNotBlock(String error) {
    return 'Blockieren nicht möglich: $error';
  }

  @override
  String get reportSubmitted => 'Danke – deine Meldung wurde übermittelt';

  @override
  String couldNotReport(String error) {
    return 'Melden nicht möglich: $error';
  }

  @override
  String get reportRecipeTitle => 'Rezept melden';

  @override
  String reportWhy(String title) {
    return 'Warum meldest du „$title“?';
  }

  @override
  String get reportDetailsOptional => 'Details (optional)';

  @override
  String get reportReasonSpam => 'Spam oder irreführend';

  @override
  String get reportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get reportReasonOffensive => 'Beleidigend oder hasserfüllt';

  @override
  String get reportReasonCopyright => 'Urheberrechtsverletzung';

  @override
  String get reportReasonOther => 'Etwas anderes';
}
