import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'🥐 Just The Crumbs'**
  String get appTitle;

  /// No description provided for @navMyRecipes.
  ///
  /// In en, this message translates to:
  /// **'My Recipes'**
  String get navMyRecipes;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — viewing saved recipes'**
  String get offlineBanner;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @tooltipMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tooltipMore;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @profileGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestName;

  /// No description provided for @profileRecipeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No recipes} =1{1 recipe} other{{count} recipes}}'**
  String profileRecipeCount(int count);

  /// No description provided for @profileSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in — your recipes are saved to your account'**
  String get profileSignedIn;

  /// No description provided for @profileSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String profileSignInFailed(String error);

  /// No description provided for @profileSignInInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you sign in'**
  String get profileSignInInfoTitle;

  /// No description provided for @profileSignInInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Signing in links the recipes you\'ve made as a guest to your account, so you can open them on any device.\n\nGuest recipes live only on this device until you sign in — so sign in here before switching to a new device, or they won\'t carry over.'**
  String get profileSignInInfoBody;

  /// No description provided for @profileGuestCardTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get profileGuestCardTitle;

  /// No description provided for @profileGuestCardBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your recipes safe and access them on any device. Recipes you\'ve already made will carry over.'**
  String get profileGuestCardBody;

  /// No description provided for @profileSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get profileSignInWithGoogle;

  /// No description provided for @profileSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get profileSignInWithApple;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteAccountTitle;

  /// No description provided for @profileDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and your data — your recipes, their comments, your categories, and your shared links. This cannot be undone.\n\nYou may be asked to sign in again to confirm.'**
  String get profileDeleteAccountBody;

  /// No description provided for @profileAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account and data were deleted'**
  String get profileAccountDeleted;

  /// No description provided for @profileReauthNeeded.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry deleting your account.'**
  String get profileReauthNeeded;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {error}'**
  String profileDeleteFailed(String error);

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get languagePickerTitle;

  /// No description provided for @profileEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get profileEditName;

  /// No description provided for @profileEditNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileEditNameTitle;

  /// No description provided for @profileEditNameBody.
  ///
  /// In en, this message translates to:
  /// **'This is the name shown on recipes you share and on the public feed.'**
  String get profileEditNameBody;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Display name updated'**
  String get profileNameUpdated;

  /// No description provided for @recipesAddRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add recipe'**
  String get recipesAddRecipe;

  /// No description provided for @recipesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recipes'**
  String get recipesSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get filterAllLanguages;

  /// No description provided for @recipesEmptyNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No recipes match'**
  String get recipesEmptyNoMatchTitle;

  /// No description provided for @recipesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet'**
  String get recipesEmptyTitle;

  /// No description provided for @recipesEmptyNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or category.'**
  String get recipesEmptyNoMatchBody;

  /// No description provided for @recipesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add recipe” to create or import your first one.'**
  String get recipesEmptyBody;

  /// No description provided for @addSheetCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create recipe'**
  String get addSheetCreateTitle;

  /// No description provided for @addSheetCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter ingredients and steps by hand'**
  String get addSheetCreateSubtitle;

  /// No description provided for @addSheetImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from URL'**
  String get addSheetImportTitle;

  /// No description provided for @addSheetImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a recipe or TikTok link'**
  String get addSheetImportSubtitle;

  /// No description provided for @addSheetCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a share code'**
  String get addSheetCodeTitle;

  /// No description provided for @addSheetCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a recipe someone shared with you'**
  String get addSheetCodeSubtitle;

  /// No description provided for @shareCodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter share code'**
  String get shareCodeDialogTitle;

  /// No description provided for @shareCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. K7Q2M9AZ'**
  String get shareCodeHint;

  /// No description provided for @recipeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found'**
  String get recipeNotFound;

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @menuMakePrivate.
  ///
  /// In en, this message translates to:
  /// **'Make private'**
  String get menuMakePrivate;

  /// No description provided for @menuMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Make public'**
  String get menuMakePublic;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @couldNotShare.
  ///
  /// In en, this message translates to:
  /// **'Could not share: {error}'**
  String couldNotShare(String error);

  /// No description provided for @recipeNowPrivate.
  ///
  /// In en, this message translates to:
  /// **'Recipe is now private'**
  String get recipeNowPrivate;

  /// No description provided for @recipeNowPublic.
  ///
  /// In en, this message translates to:
  /// **'Recipe is now public'**
  String get recipeNowPublic;

  /// No description provided for @deleteRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe?'**
  String get deleteRecipeTitle;

  /// No description provided for @deleteRecipeBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteRecipeBody;

  /// No description provided for @editRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get editRecipeTitle;

  /// No description provided for @newRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'New recipe'**
  String get newRecipeTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @fieldDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get fieldDescriptionOptional;

  /// No description provided for @fieldIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get fieldIngredients;

  /// No description provided for @helperOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get helperOnePerLine;

  /// No description provided for @addAtLeastOneIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient'**
  String get addAtLeastOneIngredient;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get addIngredient;

  /// No description provided for @ingredientHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 cups flour'**
  String get ingredientHint;

  /// No description provided for @addIngredientGroup.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient group'**
  String get addIngredientGroup;

  /// No description provided for @ingredientGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name (e.g. Crust)'**
  String get ingredientGroupNameHint;

  /// No description provided for @removeIngredientGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove group'**
  String get removeIngredientGroup;

  /// No description provided for @fieldSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get fieldSteps;

  /// No description provided for @addAtLeastOneStep.
  ///
  /// In en, this message translates to:
  /// **'Add at least one step'**
  String get addAtLeastOneStep;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @stepHint.
  ///
  /// In en, this message translates to:
  /// **'Describe this step'**
  String get stepHint;

  /// No description provided for @fieldSourceUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Source URL (optional)'**
  String get fieldSourceUrlOptional;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @fieldPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get fieldPublic;

  /// No description provided for @fieldPublicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share in the Discover feed'**
  String get fieldPublicSubtitle;

  /// No description provided for @recipeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recipe updated'**
  String get recipeUpdated;

  /// No description provided for @recipeCreated.
  ///
  /// In en, this message translates to:
  /// **'Recipe created'**
  String get recipeCreated;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create recipe'**
  String get createRecipe;

  /// No description provided for @recipeLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get recipeLanguageLabel;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import recipe'**
  String get importTitle;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste a link from a recipe website or TikTok. We\'ll pull out the ingredients and steps so you can review and save.'**
  String get importIntro;

  /// No description provided for @importUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe URL'**
  String get importUrlLabel;

  /// No description provided for @importUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get importUrlHint;

  /// No description provided for @importPasteUrlError.
  ///
  /// In en, this message translates to:
  /// **'Please paste a URL'**
  String get importPasteUrlError;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importingButton.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importingButton;

  /// No description provided for @importProgress.
  ///
  /// In en, this message translates to:
  /// **'Fetching and parsing the page…'**
  String get importProgress;

  /// No description provided for @importOfflineError.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to import a recipe from a link.'**
  String get importOfflineError;

  /// No description provided for @importNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that page. Check your connection and try again.'**
  String get importNetworkError;

  /// No description provided for @importReadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a recipe on that page. Try a different link.'**
  String get importReadError;

  /// No description provided for @offlineBannerEditing.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — your changes save on this device and sync when you reconnect.'**
  String get offlineBannerEditing;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @newCategoryButton.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategoryButton;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\nCreate one to organize your recipes.'**
  String get categoriesEmpty;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteCategoryTitle(String name);

  /// No description provided for @deleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Recipes keep their content; they just lose this tag.'**
  String get deleteCategoryBody;

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategoryTitle;

  /// No description provided for @newCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategoryTitle;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @fieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get fieldColor;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get createCategory;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @discoverSearch.
  ///
  /// In en, this message translates to:
  /// **'Search public recipes'**
  String get discoverSearch;

  /// No description provided for @discoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'No public recipes yet.\nMake one of yours public to share it here.'**
  String get discoverEmpty;

  /// No description provided for @recipeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This recipe is not available.'**
  String get recipeNotAvailable;

  /// No description provided for @menuReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get menuReport;

  /// No description provided for @menuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block / hide'**
  String get menuBlock;

  /// No description provided for @copyToMyRecipes.
  ///
  /// In en, this message translates to:
  /// **'Copy to my recipes'**
  String get copyToMyRecipes;

  /// No description provided for @copiedToRecipes.
  ///
  /// In en, this message translates to:
  /// **'Copied to your recipes'**
  String get copiedToRecipes;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentYourNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get commentYourNameOptional;

  /// No description provided for @commentAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentAddHint;

  /// No description provided for @commentPostAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Post anonymously'**
  String get commentPostAnonymously;

  /// No description provided for @commentPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commentPost;

  /// No description provided for @commentPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get commentPosting;

  /// No description provided for @commentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get commentsEmpty;

  /// No description provided for @couldNotPost.
  ///
  /// In en, this message translates to:
  /// **'Could not post: {error}'**
  String couldNotPost(String error);

  /// No description provided for @sharedRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared recipe'**
  String get sharedRecipeTitle;

  /// No description provided for @shareCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'That share code doesn\'t exist.\nDouble-check it and try again.'**
  String get shareCodeNotFound;

  /// No description provided for @recipeByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String recipeByAuthor(String author);

  /// No description provided for @ingredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTitle;

  /// No description provided for @stepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsTitle;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsLabel;

  /// No description provided for @unitsAsWritten.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get unitsAsWritten;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitsImperial;

  /// No description provided for @cookMode.
  ///
  /// In en, this message translates to:
  /// **'Cook mode'**
  String get cookMode;

  /// No description provided for @cookModeOnHint.
  ///
  /// In en, this message translates to:
  /// **'Larger text, screen stays on'**
  String get cookModeOnHint;

  /// No description provided for @recipeSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {url}'**
  String recipeSource(String url);

  /// No description provided for @ingredientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
  String ingredientsCount(int count);

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String stepsCount(int count);

  /// No description provided for @ingredientsStepsSeparator.
  ///
  /// In en, this message translates to:
  /// **'{ingredients} · {steps}'**
  String ingredientsStepsSeparator(String ingredients, String steps);

  /// No description provided for @moderationHidRecipe.
  ///
  /// In en, this message translates to:
  /// **'Hid “{title}”'**
  String moderationHidRecipe(String title);

  /// No description provided for @couldNotBlock.
  ///
  /// In en, this message translates to:
  /// **'Could not block: {error}'**
  String couldNotBlock(String error);

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was submitted'**
  String get reportSubmitted;

  /// No description provided for @couldNotReport.
  ///
  /// In en, this message translates to:
  /// **'Could not report: {error}'**
  String couldNotReport(String error);

  /// No description provided for @reportRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Report recipe'**
  String get reportRecipeTitle;

  /// No description provided for @reportWhy.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting “{title}”?'**
  String reportWhy(String title);

  /// No description provided for @reportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetailsOptional;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or misleading'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive or hateful'**
  String get reportReasonOffensive;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright violation'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
