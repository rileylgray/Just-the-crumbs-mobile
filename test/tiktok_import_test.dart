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

    test('segments a run-on paragraph description into steps', () async {
      // A real caption pasted as one long, barely-punctuated block: an intro
      // hook, the recipe, then an outro shout-out.
      const desc =
          "the best recipe of the year we finally made it for the last time "
          "I'm cooking the top 50 New York Times recipes of 2025 this is "
          "smashed beef kabobs for the sauce yogurt grated cucumber chopped "
          "mint and grated garlic mix well and let it chill to another bowl "
          "add in beef grated onion turmeric salt and lots of black pepper and "
          "mix again get a cast iron pan ripping hot and add in your beef "
          "mixture piece by piece this lets it get nice and crispy once it can "
          "release naturally break it all up and add in walnuts and cranberries "
          "then let everything finish cooking add some salt to the yogurt from "
          "earlier and shout out to Zaynab ISA for this amazing recipe.";

      // No AI needed — the heuristic segmenter should carry this.
      final fake = _FakeAi((_) => null);
      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
        aiParser: fake.call,
      ).call();

      // Broken into several steps rather than one giant blob.
      expect(result.steps.length, greaterThan(3));
      // Intro hook and outro call-to-action are gone.
      expect(
          result.steps.any((s) => s.toLowerCase().contains('recipe of the year')),
          isFalse);
      expect(result.steps.any((s) => s.toLowerCase().contains('shout out')),
          isFalse);
      // The real cooking actions survive.
      expect(result.steps.any((s) => s.toLowerCase().contains('for the sauce')),
          isTrue);
      expect(
          result.steps.any((s) => s.toLowerCase().contains('cast iron pan')),
          isTrue);
      // Best-effort dish name pulled from "this is …".
      expect(result.title, 'Smashed beef kabobs');
    });

    test('routes a trailing "Other ingredients" section to ingredients',
        () async {
      // A secondary ingredient header after the steps used to be swallowed by
      // the steps region (which ran to the end of the description).
      final desc = 'Loaded Nachos\n'
          'Ingredients:\n'
          '- 1 bag tortilla chips\n'
          '- 2 cups cheddar\n'
          'Instructions:\n'
          '1. Spread the chips on a tray.\n'
          '2. Bake until the cheese melts.\n'
          'Other ingredients:\n'
          '- 1 cup salsa\n'
          '- 1 avocado';

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(_tiktokPage(desc)),
      ).call();

      expect(result.ingredients.any((i) => i.toLowerCase().contains('salsa')),
          isTrue);
      expect(result.ingredients.any((i) => i.toLowerCase().contains('avocado')),
          isTrue);
      // The secondary-section items must not leak into the steps.
      expect(result.steps.any((s) => s.toLowerCase().contains('salsa')),
          isFalse);
      expect(result.steps.length, 2);
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

    test('prefers the AI over noisy transcript heuristics', () async {
      // A chatty spoken transcript: the heuristics mine plenty of junk from it
      // ("a cup because that", "what's next?"), so the AI's clean parse should
      // win even though the heuristics produced *some* output.
      const desc = 'black bean brownies 🍫 #healthy';
      const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:05.000
we're gonna make some black bean brownies these are healthy and delicious.

00:00:05.000 --> 00:00:09.000
one full cup drained and rinsed of black beans a cup because that's plenty.

00:00:09.000 --> 00:00:12.000
half a cup of oats going in what's next?
''';

      final fake = _FakeAi((_) => const AiParsedRecipe(
            title: 'Black Bean Brownies',
            ingredients: [
              '1 can black beans, drained',
              '1/2 cup oats',
              '1/4 cup cocoa',
            ],
            steps: ['Blend the black beans', 'Add the oats and cocoa'],
          ));

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(
          _tiktokPage(desc, subtitles: [
            {'url': 'https://v16.tiktokcdn.com/captions.vtt'},
          ]),
          vtt: vtt,
        ),
        aiParser: fake.call,
      ).call();

      // The AI ran and its clean output replaced the junk heuristic parse.
      expect(fake.calls, 1);
      expect(result.title, 'Black Bean Brownies');
      expect(result.ingredients.length, 3);
      expect(result.ingredients.any((i) => i.toLowerCase().contains('oats')),
          isTrue);
      // No mis-detected "a cup because…" fragments survive.
      expect(result.ingredients.any((i) => i.toLowerCase().contains('because')),
          isFalse);
      expect(result.steps.length, 2);
      expect(result.steps.first, 'Blend the black beans.');
    });

    test('a placeholder step does not suppress the transcript/AI fallback',
        () async {
      // Real ingredients in the caption but only a "watch the video" stub for
      // the method — the actual steps are spoken. The stub must not make the
      // description look complete and block the transcript.
      final desc = 'Garlic Butter Steak\n'
          'Ingredients:\n'
          '- 2 ribeye steaks\n'
          '- 4 tbsp butter\n'
          '- 3 cloves garlic\n'
          'Instructions:\n'
          'Watch the full video for the steps!';
      const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:03.000
season the steaks generously with salt.

00:00:03.000 --> 00:00:06.000
sear them in a hot pan for three minutes each side.

00:00:06.000 --> 00:00:09.000
add the butter and garlic and baste the steaks.
''';
      final fake = _FakeAi((_) => null); // heuristic transcript parse carries it

      final result = await RecipeImportService(
        'https://www.tiktok.com/@chef/video/123',
        client: _router(
          _tiktokPage(desc, subtitles: [
            {'url': 'https://v16.tiktokcdn.com/captions.vtt'},
          ]),
          vtt: vtt,
        ),
        aiParser: fake.call,
      ).call();

      // The transcript was consulted and its real steps imported.
      expect(fake.calls, 1);
      expect(result.ingredients.length, 3);
      expect(result.steps.any((s) => s.toLowerCase().contains('sear')), isTrue);
      // The "watch the video" placeholder is gone.
      expect(result.steps.any((s) => s.toLowerCase().contains('watch the')),
          isFalse);
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
