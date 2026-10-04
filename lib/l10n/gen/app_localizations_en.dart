// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'My Recipes';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navProfile => 'Profile';

  @override
  String get offlineBanner => 'You\'re offline — viewing saved recipes';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionKeepEditing => 'Keep editing';

  @override
  String get tooltipShare => 'Share';

  @override
  String get tooltipMore => 'More';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get profileGuestName => 'Guest';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
      zero: 'No recipes',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Signed in — your recipes are saved to your account';

  @override
  String profileSignInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get profileSignInInfoTitle => 'Before you sign in';

  @override
  String get profileSignInInfoBody =>
      'Signing in links the recipes you\'ve made as a guest to your account, so you can open them on any device.\n\nGuest recipes live only on this device until you sign in — so sign in here before switching to a new device, or they won\'t carry over.';

  @override
  String get profileGuestCardTitle => 'You\'re browsing as a guest';

  @override
  String get profileGuestCardBody =>
      'Sign in to keep your recipes safe and access them on any device. Recipes you\'ve already made will carry over.';

  @override
  String get profileSignInWithGoogle => 'Sign in with Google';

  @override
  String get profileSignInWithApple => 'Sign in with Apple';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteAccountTitle => 'Delete account?';

  @override
  String get profileDeleteAccountBody =>
      'This permanently deletes your account and your data — your recipes, their comments, your categories, and your shared links. This cannot be undone.\n\nYou may be asked to sign in again to confirm.';

  @override
  String get profileAccountDeleted => 'Your account and data were deleted';

  @override
  String get profileReauthNeeded =>
      'Please sign in again, then retry deleting your account.';

  @override
  String profileDeleteFailed(String error) {
    return 'Could not delete account: $error';
  }

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileAdPrivacy => 'Ad privacy choices';

  @override
  String get profileAdPrivacySubtitle => 'Change how ads use your data';

  @override
  String get languagePickerTitle => 'Choose a language';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileEditName => 'Edit display name';

  @override
  String get profileEditNameTitle => 'Display name';

  @override
  String get profileEditNameBody =>
      'This is the name shown on recipes you share and on the public feed.';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileNameUpdated => 'Display name updated';

  @override
  String get recipesAddRecipe => 'Add recipe';

  @override
  String get recipesSearch => 'Search recipes';

  @override
  String get filterAll => 'All';

  @override
  String get filterAllLanguages => 'All languages';

  @override
  String get recipesEmptyNoMatchTitle => 'No recipes match';

  @override
  String get recipesEmptyTitle => 'No recipes yet';

  @override
  String get recipesEmptyNoMatchBody => 'Try a different search or category.';

  @override
  String get recipesEmptyBody =>
      'Tap “Add recipe” to create or import your first one.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get addSheetTitle => 'Add a recipe';

  @override
  String get addSheetCreateTitle => 'Create recipe';

  @override
  String get addSheetCreateSubtitle => 'Enter ingredients and steps by hand';

  @override
  String get addSheetImportTitle => 'Import from URL';

  @override
  String get addSheetImportSubtitle => 'Paste a recipe or TikTok link';

  @override
  String get addSheetCodeTitle => 'Enter a share code';

  @override
  String get addSheetCodeSubtitle => 'Open a recipe someone shared with you';

  @override
  String get shareCodeDialogTitle => 'Enter share code';

  @override
  String get shareCodeHint => 'e.g. K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Recipe not found';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuMakePrivate => 'Make private';

  @override
  String get menuMakePublic => 'Make public';

  @override
  String get menuDelete => 'Delete';

  @override
  String couldNotShare(String error) {
    return 'Could not share: $error';
  }

  @override
  String get recipeNowPrivate => 'Recipe is now private';

  @override
  String get recipeNowPublic => 'Recipe is now public';

  @override
  String get deleteRecipeTitle => 'Delete recipe?';

  @override
  String get deleteRecipeBody => 'This cannot be undone.';

  @override
  String get editRecipeTitle => 'Edit recipe';

  @override
  String get newRecipeTitle => 'New recipe';

  @override
  String get fieldTitle => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get fieldDescriptionOptional => 'Description (optional)';

  @override
  String get fieldIngredients => 'Ingredients';

  @override
  String get helperOnePerLine => 'One per line';

  @override
  String get addAtLeastOneIngredient => 'Add at least one ingredient';

  @override
  String get addIngredient => 'Add ingredient';

  @override
  String get ingredientHint => 'e.g. 2 cups flour';

  @override
  String get addIngredientGroup => 'Add ingredient group';

  @override
  String get ingredientGroupNameHint => 'Group name (e.g. Crust)';

  @override
  String get removeIngredientGroup => 'Remove group';

  @override
  String get fieldSteps => 'Steps';

  @override
  String get addAtLeastOneStep => 'Add at least one step';

  @override
  String get addStep => 'Add step';

  @override
  String get stepHint => 'Describe this step';

  @override
  String get fieldSourceUrlOptional => 'Source URL (optional)';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get fieldPublic => 'Public';

  @override
  String get fieldPublicSubtitle => 'Share in the Discover feed';

  @override
  String get recipeUpdated => 'Recipe updated';

  @override
  String get recipeCreated => 'Recipe created';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get createRecipe => 'Create recipe';

  @override
  String get recipeLanguageLabel => 'Language';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'Your changes to this recipe haven\'t been saved yet.';

  @override
  String get importTitle => 'Import recipe';

  @override
  String get importIntro =>
      'Paste a link from a recipe website or TikTok. We\'ll pull out the ingredients and steps so you can review and save.';

  @override
  String get importUrlLabel => 'Recipe URL';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Please paste a URL';

  @override
  String get importButton => 'Import';

  @override
  String get importingButton => 'Importing…';

  @override
  String get importProgress => 'Fetching and parsing the page…';

  @override
  String get importOfflineError =>
      'You\'re offline. Connect to the internet to import a recipe from a link.';

  @override
  String get importNetworkError =>
      'Couldn\'t reach that page. Check your connection and try again.';

  @override
  String get importReadError =>
      'We couldn\'t find a recipe on that page. Try a different link.';

  @override
  String get clipboardNoLink => 'There\'s no link on the clipboard';

  @override
  String get offlineBannerEditing =>
      'You\'re offline — your changes save on this device and sync when you reconnect.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get newCategoryButton => 'New category';

  @override
  String get categoriesEmpty =>
      'No categories yet.\nCreate one to organize your recipes.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteCategoryBody =>
      'Recipes keep their content; they just lose this tag.';

  @override
  String get editCategoryTitle => 'Edit category';

  @override
  String get newCategoryTitle => 'New category';

  @override
  String get fieldName => 'Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get fieldColor => 'Color';

  @override
  String get createCategory => 'Create category';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String get discoverSearch => 'Search public recipes';

  @override
  String get discoverEmpty =>
      'No public recipes yet.\nMake one of yours public to share it here.';

  @override
  String get recipeNotAvailable => 'This recipe is not available.';

  @override
  String get menuReport => 'Report';

  @override
  String get menuBlock => 'Block / hide';

  @override
  String get copyToMyRecipes => 'Copy to my recipes';

  @override
  String get copiedToRecipes => 'Copied to your recipes';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentYourNameOptional => 'Your name (optional)';

  @override
  String get commentAddHint => 'Add a comment…';

  @override
  String get commentPostAnonymously => 'Post anonymously';

  @override
  String get commentPost => 'Post';

  @override
  String get commentPosting => 'Posting…';

  @override
  String get commentsEmpty => 'No comments yet. Be the first!';

  @override
  String couldNotPost(String error) {
    return 'Could not post: $error';
  }

  @override
  String get sharedRecipeTitle => 'Shared recipe';

  @override
  String get shareCodeNotFound =>
      'That share code doesn\'t exist.\nDouble-check it and try again.';

  @override
  String recipeByAuthor(String author) {
    return 'by $author';
  }

  @override
  String get ingredientsTitle => 'Ingredients';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get unitsLabel => 'Units';

  @override
  String get unitsAsWritten => 'Original';

  @override
  String get unitsMetric => 'Metric';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get cookMode => 'Cook mode';

  @override
  String get cookModeOnHint => 'Larger text, screen stays on';

  @override
  String get copyIngredients => 'Copy ingredients';

  @override
  String get ingredientsCopied => 'Ingredients copied to the clipboard';

  @override
  String get uncheckAll => 'Uncheck all';

  @override
  String recipeSource(String url) {
    return 'Source: $url';
  }

  @override
  String ingredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return 'Hid “$title”';
  }

  @override
  String couldNotBlock(String error) {
    return 'Could not block: $error';
  }

  @override
  String get reportSubmitted => 'Thanks — your report was submitted';

  @override
  String couldNotReport(String error) {
    return 'Could not report: $error';
  }

  @override
  String get reportRecipeTitle => 'Report recipe';

  @override
  String reportWhy(String title) {
    return 'Why are you reporting “$title”?';
  }

  @override
  String get reportDetailsOptional => 'Details (optional)';

  @override
  String get reportReasonSpam => 'Spam or misleading';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonOffensive => 'Offensive or hateful';

  @override
  String get reportReasonCopyright => 'Copyright violation';

  @override
  String get reportReasonOther => 'Something else';
}
