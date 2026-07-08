import 'dart:collection';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../config.dart';

/// A recipe parsed out of messy text by the AI fallback.
class AiParsedRecipe {
  const AiParsedRecipe({
    required this.title,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final List<String> ingredients;
  final List<String> steps;
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

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: AiConfig.model,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'title': Schema.string(),
              'ingredients': Schema.array(items: Schema.string()),
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

      final parsed = AiParsedRecipe(
        title: (decoded['title'] ?? '').toString().trim(),
        ingredients: _stringList(decoded['ingredients']),
        steps: _stringList(decoded['steps']),
      );

      // A "no recipe here" answer is as good as no answer to the caller.
      if (parsed.ingredients.isEmpty && parsed.steps.isEmpty) return null;

      _remember(key, parsed);
      return parsed;
    } catch (_) {
      // Network error, quota exhausted, malformed JSON, safety block, etc.
      // The caller keeps its heuristic result, so degrade silently.
      return null;
    }
  }

  void _remember(String key, AiParsedRecipe recipe) {
    _cache[key] = recipe;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
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
      'Return: a short recipe title; the ingredients as a flat list with one '
      'ingredient per entry, including quantities and units when stated; and '
      'the preparation steps as an ordered list, one action per entry.\n'
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
