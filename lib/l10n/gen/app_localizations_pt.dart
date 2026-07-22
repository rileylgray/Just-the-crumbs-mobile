// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => '🥐 Just The Crumbs';

  @override
  String get navMyRecipes => 'Minhas receitas';

  @override
  String get navDiscover => 'Descobrir';

  @override
  String get navProfile => 'Perfil';

  @override
  String get offlineBanner => 'Você está offline — vendo receitas salvas';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionSubmit => 'Enviar';

  @override
  String get actionUndo => 'Desfazer';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get tooltipShare => 'Compartilhar';

  @override
  String get tooltipMore => 'Mais';

  @override
  String errorWithMessage(String error) {
    return 'Erro: $error';
  }

  @override
  String get profileGuestName => 'Convidado';

  @override
  String profileRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receitas',
      one: '1 receita',
      zero: 'Nenhuma receita',
    );
    return '$_temp0';
  }

  @override
  String get profileSignedIn =>
      'Conectado — suas receitas são salvas na sua conta';

  @override
  String profileSignInFailed(String error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get profileSignInInfoTitle => 'Antes de entrar';

  @override
  String get profileSignInInfoBody =>
      'Ao entrar com o Google, as receitas que você criou como convidado são vinculadas à sua conta, para que você possa abri-las em qualquer dispositivo.\n\nAs receitas de convidado existem apenas neste telefone até você entrar — então entre aqui antes de trocar de telefone, ou elas não serão mantidas.';

  @override
  String get profileGuestCardTitle => 'Você está navegando como convidado';

  @override
  String get profileGuestCardBody =>
      'Entre com o Google para manter suas receitas seguras e acessá-las em qualquer dispositivo. As receitas que você já criou serão mantidas.';

  @override
  String get profileSignInWithGoogle => 'Entrar com o Google';

  @override
  String get profileSignOut => 'Sair';

  @override
  String get profileDeleteAccount => 'Excluir conta';

  @override
  String get profileDeleteAccountTitle => 'Excluir conta?';

  @override
  String get profileDeleteAccountBody =>
      'Isso exclui permanentemente sua conta e seus dados — suas receitas, seus comentários, suas categorias e seus links compartilhados. Não é possível desfazer.\n\nVocê pode ser solicitado a entrar novamente para confirmar.';

  @override
  String get profileAccountDeleted => 'Sua conta e seus dados foram excluídos';

  @override
  String get profileReauthNeeded =>
      'Entre novamente e tente excluir sua conta outra vez.';

  @override
  String profileDeleteFailed(String error) {
    return 'Não foi possível excluir a conta: $error';
  }

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get languagePickerTitle => 'Escolha um idioma';

  @override
  String get profileEditName => 'Editar nome de exibição';

  @override
  String get profileEditNameTitle => 'Nome de exibição';

  @override
  String get profileEditNameBody =>
      'Este é o nome exibido nas receitas que você compartilha e no feed público.';

  @override
  String get profileDisplayNameLabel => 'Nome de exibição';

  @override
  String get profileNameUpdated => 'Nome de exibição atualizado';

  @override
  String get recipesAddRecipe => 'Adicionar receita';

  @override
  String get recipesSearch => 'Buscar receitas';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterAllLanguages => 'Todos os idiomas';

  @override
  String get recipesEmptyNoMatchTitle => 'Nenhuma receita corresponde';

  @override
  String get recipesEmptyTitle => 'Ainda não há receitas';

  @override
  String get recipesEmptyNoMatchBody => 'Tente outra busca ou categoria.';

  @override
  String get recipesEmptyBody =>
      'Toque em “Adicionar receita” para criar ou importar a sua primeira.';

  @override
  String get addSheetCreateTitle => 'Criar receita';

  @override
  String get addSheetCreateSubtitle =>
      'Insira os ingredientes e as etapas manualmente';

  @override
  String get addSheetImportTitle => 'Importar de URL';

  @override
  String get addSheetImportSubtitle => 'Cole um link de receita ou do TikTok';

  @override
  String get addSheetCodeTitle => 'Inserir um código de compartilhamento';

  @override
  String get addSheetCodeSubtitle =>
      'Abra uma receita que alguém compartilhou com você';

  @override
  String get shareCodeDialogTitle => 'Inserir código de compartilhamento';

  @override
  String get shareCodeHint => 'ex.: K7Q2M9AZ';

  @override
  String get recipeNotFound => 'Receita não encontrada';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuMakePrivate => 'Tornar privada';

  @override
  String get menuMakePublic => 'Tornar pública';

  @override
  String get menuDelete => 'Excluir';

  @override
  String couldNotShare(String error) {
    return 'Não foi possível compartilhar: $error';
  }

  @override
  String get recipeNowPrivate => 'A receita agora é privada';

  @override
  String get recipeNowPublic => 'A receita agora é pública';

  @override
  String get deleteRecipeTitle => 'Excluir receita?';

  @override
  String get deleteRecipeBody => 'Não é possível desfazer.';

  @override
  String get editRecipeTitle => 'Editar receita';

  @override
  String get newRecipeTitle => 'Nova receita';

  @override
  String get fieldTitle => 'Título';

  @override
  String get titleRequired => 'O título é obrigatório';

  @override
  String get fieldDescriptionOptional => 'Descrição (opcional)';

  @override
  String get fieldIngredients => 'Ingredientes';

  @override
  String get helperOnePerLine => 'Um por linha';

  @override
  String get addAtLeastOneIngredient => 'Adicione pelo menos um ingrediente';

  @override
  String get addIngredient => 'Adicionar ingrediente';

  @override
  String get ingredientHint => 'ex. 2 xícaras de farinha';

  @override
  String get addIngredientGroup => 'Adicionar grupo de ingredientes';

  @override
  String get ingredientGroupNameHint => 'Nome do grupo (ex. Massa)';

  @override
  String get removeIngredientGroup => 'Remover grupo';

  @override
  String get fieldSteps => 'Etapas';

  @override
  String get addAtLeastOneStep => 'Adicione pelo menos uma etapa';

  @override
  String get addStep => 'Adicionar passo';

  @override
  String get stepHint => 'Descreva este passo';

  @override
  String get fieldSourceUrlOptional => 'URL de origem (opcional)';

  @override
  String get categoriesLabel => 'Categorias';

  @override
  String get fieldPublic => 'Pública';

  @override
  String get fieldPublicSubtitle => 'Compartilhar no feed Descobrir';

  @override
  String get recipeUpdated => 'Receita atualizada';

  @override
  String get recipeCreated => 'Receita criada';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get createRecipe => 'Criar receita';

  @override
  String get recipeLanguageLabel => 'Idioma';

  @override
  String get importTitle => 'Importar receita';

  @override
  String get importIntro =>
      'Cole um link de um site de receitas ou do TikTok. Vamos extrair os ingredientes e as etapas para você revisar e salvar.';

  @override
  String get importUrlLabel => 'URL da receita';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importPasteUrlError => 'Cole uma URL';

  @override
  String get importButton => 'Importar';

  @override
  String get importingButton => 'Importando…';

  @override
  String get importProgress => 'Buscando e analisando a página…';

  @override
  String get importOfflineError =>
      'Você está offline. Conecte-se à internet para importar uma receita de um link.';

  @override
  String get importNetworkError =>
      'Não foi possível acessar essa página. Verifique sua conexão e tente novamente.';

  @override
  String get importReadError =>
      'Não encontramos uma receita nessa página. Tente outro link.';

  @override
  String get offlineBannerEditing =>
      'Você está offline — suas alterações são salvas neste dispositivo e sincronizadas quando você reconectar.';

  @override
  String get categoriesTitle => 'Categorias';

  @override
  String get newCategoryButton => 'Nova categoria';

  @override
  String get categoriesEmpty =>
      'Ainda não há categorias.\nCrie uma para organizar suas receitas.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get deleteCategoryBody =>
      'As receitas mantêm o conteúdo; elas apenas perdem esta etiqueta.';

  @override
  String get editCategoryTitle => 'Editar categoria';

  @override
  String get newCategoryTitle => 'Nova categoria';

  @override
  String get fieldName => 'Nome';

  @override
  String get nameRequired => 'O nome é obrigatório';

  @override
  String get fieldColor => 'Cor';

  @override
  String get createCategory => 'Criar categoria';

  @override
  String get discoverTitle => 'Descobrir';

  @override
  String get surpriseMe => 'Surpreenda-me';

  @override
  String get discoverSearch => 'Buscar receitas públicas';

  @override
  String get discoverEmpty =>
      'Ainda não há receitas públicas.\nTorne uma das suas pública para compartilhá-la aqui.';

  @override
  String get recipeNotAvailable => 'Esta receita não está disponível.';

  @override
  String get menuReport => 'Denunciar';

  @override
  String get menuBlock => 'Bloquear / ocultar';

  @override
  String get copyToMyRecipes => 'Copiar para minhas receitas';

  @override
  String get copiedToRecipes => 'Copiada para suas receitas';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentYourNameOptional => 'Seu nome (opcional)';

  @override
  String get commentAddHint => 'Adicione um comentário…';

  @override
  String get commentPostAnonymously => 'Publicar anonimamente';

  @override
  String get commentPost => 'Publicar';

  @override
  String get commentPosting => 'Publicando…';

  @override
  String get commentsEmpty => 'Ainda não há comentários. Seja o primeiro!';

  @override
  String couldNotPost(String error) {
    return 'Não foi possível publicar: $error';
  }

  @override
  String get sharedRecipeTitle => 'Receita compartilhada';

  @override
  String get shareCodeNotFound =>
      'Esse código de compartilhamento não existe.\nConfira e tente novamente.';

  @override
  String recipeByAuthor(String author) {
    return 'por $author';
  }

  @override
  String get ingredientsTitle => 'Ingredientes';

  @override
  String get stepsTitle => 'Etapas';

  @override
  String get unitsLabel => 'Unidades';

  @override
  String get unitsAsWritten => 'Original';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get cookMode => 'Modo cozinha';

  @override
  String get cookModeOnHint => 'Texto maior, a tela permanece ligada';

  @override
  String recipeSource(String url) {
    return 'Fonte: $url';
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
      other: '$count etapas',
      one: '1 etapa',
    );
    return '$_temp0';
  }

  @override
  String ingredientsStepsSeparator(String ingredients, String steps) {
    return '$ingredients · $steps';
  }

  @override
  String moderationHidRecipe(String title) {
    return '“$title” ocultada';
  }

  @override
  String couldNotBlock(String error) {
    return 'Não foi possível bloquear: $error';
  }

  @override
  String get reportSubmitted => 'Obrigado — sua denúncia foi enviada';

  @override
  String couldNotReport(String error) {
    return 'Não foi possível denunciar: $error';
  }

  @override
  String get reportRecipeTitle => 'Denunciar receita';

  @override
  String reportWhy(String title) {
    return 'Por que você está denunciando “$title”?';
  }

  @override
  String get reportDetailsOptional => 'Detalhes (opcional)';

  @override
  String get reportReasonSpam => 'Spam ou enganoso';

  @override
  String get reportReasonInappropriate => 'Conteúdo inadequado';

  @override
  String get reportReasonOffensive => 'Ofensivo ou de ódio';

  @override
  String get reportReasonCopyright => 'Violação de direitos autorais';

  @override
  String get reportReasonOther => 'Outra coisa';
}
