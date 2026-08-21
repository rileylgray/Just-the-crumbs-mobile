// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'Mes recettes';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navProfile => 'Profil';

  @override
  String get offlineBanner => 'Vous êtes hors ligne — recettes enregistrées';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionSubmit => 'Envoyer';

  @override
  String get actionUndo => 'Annuler';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get tooltipShare => 'Partager';

  @override
  String get tooltipMore => 'Plus';

  @override
  String errorWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get profileGuestName => 'Invité';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes',
      one: '1 recette',
      zero: 'Aucune recette',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Connecté — vos recettes sont enregistrées sur votre compte';

  @override
  String profileSignInFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get profileSignInInfoTitle => 'Avant de vous connecter';

  @override
  String get profileSignInInfoBody =>
      'En vous connectant, les recettes créées en tant qu\'invité sont associées à votre compte, pour que vous puissiez les ouvrir sur n\'importe quel appareil.\n\nLes recettes d\'invité n\'existent que sur cet appareil jusqu\'à votre connexion — connectez-vous donc ici avant de changer d\'appareil, sinon elles ne seront pas conservées.';

  @override
  String get profileGuestCardTitle => 'Vous naviguez en tant qu\'invité';

  @override
  String get profileGuestCardBody =>
      'Connectez-vous pour garder vos recettes en sécurité et y accéder depuis n\'importe quel appareil. Les recettes que vous avez déjà créées seront conservées.';

  @override
  String get profileSignInWithGoogle => 'Se connecter avec Google';

  @override
  String get profileSignInWithApple => 'Se connecter avec Apple';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get profileDeleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get profileDeleteAccountBody =>
      'Cela supprime définitivement votre compte et vos données : vos recettes, leurs commentaires, vos catégories et vos liens partagés. Cette action est irréversible.\n\nIl se peut que l\'on vous demande de vous reconnecter pour confirmer.';

  @override
  String get profileAccountDeleted =>
      'Votre compte et vos données ont été supprimés';

  @override
  String get profileReauthNeeded =>
      'Veuillez vous reconnecter, puis réessayer de supprimer votre compte.';

  @override
  String profileDeleteFailed(String error) {
    return 'Impossible de supprimer le compte : $error';
  }

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileAdPrivacy => 'Choix de confidentialité publicitaire';

  @override
  String get profileAdPrivacySubtitle =>
      'Modifiez l\'utilisation de vos données par les pubs';

  @override
  String get languagePickerTitle => 'Choisir une langue';

  @override
  String get profileEditName => 'Modifier le nom affiché';

  @override
  String get profileEditNameTitle => 'Nom affiché';

  @override
  String get profileEditNameBody =>
      'C\'est le nom affiché sur les recettes que vous partagez et dans le fil public.';

  @override
  String get profileDisplayNameLabel => 'Nom affiché';

  @override
  String get profileNameUpdated => 'Nom affiché mis à jour';

  @override
  String get recipesAddRecipe => 'Ajouter une recette';

  @override
  String get recipesSearch => 'Rechercher des recettes';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterAllLanguages => 'Toutes les langues';

  @override
  String get recipesEmptyNoMatchTitle => 'Aucune recette correspondante';

  @override
  String get recipesEmptyTitle => 'Pas encore de recettes';

  @override
  String get recipesEmptyNoMatchBody =>
      'Essayez une autre recherche ou catégorie.';

  @override
  String get recipesEmptyBody =>
      'Appuyez sur « Ajouter une recette » pour créer ou importer votre première recette.';

  @override
  String get addSheetCreateTitle => 'Créer une recette';

  @override
  String get addSheetCreateSubtitle =>
      'Saisir les ingrédients et les étapes manuellement';

  @override
  String get addSheetImportTitle => 'Importer depuis une URL';

  @override
  String get addSheetImportSubtitle => 'Coller un lien de recette ou TikTok';

  @override
  String get addSheetCodeTitle => 'Saisir un code de partage';

  @override
  String get addSheetCodeSubtitle =>
      'Ouvrir une recette que quelqu\'un a partagée avec vous';

  @override
  String get shareCodeDialogTitle => 'Saisir le code de partage';

  @override
  String get shareCodeHint => 'ex. K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Recette introuvable';

  @override
  String get menuEdit => 'Modifier';

  @override
  String get menuMakePrivate => 'Rendre privée';

  @override
  String get menuMakePublic => 'Rendre publique';

  @override
  String get menuDelete => 'Supprimer';

  @override
  String couldNotShare(String error) {
    return 'Impossible de partager : $error';
  }

  @override
  String get recipeNowPrivate => 'La recette est désormais privée';

  @override
  String get recipeNowPublic => 'La recette est désormais publique';

  @override
  String get deleteRecipeTitle => 'Supprimer la recette ?';

  @override
  String get deleteRecipeBody => 'Cette action est irréversible.';

  @override
  String get editRecipeTitle => 'Modifier la recette';

  @override
  String get newRecipeTitle => 'Nouvelle recette';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get titleRequired => 'Le titre est obligatoire';

  @override
  String get fieldDescriptionOptional => 'Description (facultatif)';

  @override
  String get fieldIngredients => 'Ingrédients';

  @override
  String get helperOnePerLine => 'Un par ligne';

  @override
  String get addAtLeastOneIngredient => 'Ajoutez au moins un ingrédient';

  @override
  String get addIngredient => 'Ajouter un ingrédient';

  @override
  String get ingredientHint => 'ex. 2 tasses de farine';

  @override
  String get addIngredientGroup => 'Ajouter un groupe d\'ingrédients';

  @override
  String get ingredientGroupNameHint => 'Nom du groupe (ex. Pâte)';

  @override
  String get removeIngredientGroup => 'Supprimer le groupe';

  @override
  String get fieldSteps => 'Étapes';

  @override
  String get addAtLeastOneStep => 'Ajoutez au moins une étape';

  @override
  String get addStep => 'Ajouter une étape';

  @override
  String get stepHint => 'Décrivez cette étape';

  @override
  String get fieldSourceUrlOptional => 'URL source (facultatif)';

  @override
  String get categoriesLabel => 'Catégories';

  @override
  String get fieldPublic => 'Publique';

  @override
  String get fieldPublicSubtitle => 'Partager dans le fil Découvrir';

  @override
  String get recipeUpdated => 'Recette mise à jour';

  @override
  String get recipeCreated => 'Recette créée';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get createRecipe => 'Créer la recette';

  @override
  String get recipeLanguageLabel => 'Langue';

  @override
  String get importTitle => 'Importer une recette';

  @override
  String get importIntro =>
      'Collez un lien d\'un site de recettes ou de TikTok. Nous en extrairons les ingrédients et les étapes pour que vous puissiez les vérifier et les enregistrer.';

  @override
  String get importUrlLabel => 'URL de la recette';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Veuillez coller une URL';

  @override
  String get importButton => 'Importer';

  @override
  String get importingButton => 'Importation…';

  @override
  String get importProgress => 'Récupération et analyse de la page…';

  @override
  String get importOfflineError =>
      'Vous êtes hors ligne. Connectez-vous à internet pour importer une recette depuis un lien.';

  @override
  String get importNetworkError =>
      'Impossible d\'accéder à cette page. Vérifiez votre connexion et réessayez.';

  @override
  String get importReadError =>
      'Nous n\'avons trouvé aucune recette sur cette page. Essayez un autre lien.';

  @override
  String get offlineBannerEditing =>
      'Hors ligne — vos modifications sont enregistrées sur cet appareil et synchronisées dès que vous serez reconnecté.';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get newCategoryButton => 'Nouvelle catégorie';

  @override
  String get categoriesEmpty =>
      'Pas encore de catégories.\nCréez-en une pour organiser vos recettes.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteCategoryBody =>
      'Les recettes conservent leur contenu ; elles perdent seulement cette étiquette.';

  @override
  String get editCategoryTitle => 'Modifier la catégorie';

  @override
  String get newCategoryTitle => 'Nouvelle catégorie';

  @override
  String get fieldName => 'Nom';

  @override
  String get nameRequired => 'Le nom est obligatoire';

  @override
  String get fieldColor => 'Couleur';

  @override
  String get createCategory => 'Créer la catégorie';

  @override
  String get discoverTitle => 'Découvrir';

  @override
  String get surpriseMe => 'Surprenez-moi';

  @override
  String get discoverSearch => 'Rechercher des recettes publiques';

  @override
  String get discoverEmpty =>
      'Pas encore de recettes publiques.\nRendez l\'une des vôtres publique pour la partager ici.';

  @override
  String get recipeNotAvailable => 'Cette recette n\'est pas disponible.';

  @override
  String get menuReport => 'Signaler';

  @override
  String get menuBlock => 'Bloquer / masquer';

  @override
  String get copyToMyRecipes => 'Copier dans mes recettes';

  @override
  String get copiedToRecipes => 'Copiée dans vos recettes';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get commentYourNameOptional => 'Votre nom (facultatif)';

  @override
  String get commentAddHint => 'Ajouter un commentaire…';

  @override
  String get commentPostAnonymously => 'Publier de façon anonyme';

  @override
  String get commentPost => 'Publier';

  @override
  String get commentPosting => 'Publication…';

  @override
  String get commentsEmpty =>
      'Aucun commentaire pour l\'instant. Soyez le premier !';

  @override
  String couldNotPost(String error) {
    return 'Impossible de publier : $error';
  }

  @override
  String get sharedRecipeTitle => 'Recette partagée';

  @override
  String get shareCodeNotFound =>
      'Ce code de partage n\'existe pas.\nVérifiez-le et réessayez.';

  @override
  String recipeByAuthor(String author) {
    return 'par $author';
  }

  @override
  String get ingredientsTitle => 'Ingrédients';

  @override
  String get stepsTitle => 'Étapes';

  @override
  String get unitsLabel => 'Unités';

  @override
  String get unitsAsWritten => 'Original';

  @override
  String get unitsMetric => 'Métrique';

  @override
  String get unitsImperial => 'Impérial';

  @override
  String get cookMode => 'Mode cuisine';

  @override
  String get cookModeOnHint => 'Texte plus grand, écran toujours allumé';

  @override
  String recipeSource(String url) {
    return 'Source : $url';
  }

  @override
  String ingredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingrédients',
      one: '1 ingrédient',
    );
    return '$_temp0';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étapes',
      one: '1 étape',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return '« $title » masquée';
  }

  @override
  String couldNotBlock(String error) {
    return 'Impossible de bloquer : $error';
  }

  @override
  String get reportSubmitted => 'Merci — votre signalement a été envoyé';

  @override
  String couldNotReport(String error) {
    return 'Impossible de signaler : $error';
  }

  @override
  String get reportRecipeTitle => 'Signaler la recette';

  @override
  String reportWhy(String title) {
    return 'Pourquoi signalez-vous « $title » ?';
  }

  @override
  String get reportDetailsOptional => 'Détails (facultatif)';

  @override
  String get reportReasonSpam => 'Spam ou trompeur';

  @override
  String get reportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get reportReasonOffensive => 'Offensant ou haineux';

  @override
  String get reportReasonCopyright => 'Violation de droits d\'auteur';

  @override
  String get reportReasonOther => 'Autre chose';
}
