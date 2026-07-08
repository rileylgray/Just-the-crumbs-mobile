import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'ai_recipe_parser.dart';
import 'tiktok_import_service.dart';

/// The parsed result of importing a recipe from a URL.
class ImportedRecipe {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final String sourceUrl;

  const ImportedRecipe({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.sourceUrl,
  });
}

/// Dart port of the Rails `RecipeImportService`. Fetches a recipe page and
/// extracts title/ingredients/steps, preferring Schema.org JSON-LD and falling
/// back through the same heuristic ladder as the original scraper. Runs fully
/// client-side (no CORS restriction on mobile).
class RecipeImportService {
  RecipeImportService(this.url, {http.Client? client, AiRecipeParser? aiParser})
      : _client = client ?? http.Client(),
        _aiParser = aiParser;

  final String url;
  final http.Client _client;
  final AiRecipeParser? _aiParser;
  late Document _doc;

  Future<ImportedRecipe> call() async {
    if (_isTikTok) {
      return TiktokImportService(url, client: _client, aiParser: _aiParser)
          .call();
    }

    late http.Response response;
    try {
      response = await _client.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      throw 'Error importing recipe: $e';
    }

    _doc = html_parser.parse(response.body);

    // Extract BEFORE stripping scripts (Schema.org lives in <script>).
    final title = _extractTitle();
    final ingredients = _extractIngredients();
    final steps = _extractSteps();

    if (ingredients.isEmpty) throw 'Could not extract ingredients from URL';
    if (steps.isEmpty) throw 'Could not extract steps from URL';

    return ImportedRecipe(
      title: title,
      ingredients: ingredients,
      steps: steps,
      sourceUrl: url,
    );
  }

  bool get _isTikTok => RegExp(r'tiktok\.com', caseSensitive: false).hasMatch(url);

  // ---- Title ---------------------------------------------------------------

  String _extractTitle() {
    String? title;
    title ??= _doc.querySelector("h1[class*='recipe']")?.text.trim();
    title ??= _doc.querySelector("[class*='recipe-title']")?.text.trim();
    title ??= _doc
        .querySelector("meta[property='og:title']")
        ?.attributes['content']
        ?.trim();
    title ??= _doc.querySelector('title')?.text.trim();

    if (title != null && title.contains('|')) {
      title = title.split('|').first.trim();
    }
    return (title == null || title.isEmpty) ? 'Recipe from $url' : title;
  }

  // ---- Ingredients ---------------------------------------------------------

  List<String> _extractIngredients() {
    // Priority 0: Simply Recipes structured ingredients.
    final simply = _doc
        .querySelectorAll('.structured-ingredients__list-item')
        .map((e) => _clean(e.text))
        .where(_reasonable)
        .toList();
    if (simply.isNotEmpty) return simply;

    // Priority 1: grouped HTML (AllRecipes etc.).
    final grouped = _groupedIngredientsFromHtml();
    if (grouped.isNotEmpty) return grouped;

    final genericGrouped = _groupedIngredientsGeneric();
    if (genericGrouped.isNotEmpty) return genericGrouped;

    // Priority 2: Schema.org.
    final schema = _ingredientsFromSchemaOrg();
    if (schema.isNotEmpty) return schema;

    // Priority 3a: single-element plugin ingredients.
    for (final pattern in const [
      '.wprm-recipe-ingredient',
      '.aioseo-recipe-ingredient',
      '.tasty-recipes-ingredient',
    ]) {
      final els = _doc.querySelectorAll(pattern);
      if (els.length >= 2) {
        final candidates =
            els.map((e) => _clean(e.text)).where(_reasonable).toList();
        if (candidates.length >= 2) return candidates;
      }
    }

    // Priority 3b: ingredient container lists.
    for (final pattern in const [
      "[class*='ingredient'] ul",
      "[class*='ingredient'] ol",
      "[class*='ingredients'] ul",
      "[class*='ingredients'] ol",
      "ul[class*='ingredient']",
      "ol[class*='ingredient']",
      "[data-cy='ingredients-list'] li",
      '.tasty-recipes-ingredients li',
    ]) {
      final list = _doc.querySelector(pattern);
      if (list != null) {
        final candidates = list
            .querySelectorAll('li')
            .map((e) => _clean(e.text))
            .where(_reasonable)
            .toList();
        if (candidates.length >= 2) return candidates;
      }
    }

    // Priority 4: any list that looks like ingredients.
    for (final list in _doc.querySelectorAll('ul, ol')) {
      if (_ingredientKeywords(list.text.toLowerCase())) {
        final candidates = list
            .querySelectorAll('li')
            .map((e) => _clean(e.text))
            .where(_reasonable)
            .toList();
        if (candidates.length >= 2) return candidates;
      }
    }
    return const [];
  }

