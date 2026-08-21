import 'dart:collection';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../config.dart';
import '../../models/recipe.dart';

/// A recipe parsed out of messy text by the AI fallback.
class AiParsedRecipe {
  /// A recipe whose ingredients are one plain list.
  AiParsedRecipe({
    required this.title,
    required List<String> ingredients,
    required this.steps,
  }) : ingredientGroups = [IngredientGroup(items: ingredients)];

  /// A recipe the model split into named parts ("For the sauce").
  const AiParsedRecipe.grouped({
    required this.title,
    required this.ingredientGroups,
    required this.steps,
  });

  final String title;

  /// The ingredients as the model grouped them. A recipe with no named parts
  /// holds a single untitled group.
  final List<IngredientGroup> ingredientGroups;
  final List<String> steps;

  /// Every ingredient, groups flattened in order.
  List<String> get ingredients =>
      [for (final g in ingredientGroups) ...g.items];
}

/// Signature for the AI parse step. Takes the best raw text we have for a video
/// (caption + transcript) and returns a structured recipe, or `null` if it
/// couldn't help. Injected so importers can be unit-tested with a fake and the
/// production Gemini implementation can be swapped or disabled.
typedef AiRecipeParser = Future<AiParsedRecipe?> Function(String rawText);

/// Production [AiRecipeParser]: calls Gemini via Firebase AI Logic with a
/// structured-output schema. Gated by [AiConfig.importAssistEnabled], caches by
/// input text to avoid duplicate calls, and returns `null` on *any* failure so
/// the caller can fall back to its heuristic result. See [AiConfig] for the
/// free-tier rationale.
class GeminiRecipeParser {
  const GeminiRecipeParser();

  /// Small session cache so retrying the same import (same caption/transcript)
  /// never spends a second request. Bounded to keep memory flat.
  static final LinkedHashMap<String, AiParsedRecipe> _cache = LinkedHashMap();
  static const int _cacheLimit = 50;

  /// One retry for a failed request. An import that reaches this parser has
  /// already come up short on heuristics, so losing the call means the recipe
  /// degrades to "watch the video" — worth a second attempt when the first
  /// throws. A cold start is where this bites: the request races app launch,
  /// with the Firebase auth token the SDK attaches, DNS and TLS all still
  /// settling. A model that simply had nothing to say is not retried.
  static const int _maxAttempts = 2;
  static const Duration _retryDelay = Duration(milliseconds: 600);

  Future<AiParsedRecipe?> call(String rawText) async {
    if (!AiConfig.importAssistEnabled) return null;
    // Needs an initialized Firebase app; absent in unit tests, so bail quietly.
    if (Firebase.apps.isEmpty) return null;

    final text = rawText.trim();
    if (text.length < 20) return null; // nothing worth spending a call on

    final key = text.length > AiConfig.maxInputChars
        ? text.substring(0, AiConfig.maxInputChars)
        : text;
    final cached = _cache[key];
    if (cached != null) return cached;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final parsed = await _generate(key);
        if (parsed == null) return null;
        _remember(key, parsed);
        return parsed;
      } catch (error) {
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        // Network error, quota exhausted, malformed JSON, safety block, etc.
        // The caller keeps its heuristic result, so degrade silently — but say
        // so in the log, because from the outside a silent degrade and a
        // working parse are both just "the recipe came out thin".
        debugPrint('AI recipe parse failed: $error');
      }
    }
    return null;
  }

  /// One request to the model. Returns `null` when the model answered with
  /// nothing usable; throws when the request itself failed.
  Future<AiParsedRecipe?> _generate(String key) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.model,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'title': Schema.string(),
            'ingredientGroups': Schema.array(
              items: Schema.object(
                properties: {
                  'title': Schema.string(),
                  'items': Schema.array(items: Schema.string()),
                },
              ),
            ),
            'steps': Schema.array(items: Schema.string()),
          },
        ),
      ),
    );

    final response = await model
        .generateContent([Content.text(key)]).timeout(
            const Duration(seconds: 20));

    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;

    final parsed = AiParsedRecipe.grouped(
      title: (decoded['title'] ?? '').toString().trim(),
      ingredientGroups: _groups(decoded),
      steps: _stringList(decoded['steps']),
    );

    // A "no recipe here" answer is as good as no answer to the caller.
    if (parsed.ingredients.isEmpty && parsed.steps.isEmpty) return null;

    return parsed;
  }

  void _remember(String key, AiParsedRecipe recipe) {
    _cache[key] = recipe;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Reads the model's `ingredientGroups`, tolerating a flat `ingredients`
  /// array instead (older cached responses, or a model that ignored the
  /// schema). Empty groups are dropped so a stray heading can't render as one.
  static List<IngredientGroup> _groups(Map decoded) {
    final raw = decoded['ingredientGroups'];
    if (raw is List) {
      final groups = <IngredientGroup>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final items = _stringList(entry['items']);
        if (items.isEmpty) continue;
        groups.add(IngredientGroup(
          title: (entry['title'] ?? '').toString().trim(),
          items: items,
        ));
      }
      if (groups.isNotEmpty) return groups;
    }
    return [IngredientGroup(items: _stringList(decoded['ingredients']))];
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static const _systemPrompt =
      'You extract a single cooking recipe from messy social-media text — a '
      "TikTok caption and/or an auto-generated (often unpunctuated) transcript "
      'of the spoken video.\n'
      'Return: a short recipe title; the ingredients, one per entry, including '
      'quantities and units when stated; and the preparation steps as an '
      'ordered list, one action per entry.\n'
      'Group the ingredients only when the text itself names parts ("for the '
      'sauce", "for the marinade"): then return one group per part, titled '
      'with that part\'s name (without the leading "for the"). Otherwise '
      'return a single group with an empty title. Never emit a group title '
      'the text does not state, and never repeat an ingredient across '
      'groups.\n'
      'Strip hashtags, @mentions, emojis, promotional lines and calls to '
      'action ("follow for more", "link in bio"). Do NOT number the steps '
      'yourself — the app numbers them. Do NOT invent ingredients or steps that '
      'the text does not support. If the text is not a recipe, return empty '
      'arrays for ingredients and steps.';
}

/// Default parser used by importers in production. A thin function wrapper so
/// the [AiRecipeParser] typedef can be satisfied directly.
Future<AiParsedRecipe?> defaultAiRecipeParser(String rawText) =>
    const GeminiRecipeParser().call(rawText);
