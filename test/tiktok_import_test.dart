import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_the_crumbs_mobile/services/import/ai_recipe_parser.dart';
import 'package:just_the_crumbs_mobile/services/import/recipe_import_service.dart';

/// Records invocations and returns a canned response, standing in for the
/// production Gemini parser.
class _FakeAi {
  _FakeAi(this._respond);

  final AiParsedRecipe? Function(String input) _respond;
  int calls = 0;
  String? lastInput;

  Future<AiParsedRecipe?> call(String rawText) async {
    calls++;
    lastInput = rawText;
    return _respond(rawText);
  }
}

/// Wraps a TikTok video description in the hydration JSON script the parser
/// reads, optionally attaching subtitle tracks.
String _tiktokPage(
  String desc, {
  String creator = 'chef',
  List<Map<String, String>> subtitles = const [],
}) {
  final itemStruct = {
    'desc': desc,
    'author': {'uniqueId': creator},
    'video': {
      'subtitleInfos': [
        for (final s in subtitles)
          {
            'Url': s['url'],
            'Format': s['format'] ?? 'webvtt',
            'LanguageCodeName': s['lang'] ?? 'eng-US',
            'Source': s['source'] ?? 'MT',
          },
      ],
    },
  };
  final data = {
    '__DEFAULT_SCOPE__': {
      'webapp.video-detail': {
        'itemInfo': {'itemStruct': itemStruct},
      },
    },
  };
  return '''
<html><head>
<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">
${jsonEncode(data)}
</script></head><body></body></html>''';
}

/// Routes requests: the tiktok.com video url returns [page]; anything else
/// (subtitle CDN urls) returns [vtt].
http.Client _router(String page, {String vtt = ''}) =>
    MockClient((request) async {
      // Encode as UTF-8 bytes with a matching charset, mirroring a real
      // response so emoji round-trip instead of being mangled as latin1.
      final body = request.url.host.contains('tiktok.com') ? page : vtt;
      return http.Response.bytes(
        utf8.encode(body),
        200,
        headers: const {'content-type': 'text/html; charset=utf-8'},
      );
    });

void main() {
  group('TiktokImportService (via RecipeImportService)', () {
    test('parses a full recipe out of the description', () async {
      final desc = 'Creamy Tuscan Chicken 🍗\n'
          'Ingredients:\n'
          '- 4 chicken breasts\n'
          '- 1 cup heavy cream\n'
          '- 2 cups spinach\n'
          'Instructions:\n'
          '1. Season and sear the chicken until golden.\n'
          '2. Add the cream and spinach and simmer.\n'
          '#recipe #cooking';

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
      ).call();

      expect(result.title, 'Creamy Tuscan Chicken');
      expect(result.ingredients,
          ['4 chicken breasts', '1 cup heavy cream', '2 cups spinach']);
      expect(result.steps.length, 2);
      expect(result.steps.first, 'Season and sear the chicken until golden.');
      // Hashtags stripped, steps end with punctuation.
      expect(result.ingredients.any((i) => i.contains('#')), isFalse);
    });

    test('segments a single-line description via inline headers', () async {
      final desc = 'Easy Fried Rice Ingredients: 2 cups rice, 3 eggs, '
          '1 cup peas Instructions: 1. Fry the rice. 2. Scramble the eggs in.';

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
      ).call();

      expect(result.title, 'Easy Fried Rice');
      expect(result.ingredients, ['2 cups rice', '3 eggs', '1 cup peas']);
      expect(result.steps.length, 2);
    });

    test('falls back to subtitles when the description has no recipe',
        () async {
      const desc = 'the BEST dinner 😍 follow for more! #fyp #foodtok';
      const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:02.000
today we're making pasta.

00:00:02.000 --> 00:00:04.000
today we're making pasta.

00:00:04.000 --> 00:00:07.000
add two cups of flour to a bowl.

00:00:07.000 --> 00:00:10.000
boil the pasta for ten minutes.
''';

      final page = _tiktokPage(
        desc,
        subtitles: [
          {'url': 'https://v16.tiktokcdn.com/captions.vtt'},
        ],
      );

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(page, vtt: vtt),
      ).call();

      // Title still comes from the caption.
      expect(result.title, isNotEmpty);
      // Ingredient pulled out of the spoken words.
      expect(
          result.ingredients.any((i) => i.toLowerCase().contains('flour')),
          isTrue);
      // Steps come from the transcript, de-duplicated and punctuated.
      expect(result.steps, isNotEmpty);
      expect(result.steps.where((s) => s.contains('making pasta')).length, 1);
      expect(result.steps.every((s) => RegExp(r'[.!?]$').hasMatch(s)), isTrue);
    });

    test('never throws; degrades to a watch-the-video step', () async {
      const desc = 'just vibes ✨ #foodtok';
      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
      ).call();

      expect(result.steps.length, 1);
      expect(result.steps.first.toLowerCase(), contains('watch the video'));
    });
  });

  group('TiktokImportService AI fallback', () {
    test('uses the AI parser when heuristics come up empty', () async {
      const desc = 'the BEST dinner 😍 follow for more! #fyp #foodtok';
      final fake = _FakeAi((_) => const AiParsedRecipe(
            title: 'Garlic Butter Shrimp',
            ingredients: ['1 lb shrimp', '4 tbsp butter', '3 cloves garlic'],
            steps: ['Melt the butter', 'Add garlic and shrimp', 'Cook 3 minutes'],
          ));

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
        aiParser: fake.call,
      ).call();

      expect(fake.calls, 1);
      expect(result.title, 'Garlic Butter Shrimp');
      expect(result.ingredients.length, 3);
      // AI output is run through the same formatter (steps get punctuation).
      expect(result.steps.first, 'Melt the butter.');
      expect(result.steps.length, 3);
    });

    test('does NOT call the AI when the description is already a full recipe',
        () async {
      final desc = 'Creamy Tuscan Chicken\n'
          'Ingredients:\n- 4 chicken breasts\n- 1 cup heavy cream\n'
          'Instructions:\n1. Sear the chicken until golden.\n'
          '2. Add cream and simmer.';
      final fake = _FakeAi((_) => throw StateError('should not be called'));

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
        aiParser: fake.call,
      ).call();

      expect(fake.calls, 0);
      expect(result.ingredients.length, 2);
      expect(result.steps.length, 2);
    });

    test('feeds the AI both the caption and the transcript', () async {
      const desc = 'dinner idea 🍤 #foodtok';
      const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:02.000
melt some butter in a pan
''';
      final fake = _FakeAi((_) => null); // can't help — forces graceful path

      await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(
          _tiktokPage(desc, subtitles: [
            {'url': 'https://v16.tiktokcdn.com/captions.vtt'},
          ]),
          vtt: vtt,
        ),
        aiParser: fake.call,
      ).call();

      expect(fake.calls, 1);
      expect(fake.lastInput, contains('dinner idea'));
      expect(fake.lastInput, contains('melt some butter'));
    });

    test('degrades gracefully when the AI returns null', () async {
      const desc = 'just vibes ✨ #foodtok';
      final fake = _FakeAi((_) => null);

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
        aiParser: fake.call,
      ).call();

      expect(fake.calls, 1);
      expect(result.steps.first.toLowerCase(), contains('watch the video'));
    });
  });
}
