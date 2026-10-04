// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'Mis recetas';

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navProfile => 'Perfil';

  @override
  String get offlineBanner => 'Estás sin conexión: viendo recetas guardadas';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionSubmit => 'Enviar';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionPaste => 'Pegar';

  @override
  String get actionClear => 'Borrar';

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get actionKeepEditing => 'Seguir editando';

  @override
  String get tooltipShare => 'Compartir';

  @override
  String get tooltipMore => 'Más';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get profileGuestName => 'Invitado';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recetas',
      one: '1 receta',
      zero: 'Sin recetas',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Sesión iniciada: tus recetas se guardan en tu cuenta';

  @override
  String profileSignInFailed(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get profileSignInInfoTitle => 'Antes de iniciar sesión';

  @override
  String get profileSignInInfoBody =>
      'Al iniciar sesión, las recetas que creaste como invitado se vinculan a tu cuenta, para que puedas abrirlas en cualquier dispositivo.\n\nLas recetas de invitado solo existen en este dispositivo hasta que inicies sesión, así que inicia sesión aquí antes de cambiar de dispositivo o no se conservarán.';

  @override
  String get profileGuestCardTitle => 'Estás navegando como invitado';

  @override
  String get profileGuestCardBody =>
      'Inicia sesión para mantener tus recetas seguras y acceder a ellas desde cualquier dispositivo. Las recetas que ya hayas creado se conservarán.';

  @override
  String get profileSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get profileSignInWithApple => 'Iniciar sesión con Apple';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileDeleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get profileDeleteAccountBody =>
      'Esto elimina permanentemente tu cuenta y tus datos: tus recetas, sus comentarios, tus categorías y tus enlaces compartidos. Esta acción no se puede deshacer.\n\nEs posible que se te pida iniciar sesión de nuevo para confirmar.';

  @override
  String get profileAccountDeleted => 'Tu cuenta y tus datos se eliminaron';

  @override
  String get profileReauthNeeded =>
      'Inicia sesión de nuevo y vuelve a intentar eliminar tu cuenta.';

  @override
  String profileDeleteFailed(String error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileAdPrivacy => 'Opciones de privacidad de anuncios';

  @override
  String get profileAdPrivacySubtitle =>
      'Cambia cómo los anuncios usan tus datos';

  @override
  String get languagePickerTitle => 'Elige un idioma';

  @override
  String get profileSettings => 'Ajustes';

  @override
  String get profileEditName => 'Editar nombre visible';

  @override
  String get profileEditNameTitle => 'Nombre visible';

  @override
  String get profileEditNameBody =>
      'Este es el nombre que aparece en las recetas que compartes y en el feed público.';

  @override
  String get profileDisplayNameLabel => 'Nombre visible';

  @override
  String get profileNameUpdated => 'Nombre visible actualizado';

  @override
  String get recipesAddRecipe => 'Añadir receta';

  @override
  String get recipesSearch => 'Buscar recetas';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterAllLanguages => 'Todos los idiomas';

  @override
  String get recipesEmptyNoMatchTitle => 'No hay recetas que coincidan';

  @override
  String get recipesEmptyTitle => 'Aún no hay recetas';

  @override
  String get recipesEmptyNoMatchBody => 'Prueba con otra búsqueda o categoría.';

  @override
  String get recipesEmptyBody =>
      'Toca «Añadir receta» para crear o importar tu primera receta.';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get addSheetTitle => 'Añadir una receta';

  @override
  String get addSheetCreateTitle => 'Crear receta';

  @override
  String get addSheetCreateSubtitle =>
      'Introduce los ingredientes y los pasos manualmente';

  @override
  String get addSheetImportTitle => 'Importar desde URL';

  @override
  String get addSheetImportSubtitle => 'Pega un enlace de receta o de TikTok';

  @override
  String get addSheetCodeTitle => 'Introducir un código para compartir';

  @override
  String get addSheetCodeSubtitle =>
      'Abre una receta que alguien compartió contigo';

  @override
  String get shareCodeDialogTitle => 'Introducir código para compartir';

  @override
  String get shareCodeHint => 'p. ej. K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Receta no encontrada';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuMakePrivate => 'Hacer privada';

  @override
  String get menuMakePublic => 'Hacer pública';

  @override
  String get menuDelete => 'Eliminar';

  @override
  String couldNotShare(String error) {
    return 'No se pudo compartir: $error';
  }

  @override
  String get recipeNowPrivate => 'La receta ahora es privada';

  @override
  String get recipeNowPublic => 'La receta ahora es pública';

  @override
  String get deleteRecipeTitle => '¿Eliminar receta?';

  @override
  String get deleteRecipeBody => 'Esta acción no se puede deshacer.';

  @override
  String get editRecipeTitle => 'Editar receta';

  @override
  String get newRecipeTitle => 'Nueva receta';

  @override
  String get fieldTitle => 'Título';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String get fieldDescriptionOptional => 'Descripción (opcional)';

  @override
  String get fieldIngredients => 'Ingredientes';

  @override
  String get helperOnePerLine => 'Uno por línea';

  @override
  String get addAtLeastOneIngredient => 'Añade al menos un ingrediente';

  @override
  String get addIngredient => 'Añadir ingrediente';

  @override
  String get ingredientHint => 'p. ej. 2 tazas de harina';

  @override
  String get addIngredientGroup => 'Añadir grupo de ingredientes';

  @override
  String get ingredientGroupNameHint => 'Nombre del grupo (p. ej. Masa)';

  @override
  String get removeIngredientGroup => 'Eliminar grupo';

  @override
  String get fieldSteps => 'Pasos';

  @override
  String get addAtLeastOneStep => 'Añade al menos un paso';

  @override
  String get addStep => 'Añadir paso';

  @override
  String get stepHint => 'Describe este paso';

  @override
  String get fieldSourceUrlOptional => 'URL de origen (opcional)';

  @override
  String get categoriesLabel => 'Categorías';

  @override
  String get fieldPublic => 'Pública';

  @override
  String get fieldPublicSubtitle => 'Compartir en el feed de Descubrir';

  @override
  String get recipeUpdated => 'Receta actualizada';

  @override
  String get recipeCreated => 'Receta creada';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get createRecipe => 'Crear receta';

  @override
  String get recipeLanguageLabel => 'Idioma';

  @override
  String get discardChangesTitle => '¿Descartar los cambios?';

  @override
  String get discardChangesBody =>
      'Los cambios en esta receta aún no se han guardado.';

  @override
  String get importTitle => 'Importar receta';

  @override
  String get importIntro =>
      'Pega un enlace de un sitio de recetas o de TikTok. Extraeremos los ingredientes y los pasos para que puedas revisarlos y guardarlos.';

  @override
  String get importUrlLabel => 'URL de la receta';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Pega una URL';

  @override
  String get importButton => 'Importar';

  @override
  String get importingButton => 'Importando…';

  @override
  String get importProgress => 'Obteniendo y analizando la página…';

  @override
  String get importOfflineError =>
      'Estás sin conexión. Conéctate a internet para importar una receta desde un enlace.';

  @override
  String get importNetworkError =>
      'No se pudo acceder a esa página. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get importReadError =>
      'No encontramos ninguna receta en esa página. Prueba con otro enlace.';

  @override
  String get clipboardNoLink => 'No hay ningún enlace en el portapapeles';

  @override
  String get offlineBannerEditing =>
      'Sin conexión: tus cambios se guardan en este dispositivo y se sincronizan cuando vuelvas a conectarte.';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get newCategoryButton => 'Nueva categoría';

  @override
  String get categoriesEmpty =>
      'Aún no hay categorías.\nCrea una para organizar tus recetas.';

  @override
  String deleteCategoryTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get deleteCategoryBody =>
      'Las recetas conservan su contenido; solo pierden esta etiqueta.';

  @override
  String get editCategoryTitle => 'Editar categoría';

  @override
  String get newCategoryTitle => 'Nueva categoría';

  @override
  String get fieldName => 'Nombre';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get fieldColor => 'Color';

  @override
  String get createCategory => 'Crear categoría';

  @override
  String get discoverTitle => 'Descubrir';

  @override
  String get surpriseMe => 'Sorpréndeme';

  @override
  String get discoverSearch => 'Buscar recetas públicas';

  @override
  String get discoverEmpty =>
      'Aún no hay recetas públicas.\nHaz pública una de las tuyas para compartirla aquí.';

  @override
  String get recipeNotAvailable => 'Esta receta no está disponible.';

  @override
  String get menuReport => 'Denunciar';

  @override
  String get menuBlock => 'Bloquear / ocultar';

  @override
  String get copyToMyRecipes => 'Copiar a mis recetas';

  @override
  String get copiedToRecipes => 'Copiada a tus recetas';

  @override
  String get commentsTitle => 'Comentarios';

  @override
  String get commentYourNameOptional => 'Tu nombre (opcional)';

  @override
  String get commentAddHint => 'Añade un comentario…';

  @override
  String get commentPostAnonymously => 'Publicar de forma anónima';

  @override
  String get commentPost => 'Publicar';

  @override
  String get commentPosting => 'Publicando…';

  @override
  String get commentsEmpty => 'Aún no hay comentarios. ¡Sé el primero!';

  @override
  String couldNotPost(String error) {
    return 'No se pudo publicar: $error';
  }

  @override
  String get sharedRecipeTitle => 'Receta compartida';

  @override
  String get shareCodeNotFound =>
      'Ese código para compartir no existe.\nCompruébalo y vuelve a intentarlo.';

  @override
  String recipeByAuthor(String author) {
    return 'por $author';
  }

  @override
  String get ingredientsTitle => 'Ingredientes';

  @override
  String get stepsTitle => 'Pasos';

  @override
  String get unitsLabel => 'Unidades';

  @override
  String get unitsAsWritten => 'Original';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get cookMode => 'Modo cocina';

  @override
  String get cookModeOnHint =>
      'Texto más grande, la pantalla permanece encendida';

  @override
  String get copyIngredients => 'Copiar ingredientes';

  @override
  String get ingredientsCopied => 'Ingredientes copiados al portapapeles';

  @override
  String get uncheckAll => 'Desmarcar todo';

  @override
  String recipeSource(String url) {
    return 'Fuente: $url';
  }

  @override
  String ingredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredientes',
      one: '1 ingrediente',
    );
    return '$_temp0';
  }

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasos',
      one: '1 paso',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return 'Se ocultó «$title»';
  }

  @override
  String couldNotBlock(String error) {
    return 'No se pudo bloquear: $error';
  }

  @override
  String get reportSubmitted => 'Gracias, tu denuncia se envió';

  @override
  String couldNotReport(String error) {
    return 'No se pudo denunciar: $error';
  }

  @override
  String get reportRecipeTitle => 'Denunciar receta';

  @override
  String reportWhy(String title) {
    return '¿Por qué denuncias «$title»?';
  }

  @override
  String get reportDetailsOptional => 'Detalles (opcional)';

  @override
  String get reportReasonSpam => 'Spam o engañoso';

  @override
  String get reportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get reportReasonOffensive => 'Ofensivo o de odio';

  @override
  String get reportReasonCopyright => 'Violación de derechos de autor';

  @override
  String get reportReasonOther => 'Otra cosa';
}