  List<String> _groupedIngredientsFromHtml() {
    final grouped = <String>[];
    for (final heading
        in _doc.querySelectorAll('.mm-recipes-structured-ingredients__list-heading')) {
      final groupName = heading.text.trim();
      final list = _followingList(heading);
      if (list == null) continue;
      for (final li in list.querySelectorAll('li')) {
        final text = _clean(li.text);
        if (text.isNotEmpty) grouped.add('$groupName — $text');
      }
    }
    return grouped;
  }

  List<String> _groupedIngredientsGeneric() {
    final grouped = <String>[];

    // WPRM plugin structure.
    for (final group in _doc.querySelectorAll('.wprm-recipe-ingredient-group')) {
      final heading =
          group.querySelector('h3, h4, .wprm-recipe-group-name');
      final groupName = heading?.text.trim().replaceAll(RegExp(r':$'), '');
      for (final li in group.querySelectorAll('li')) {
        final text = _clean(li.text);
        if (text.isEmpty) continue;
        grouped.add(
            (groupName != null && groupName.isNotEmpty) ? '$groupName — $text' : text);
      }
    }
    if (grouped.isNotEmpty) return grouped;

    // Heading-based fallback.
    final ingredientsHeading = _doc.querySelectorAll('h2, h3, h4').where((h) {
      final cls = h.attributes['class'] ?? '';
      return !cls.contains('wp-block-heading') &&
          h.text.trim().toLowerCase().contains('ingredients');
    }).firstOrNull;
    if (ingredientsHeading == null) return grouped;

    const stopHeadings = ['instructions', 'directions', 'method', 'steps'];

    final mainList = _followingList(ingredientsHeading);
    if (mainList != null) {
      for (final li in mainList.querySelectorAll('li')) {
        final text = _clean(li.text);
        if (text.isNotEmpty) grouped.add(text);
      }
    }

    final container = ingredientsHeading.parent ?? _doc.documentElement;
    for (final heading in container?.querySelectorAll('h3, h4') ?? const []) {
      final headingText = heading.text.trim();
      if (headingText.isEmpty || headingText.toLowerCase().contains('ingredients')) {
        continue;
      }
      if (stopHeadings.any((w) => headingText.toLowerCase().contains(w))) break;
      final list = _followingList(heading);
      if (list == null) continue;
      for (final li in list.querySelectorAll('li')) {
        final text = _clean(li.text);
        if (text.isNotEmpty) grouped.add('$headingText — $text');
      }
    }
    return grouped;
  }

