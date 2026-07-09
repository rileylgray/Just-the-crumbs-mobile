// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'Le mie ricette';

  @override
  String get navDiscover => 'Scopri';

  @override
  String get navProfile => 'Profilo';

  @override
  String get offlineBanner =>
      'Sei offline — visualizzazione delle ricette salvate';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionOpen => 'Apri';

  @override
  String get actionSubmit => 'Invia';

  @override
  String get actionUndo => 'Annulla';

  @override
  String get actionContinue => 'Continua';

  @override
  String get tooltipShare => 'Condividi';

  @override
  String get tooltipMore => 'Altro';

  @override
  String errorWithMessage(String error) {
    return 'Errore: $error';
  }

  @override
  String get profileGuestName => 'Ospite';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricette',
      one: '1 ricetta',
      zero: 'Nessuna ricetta',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Accesso eseguito — le tue ricette sono salvate nel tuo account';

  @override
  String profileSignInFailed(String error) {
    return 'Accesso non riuscito: $error';
  }

  @override
  String get profileSignInInfoTitle => 'Prima di accedere';

  @override
  String get profileSignInInfoBody =>
      'Accedendo con Google, le ricette che hai creato come ospite vengono collegate al tuo account, così puoi aprirle da qualsiasi dispositivo.\n\nLe ricette da ospite esistono solo su questo telefono finché non accedi: accedi qui prima di passare a un nuovo telefono, altrimenti non verranno mantenute.';

  @override
  String get profileGuestCardTitle => 'Stai navigando come ospite';

  @override
  String get profileGuestCardBody =>
      'Accedi con Google per mantenere al sicuro le tue ricette e accedervi da qualsiasi dispositivo. Le ricette che hai già creato verranno mantenute.';

  @override
  String get profileSignInWithGoogle => 'Accedi con Google';

  @override
  String get profileSignOut => 'Esci';

  @override
  String get profileDeleteAccount => 'Elimina account';

  @override
  String get profileDeleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get profileDeleteAccountBody =>
      'Questo elimina definitivamente il tuo account e i tuoi dati: le tue ricette, i loro commenti, le tue categorie e i tuoi link condivisi. L\'operazione non può essere annullata.\n\nPotrebbe esserti chiesto di accedere di nuovo per confermare.';

  @override
  String get profileAccountDeleted =>
      'Il tuo account e i tuoi dati sono stati eliminati';

  @override
  String get profileReauthNeeded =>
      'Accedi di nuovo, poi riprova a eliminare il tuo account.';

  @override
  String profileDeleteFailed(String error) {
    return 'Impossibile eliminare l\'account: $error';
  }

  @override
  String get profileLanguage => 'Lingua';

  @override
  String get languagePickerTitle => 'Scegli una lingua';

  @override
  String get profileEditName => 'Modifica nome visualizzato';

  @override
  String get profileEditNameTitle => 'Nome visualizzato';

  @override
  String get profileEditNameBody =>
      'Questo è il nome mostrato sulle ricette che condividi e nel feed pubblico.';

  @override
  String get profileDisplayNameLabel => 'Nome visualizzato';

  @override
  String get profileNameUpdated => 'Nome visualizzato aggiornato';

  @override
  String get recipesAddRecipe => 'Aggiungi ricetta';

  @override
  String get recipesSearch => 'Cerca ricette';

  @override
  String get filterAll => 'Tutte';

  @override
  String get filterAllLanguages => 'Tutte le lingue';

  @override
  String get recipesEmptyNoMatchTitle => 'Nessuna ricetta corrisponde';

  @override
  String get recipesEmptyTitle => 'Ancora nessuna ricetta';

  @override
  String get recipesEmptyNoMatchBody =>
      'Prova con un\'altra ricerca o categoria.';

  @override
  String get recipesEmptyBody =>
      'Tocca “Aggiungi ricetta” per creare o importare la tua prima ricetta.';

  @override
  String get addSheetCreateTitle => 'Crea ricetta';

  @override
  String get addSheetCreateSubtitle =>
      'Inserisci ingredienti e passaggi a mano';

  @override
  String get addSheetImportTitle => 'Importa da URL';

  @override
  String get addSheetImportSubtitle =>
      'Incolla un link di una ricetta o di TikTok';

  @override
  String get addSheetCodeTitle => 'Inserisci un codice di condivisione';

  @override
  String get addSheetCodeSubtitle =>
      'Apri una ricetta che qualcuno ha condiviso con te';

  @override
  String get shareCodeDialogTitle => 'Inserisci il codice di condivisione';

  @override
  String get shareCodeHint => 'es. K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Ricetta non trovata';

  @override
  String get menuEdit => 'Modifica';

  @override
  String get menuMakePrivate => 'Rendi privata';

  @override
  String get menuMakePublic => 'Rendi pubblica';

  @override
  String get menuDelete => 'Elimina';

  @override
  String couldNotShare(String error) {
    return 'Impossibile condividere: $error';
  }

  @override
  String get recipeNowPrivate => 'La ricetta ora è privata';

  @override
  String get recipeNowPublic => 'La ricetta ora è pubblica';

  @override
  String get deleteRecipeTitle => 'Eliminare la ricetta?';

  @override
  String get deleteRecipeBody => 'L\'operazione non può essere annullata.';

  @override
  String get editRecipeTitle => 'Modifica ricetta';

  @override
  String get newRecipeTitle => 'Nuova ricetta';

  @override
  String get fieldTitle => 'Titolo';

  @override
  String get titleRequired => 'Il titolo è obbligatorio';

  @override
  String get fieldDescriptionOptional => 'Descrizione (facoltativa)';

  @override
  String get fieldIngredients => 'Ingredienti';

  @override
  String get helperOnePerLine => 'Uno per riga';

  @override
  String get addAtLeastOneIngredient => 'Aggiungi almeno un ingrediente';

  @override
  String get fieldSteps => 'Passaggi';

  @override
  String get addAtLeastOneStep => 'Aggiungi almeno un passaggio';

  @override
  String get fieldSourceUrlOptional => 'URL di origine (facoltativo)';

  @override
  String get categoriesLabel => 'Categorie';

  @override
  String get fieldPublic => 'Pubblica';

  @override
  String get fieldPublicSubtitle => 'Condividi nel feed Scopri';

  @override
  String get recipeUpdated => 'Ricetta aggiornata';

  @override
  String get recipeCreated => 'Ricetta creata';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get createRecipe => 'Crea ricetta';

  @override
  String get recipeLanguageLabel => 'Lingua';

  @override
  String get importTitle => 'Importa ricetta';

  @override
  String get importIntro =>
      'Incolla un link da un sito di ricette o da TikTok. Estrarremo gli ingredienti e i passaggi così potrai controllarli e salvarli.';

  @override
  String get importUrlLabel => 'URL della ricetta';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Incolla un URL';

  @override
  String get importButton => 'Importa';

  @override
  String get importingButton => 'Importazione…';

  @override
  String get importProgress => 'Recupero e analisi della pagina…';

  @override
  String get categoriesTitle => 'Categorie';

  @override
  String get newCategoryButton => 'Nuova categoria';

  @override
  String get categoriesEmpty =>
      'Ancora nessuna categoria.\nCreane una per organizzare le tue ricette.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Eliminare “$name”?';
  }

  @override
  String get deleteCategoryBody =>
      'Le ricette mantengono il loro contenuto; perdono solo questa etichetta.';

  @override
  String get editCategoryTitle => 'Modifica categoria';

  @override
  String get newCategoryTitle => 'Nuova categoria';

  @override
  String get fieldName => 'Nome';

  @override
  String get nameRequired => 'Il nome è obbligatorio';

  @override
  String get fieldColor => 'Colore';

  @override
  String get createCategory => 'Crea categoria';

  @override
  String get discoverTitle => 'Scopri';

  @override
  String get surpriseMe => 'Sorprendimi';

  @override
  String get discoverSearch => 'Cerca ricette pubbliche';

  @override
  String get discoverEmpty =>
      'Ancora nessuna ricetta pubblica.\nRendi pubblica una delle tue per condividerla qui.';

  @override
  String get recipeNotAvailable => 'Questa ricetta non è disponibile.';

  @override
  String get menuReport => 'Segnala';

  @override
  String get menuBlock => 'Blocca / nascondi';

  @override
  String get copyToMyRecipes => 'Copia nelle mie ricette';

  @override
  String get copiedToRecipes => 'Copiata nelle tue ricette';

  @override
  String get commentsTitle => 'Commenti';

  @override
  String get commentYourNameOptional => 'Il tuo nome (facoltativo)';

  @override
  String get commentAddHint => 'Aggiungi un commento…';

  @override
  String get commentPostAnonymously => 'Pubblica in modo anonimo';

  @override
  String get commentPost => 'Pubblica';

  @override
  String get commentPosting => 'Pubblicazione…';

  @override
  String get commentsEmpty => 'Ancora nessun commento. Sii il primo!';

  @override
  String couldNotPost(String error) {
    return 'Impossibile pubblicare: $error';
  }

  @override
  String get sharedRecipeTitle => 'Ricetta condivisa';

  @override
  String get shareCodeNotFound =>
      'Questo codice di condivisione non esiste.\nControllalo e riprova.';

  @override
  String recipeByAuthor(String author) {
    return 'di $author';
  }

  @override
  String get ingredientsTitle => 'Ingredienti';

  @override
  String get stepsTitle => 'Passaggi';

  @override
  String recipeSource(String url) {
    return 'Fonte: $url';
  }

  @override
  String ingredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredienti',
      one: '1 ingrediente',
    );
    return '$_temp0';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passaggi',
      one: '1 passaggio',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return '“$title” nascosta';
  }

  @override
  String couldNotBlock(String error) {
    return 'Impossibile bloccare: $error';
  }

  @override
  String get reportSubmitted => 'Grazie — la tua segnalazione è stata inviata';

  @override
  String couldNotReport(String error) {
    return 'Impossibile segnalare: $error';
  }

  @override
  String get reportRecipeTitle => 'Segnala ricetta';

  @override
  String reportWhy(String title) {
    return 'Perché stai segnalando “$title”?';
  }

  @override
  String get reportDetailsOptional => 'Dettagli (facoltativi)';

  @override
  String get reportReasonSpam => 'Spam o fuorviante';

  @override
  String get reportReasonInappropriate => 'Contenuto inappropriato';

  @override
  String get reportReasonOffensive => 'Offensivo o d\'odio';

  @override
  String get reportReasonCopyright => 'Violazione del copyright';

  @override
  String get reportReasonOther => 'Qualcos\'altro';
}