  List<String> _ingredientsFromSchemaOrg() {
    for (final obj in _schemaObjects()) {
      final types = _types(obj);
      if (types.contains('recipe') && obj['recipeIngredient'] is List) {
        return (obj['recipeIngredient'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  // ---- Steps ---------------------------------------------------------------

  List<String> _extractSteps() {
    final schema = _stepsFromSchemaOrg();
    if (schema.isNotEmpty) return schema;

    // Plugin patterns.
    for (final pattern in const [
      '.wprm-recipe-instruction',
      '.wprm-recipe-instructions li',
      '.aioseo-recipe-instructions li',
      '.tasty-recipes-instructions li',
      "[class*='recipe-instruction']",
    ]) {
      final els = _doc.querySelectorAll(pattern);
      if (els.length >= 2 && els.length <= 15) {
        final steps = <String>[];
        for (final el in els) {
          final textEl = el.querySelector('.wprm-recipe-instruction-text');
          final text = _clean(textEl?.text ?? el.text);
          if (text.length > 10 && text.length < 2000) steps.add(text);
        }
        if (steps.isNotEmpty) return steps;
      }
    }

    // Ordered-list patterns.
    for (final pattern in const [
      "[class*='instruction'] ol",
      "[class*='instructions'] ol",
      "[class*='directions'] ol",
      "[class*='steps'] ol",
      "ol[class*='steps']",
      "ol[class*='instruction']",
    ]) {
      final list = _doc.querySelector(pattern);
      if (list != null) {
        final steps = _stepsFromListItems(list);
        if (steps.isNotEmpty) return steps;
      }
    }

    // Keyword-based lists (4–15 items, pick the shortest).
    final candidates = <Element>[];
    for (final list in _doc.querySelectorAll('ol, ul')) {
      final count = list.querySelectorAll('li').length;
      if (_stepKeywords(list.text.toLowerCase()) && count >= 4 && count <= 15) {
        candidates.add(list);
      }
    }
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.text.length.compareTo(b.text.length));
      return _stepsFromListItems(candidates.first);
    }
    return const [];
  }

  List<String> _stepsFromSchemaOrg() {
    for (final obj in _schemaObjects()) {
      if (!_types(obj).contains('recipe')) continue;
      final instructions = obj['recipeInstructions'];
      if (instructions is List && instructions.isNotEmpty) {
        final steps = _flattenInstructions(instructions);
        if (steps.isNotEmpty) return steps;
      } else if (instructions is String && instructions.trim().isNotEmpty) {
        final steps = instructions
            .split(RegExp(r'\r?\n'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (steps.isNotEmpty) return steps;
      }
    }
    return const [];
  }

  List<String> _flattenInstructions(List instructions) {
    final steps = <String>[];
    for (final item in instructions) {
      if (item is Map) {
        final type = (item['@type'] ?? '').toString().toLowerCase();
        if (type == 'howtosection' && item['itemListElement'] is List) {
          steps.addAll(_flattenInstructions(item['itemListElement'] as List));
        } else {
          final text = (item['text'] ?? item['description'] ?? '').toString().trim();
          if (text.isNotEmpty) steps.add(text);
        }
      } else {
        final text = item.toString().trim();
        if (text.isNotEmpty) steps.add(text);
      }
    }
    return steps;
  }

  List<String> _stepsFromListItems(Element list) {
    final steps = <String>[];
    for (final li in list.querySelectorAll('li')) {
      for (final junk
          in li.querySelectorAll('img, figure, figcaption, script, style, svg')) {
        junk.remove();
      }
      final text = _clean(li.text);
      if (text.length > 10 && text.length < 2000) steps.add(text);
    }
    return steps;
  }

  // ---- Shared helpers ------------------------------------------------------

  /// All JSON-LD objects on the page, with `@graph` wrappers flattened.
  List<Map<String, dynamic>> _schemaObjects() {
    final result = <Map<String, dynamic>>[];
    for (final script
        in _doc.querySelectorAll('script[type="application/ld+json"]')) {
      dynamic data;
      try {
        data = jsonDecode(script.text);
      } catch (_) {
        continue;
      }
      final items = <dynamic>[];
      if (data is List) {
        items.addAll(data);
      } else {
        items.add(data);
      }
      for (final item in List.of(items)) {
        if (item is Map && item['@graph'] is List) {
          items.addAll(item['@graph'] as List);
        }
      }
      for (final item in items) {
        if (item is Map) result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  List<String> _types(Map<String, dynamic> obj) {
    final t = obj['@type'];
    if (t is List) return t.map((e) => e.toString().toLowerCase()).toList();
    if (t is String) return [t.toLowerCase()];
    return const [];
  }

  /// First `ul`/`ol` among the element's following siblings (mirrors the Ruby
  /// `following-sibling::*` xpath).
  Element? _followingList(Element element) {
    final parent = element.parent;
    if (parent == null) return null;
    final siblings = parent.children;
    final idx = siblings.indexOf(element);
    if (idx < 0) return null;
    for (var i = idx + 1; i < siblings.length; i++) {
      final name = siblings[i].localName;
      if (name == 'ul' || name == 'ol') return siblings[i];
    }
    return null;
  }

  bool _reasonable(String text) => text.length > 3 && text.length < 500;

  bool _ingredientKeywords(String text) {
    const keywords = [
      'cup', 'tbsp', 'tsp', 'oz', 'lb', 'gram', 'kg', 'ml',
      'salt', 'sugar', 'flour', 'butter', 'egg',
    ];
    return keywords.any(text.contains);
  }

  bool _stepKeywords(String text) {
    const keywords = [
      'mix', 'combine', 'heat', 'cook', 'bake', 'add', 'stir',
      'pour', 'blend', 'whisk', 'season', 'serve', 'roast',
    ];
    return keywords.any(text.contains);
  }

  static final _bulletPrefix = RegExp(
      r'^\s*[▢☐☑▫▪•‣◦⁃∙●○•·‣⁃◦▪▫▸▹▶▷►◅◆◇○●\-\*\+]+\s*');
  static final _whitespace = RegExp(r'\s+');

  String _clean(String text) {
    return text
        .replaceAll(_bulletPrefix, '')
        .replaceAll(_whitespace, ' ')
        .trim();
  }
}
