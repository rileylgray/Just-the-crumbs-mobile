import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../config.dart';
import 'ai_recipe_parser.dart';
import 'recipe_import_service.dart';

/// Dart port of the Rails `TiktokImportService`. TikTok pages don't carry
/// Schema.org recipe data, so we pull the recipe from two places, in order:
///
/// 1. The video **description** (from the embedded hydration JSON, or the
///    `og:description` meta as a fallback). Many creators paste a full recipe —
///    a title, an `Ingredients:` list and numbered steps — right into it.
/// 2. The video **subtitles/captions** (a WebVTT transcript linked from the
///    hydration JSON). When the description is just a caption, we fetch the
///    transcript and heuristically pull ingredients and steps out of the
///    spoken words.
///
/// Whatever we find is cleaned up (bullets, emoji, hashtags and numbering are
/// stripped; lines are capitalised and de-duplicated) so the imported recipe
/// lands in the form nicely formatted.
class TiktokImportService {
  TiktokImportService(
    this.url, {
    http.Client? client,
    AiRecipeParser? aiParser,
  })  : _client = client ?? http.Client(),
        _aiParser = aiParser ?? defaultAiRecipeParser;

  final String url;
  final http.Client _client;

  /// Fallback parser used only when the heuristics come up short. Injectable
  /// for tests; defaults to the production Gemini parser (which itself no-ops
  /// when disabled or unavailable).
  final AiRecipeParser _aiParser;

  Future<ImportedRecipe> call() async {
    late http.Response response;
    try {
      response = await _client.get(
        Uri.parse(url),
        headers: const {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      throw 'Error importing TikTok recipe: $e';
    }

    final doc = html_parser.parse(response.body);
    final meta = _extractMetadata(doc);

    // 1. Try the description first.
    final fromDesc = _parseFromDescription(meta.description, meta.creator);
    var title = fromDesc.title;
    var ingredients = fromDesc.ingredients;
    var steps = fromDesc.steps;

    // 2. Fall back to the subtitles for anything the description didn't provide.
    String? transcript;
    if (_isWeak(ingredients, steps) && meta.subtitleUrls.isNotEmpty) {
      transcript = await _fetchTranscript(meta.subtitleUrls);
      if (transcript != null) {
        final fromSubs = _parseFromTranscript(transcript);
        if (ingredients.length < 2 &&
            fromSubs.ingredients.length > ingredients.length) {
          ingredients = fromSubs.ingredients;
        }
        if (steps.isEmpty && fromSubs.steps.isNotEmpty) {
          steps = fromSubs.steps;
        }
      }
    }

    // 3. Last resort: let the AI untangle the raw caption + transcript. Only
    //    runs when the heuristics still fell short, so most imports never reach
    //    it (keeping call volume inside the free tier). Degrades silently.
    if (_isWeak(ingredients, steps)) {
      // Whether the heuristics found a real recipe (vs. just a caption-derived
      // title guess) decides if the AI's title should override.
      final hadRealContent = ingredients.length >= 2 || steps.isNotEmpty;
      final ai = await _aiParser(_rawForAi(meta.description, transcript));
      if (ai != null) {
        if ((_isFallbackTitle(title) || !hadRealContent) &&
            ai.title.isNotEmpty) {
          title = _capitalize(_baseClean(ai.title));
        }
        if (ingredients.length < 2 && ai.ingredients.length >= 2) {
          ingredients = _finalizeIngredients(ai.ingredients);
        }
        if (steps.isEmpty && ai.steps.isNotEmpty) {
          steps = _finalizeSteps(ai.steps);
        }
      }
    }

    // A single run-on block (a whole transcript that landed as one step) gets
    // carved into individual steps here regardless of which source produced it.
    steps = _resegmentLongSteps(steps);

    if (steps.isEmpty) {
      steps = const ['Watch the video for the full instructions.'];
    }

    return ImportedRecipe(
      title: title,
      ingredients: ingredients,
      steps: steps,
      sourceUrl: url,
    );
  }

  bool _isWeak(List<String> ingredients, List<String> steps) =>
      ingredients.length < 2 || steps.isEmpty;

  bool _isFallbackTitle(String title) => title.startsWith('Recipe by ');

  /// Combines the caption and transcript into a single, size-capped block of
  /// text for the AI, so token use (and cost) stays tiny.
  String _rawForAi(String? description, String? transcript) {
    final buffer = StringBuffer();
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) {
      buffer.writeln('Caption:');
      buffer.writeln(desc);
    }
    final t = transcript?.trim();
    if (t != null && t.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('Transcript:');
      buffer.writeln(t);
    }
    final text = buffer.toString().trim();
    return text.length > AiConfig.maxInputChars
        ? text.substring(0, AiConfig.maxInputChars)
        : text;
  }

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36';

  // ---- Metadata extraction -------------------------------------------------

  _TiktokMeta _extractMetadata(dynamic doc) {
    String? creator;
    String? description;
    final subtitleUrls = <String>[];

    final script =
        doc.querySelector('script[id="__UNIVERSAL_DATA_FOR_REHYDRATION__"]');
    if (script != null) {
      try {
        final data = jsonDecode(script.text) as Map<String, dynamic>;
        final itemStruct = _dig(data, [
          '__DEFAULT_SCOPE__',
          'webapp.video-detail',
          'itemInfo',
          'itemStruct',
        ]);
        if (itemStruct is Map) {
          description = itemStruct['desc'] as String?;
          final author = itemStruct['author'];
          if (author is Map) {
            creator = (author['uniqueId'] ?? author['nickname']) as String?;
          }
          subtitleUrls.addAll(_subtitleUrls(itemStruct['video']));
        }
      } catch (_) {
        // Fall through to meta tag.
      }
    }

    if (description == null || description.trim().isEmpty) {
      description = doc
          .querySelector('meta[property="og:description"]')
          ?.attributes['content'] as String?;
    }

    return _TiktokMeta(creator, description, subtitleUrls);
  }

  /// Collects subtitle/caption VTT urls from the video node, ranked so that
  /// English, human-written (non-ASR) WebVTT tracks are tried first.
  List<String> _subtitleUrls(dynamic video) {
    if (video is! Map) return const [];
    final infos = video['subtitleInfos'];
    if (infos is! List) return const [];

    final ranked = <(int, String)>[];
    for (final info in infos) {
      if (info is! Map) continue;
      final urlValue = (info['Url'] ?? info['url'] ?? '').toString();
      if (urlValue.isEmpty) continue;
      final format = (info['Format'] ?? '').toString().toLowerCase();
      if (format.isNotEmpty && !format.contains('webvtt')) continue;

      final lang = (info['LanguageCodeName'] ?? info['LanguageID'] ?? '')
          .toString()
          .toLowerCase();
      final source = (info['Source'] ?? '').toString().toLowerCase();

      var score = 0;
      if (lang.startsWith('en')) score -= 4; // prefer English
      if (source != 'asr') score -= 2; // prefer real captions over auto ones
      ranked.add((score, urlValue));
    }

    ranked.sort((a, b) => a.$1.compareTo(b.$1));
    return ranked.map((e) => e.$2).toList();
  }

  // ---- Description parsing -------------------------------------------------

  _ParsedRecipe _parseFromDescription(String? text, String? creator) {
    if (text == null || text.trim().isEmpty) {
      return _ParsedRecipe(_fallbackTitle(creator), const [], const []);
    }

    final lines = _toLines(_preNormalize(text));

    // Title: first meaningful line that isn't a section header.
    var titleIdx = -1;
    var title = _fallbackTitle(creator);
    for (var i = 0; i < lines.length; i++) {
      if (_isIngredientsHeader(lines[i]) || _isStepsHeader(lines[i])) continue;
      final candidate = _baseClean(lines[i]);
      if (candidate.length < 3) continue;
      title = _capitalize(
          candidate.length > 90 ? candidate.substring(0, 90).trim() : candidate);
      titleIdx = i;
      break;
    }

    final (ingRaw, stepRaw) = _splitSections(lines, titleIdx);
    final ingredients = _finalizeIngredients(ingRaw);
    final steps = _finalizeSteps(stepRaw);
    return _ParsedRecipe(title, ingredients, steps);
  }

  /// Splits the description lines into raw ingredient lines and raw step lines,
  /// using `Ingredients:` / `Instructions:` headers when present and otherwise
  /// classifying line-by-line (ingredients first, then steps).
  (List<String>, List<String>) _splitSections(List<String> lines, int titleIdx) {
    var ingIdx = -1;
    var stepIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (ingIdx < 0 && _isIngredientsHeader(lines[i])) ingIdx = i;
      if (stepIdx < 0 && _isStepsHeader(lines[i])) stepIdx = i;
    }

    if (ingIdx >= 0 && stepIdx >= 0) {
      if (ingIdx < stepIdx) {
        return (
          _region(lines, ingIdx, stepIdx, _ingredientsHeader),
          _region(lines, stepIdx, lines.length, _stepsHeader),
        );
      }
      return (
        _region(lines, ingIdx, lines.length, _ingredientsHeader),
        _region(lines, stepIdx, ingIdx, _stepsHeader),
      );
    }

    if (ingIdx >= 0) {
      final region = _region(lines, ingIdx, lines.length, _ingredientsHeader);
      return _splitByStepStart(region);
    }

    if (stepIdx >= 0) {
      final steps = _region(lines, stepIdx, lines.length, _stepsHeader);
      final ing = lines
          .sublist(0, stepIdx)
          .where(_looksLikeIngredient)
          .toList();
      return (ing, steps);
    }

    // No headers: classify the body (everything after the title).
    final body = lines.sublist(titleIdx < 0 ? 0 : titleIdx + 1);
    return _classify(body);
  }

  /// Slices `lines[start, end)`, stripping the section keyword off the header
  /// line so any inline list (`Ingredients: flour, eggs`) survives.
  List<String> _region(
      List<String> lines, int start, int end, RegExp header) {
    final out = <String>[];
    for (var i = start; i < end; i++) {
      var line = lines[i];
      if (i == start) {
        final m = header.firstMatch(line);
        if (m != null) line = line.substring(m.end).trim();
        if (line.isEmpty) continue;
      }
      out.add(line);
    }
    return out;
  }

  /// Everything up to the first step-looking line is ingredients; the rest are
  /// steps. Used when only an `Ingredients:` header is present.
  (List<String>, List<String>) _splitByStepStart(List<String> region) {
    for (var i = 0; i < region.length; i++) {
      if (_isNumberedStep(region[i]) || _startsWithCookingVerb(region[i])) {
        return (region.sublist(0, i), region.sublist(i));
      }
    }
    return (region, const []);
  }

  (List<String>, List<String>) _classify(List<String> body) {
    final ing = <String>[];
    final steps = <String>[];
    var inSteps = false;
    for (final line in body) {
      if (!inSteps &&
          (_isNumberedStep(line) || _startsWithCookingVerb(line))) {
        inSteps = true;
      }
      if (inSteps) {
        steps.add(line);
      } else if (_looksLikeIngredient(line)) {
        ing.add(line);
      } else {
        // Not clearly an ingredient and we haven't hit steps yet — treat it as
        // the start of the instructions.
        inSteps = true;
        steps.add(line);
      }
    }
    return (ing, steps);
  }

  // ---- Subtitle (transcript) parsing ---------------------------------------

  Future<String?> _fetchTranscript(List<String> urls) async {
    for (final u in urls) {
      try {
        final res = await _client.get(
          Uri.parse(u),
          headers: const {
            'User-Agent': _userAgent,
            'Referer': 'https://www.tiktok.com/',
          },
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final transcript = _parseVtt(res.body);
        if (transcript.trim().isNotEmpty) return transcript;
      } catch (_) {
        // Try the next track.
      }
    }
    return null;
  }

  /// Extracts the spoken text from a WebVTT document, dropping headers,
  /// timestamps, cue indexes and inline tags, and collapsing the immediate
  /// duplicate lines that ASR captions love to emit.
  String _parseVtt(String body) {
    final out = <String>[];
    for (final raw in body.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('WEBVTT') ||
          line.startsWith('NOTE') ||
          line.startsWith('STYLE') ||
          line.startsWith('Kind:') ||
          line.startsWith('Language:')) {
        continue;
      }
      if (line.contains('-->')) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      final clean = line.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      if (clean.isEmpty) continue;
      if (out.isNotEmpty && out.last == clean) continue;
      out.add(clean);
    }
    return out.join(' ');
  }

  _ParsedRecipe _parseFromTranscript(String transcript) {
    final text = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    final ingredients = _finalizeIngredients(_ingredientsFromProse(text));
    final steps = _finalizeSteps(_stepsFromProse(text));
    return _ParsedRecipe('', ingredients, steps);
  }

  /// Pulls quantity-led phrases ("two cups of flour", "1 lb chicken") out of a
  /// block of prose.
  List<String> _ingredientsFromProse(String text) {
    final re = RegExp(
      r'((?:\d+(?:[./]\d+)?|[½⅓⅔¼¾]|a|an|one|two|three|four|five|six|seven|eight|nine|ten|half)'
      r'\s+(?:\w+\s+){0,2}?'
      r'(?:cups?|tbsps?|tablespoons?|tsps?|teaspoons?|ounces?|oz|pounds?|lbs?|grams?|cloves?|cans?|sticks?|slices?|pinch(?:es)?|handfuls?|bunch(?:es)?)'
      r'(?:\s+of)?\s+\w+(?:\s+\w+){0,2})',
      caseSensitive: false,
    );
    return re.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Turns a transcript (or any run-on block of prose) into readable steps.
  ///
  /// TikTok captions are usually one long, barely-punctuated stream, so
  /// splitting on sentence breaks alone leaves the whole recipe as a single
  /// step. Instead we drop the intro hook and the outro call-to-action
  /// ("shout out to…", "follow for more"), then carve the remaining prose into
  /// steps at natural action boundaries — a new cooking verb ("add", "mix",
  /// "get"), a switch to a new vessel ("to another bowl") or a new component
  /// ("for the sauce").
  List<String> _stepsFromProse(String text) => _segmentProse(text);

  List<String> _segmentProse(String text) {
    final trimmed = _stripOutro(text.replaceAll(RegExp(r'\s+'), ' ').trim());
    if (trimmed.isEmpty) return const [];

    final segments = <String>[];
    for (final sentence in _splitSentences(trimmed)) {
      for (final clause in _splitClauses(sentence)) {
        final cleaned = _trimConnectives(clause);
        if (cleaned.isNotEmpty) segments.add(cleaned);
      }
    }

    final kept = _dropLeadingAndTrailingChatter(segments);
    return _mergeShortSegments(kept).take(40).toList();
  }

  /// Splits on sentence punctuation; falls back to the whole block when there
  /// is none (the common ASR case), leaving the clause splitter to do the work.
  List<String> _splitSentences(String text) {
    if (!RegExp(r'[.!?]').hasMatch(text)) return [text];
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Carves a single (possibly very long) sentence into step-sized clauses by
  /// starting a fresh clause whenever a new cooking action begins: a switch of
  /// vessel/component, a sequencing word ("then", "once") or — once the current
  /// clause is long enough — a fresh cooking verb that isn't glued to the words
  /// before it.
  List<String> _splitClauses(String sentence) {
    final words = sentence.split(' ').where((w) => w.isNotEmpty).toList();
    final segments = <String>[];
    final current = <String>[];
    // True while we're inside a "once/when/after…" lead-in, whose main verb
    // belongs to the same step rather than starting a new one.
    var subordinate = false;

    void flush() {
      if (current.isNotEmpty) {
        segments.add(current.join(' '));
        current.clear();
      }
    }

    for (var i = 0; i < words.length; i++) {
      final token = _wordToken(words[i]);
      final prev = i == 0 ? '' : _wordToken(words[i - 1]);

      var boundary = false;
      if (current.isNotEmpty) {
        if (_isVesselOrComponentCue(words, i) && current.length >= 2) {
          boundary = true;
        } else if (current.length >= _minClauseWords &&
            !_glueWords.contains(prev)) {
          if (_isStepStartVerb(token)) {
            // The main verb of a "once…" lead-in stays in that same step.
            if (subordinate) {
              subordinate = false;
            } else {
              boundary = true;
            }
          } else if (_transitionCues.contains(token)) {
            boundary = true;
          }
        }
      }

      if (boundary) flush();
      if (current.isEmpty) subordinate = _subordinateStarts.contains(token);
      current.add(words[i]);
    }
    flush();
    return segments;
  }

  /// A boundary at word [i] because the cook moves to a new component
  /// ("for the sauce") or a fresh vessel ("to another bowl").
  bool _isVesselOrComponentCue(List<String> words, int i) {
    final w0 = _wordToken(words[i]);
    final w1 = i + 1 < words.length ? _wordToken(words[i + 1]) : '';
    final w2 = i + 2 < words.length ? _wordToken(words[i + 2]) : '';
    if (w0 == 'for' && w1 == 'the' && _components.contains(w2)) return true;
    if ((w0 == 'to' || w0 == 'in' || w0 == 'into' || w0 == 'onto') &&
        w1 == 'another' &&
        _containers.contains(w2)) {
      return true;
    }
    return false;
  }

  bool _isStepStartVerb(String token) =>
      _cookingVerbs.contains(token) || token == 'get' || token == 'grab';

  String _wordToken(String w) => w.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

  /// Truncates a trailing call-to-action ("…and shout out to X", "follow for
  /// more") when there's a real recipe in front of it.
  String _stripOutro(String text) {
    final m = _outroChatter.firstMatch(text);
    if (m == null) return text;
    final head = text.substring(0, m.start).trim();
    return head.split(' ').length >= 4 ? head : text;
  }

  /// Drops the leading intro hook and any trailing chatter the outro trim
  /// missed, but never touches recipe steps in the middle.
  List<String> _dropLeadingAndTrailingChatter(List<String> segments) {
    var start = 0;
    var end = segments.length;
    while (start < end && _isChatterSegment(segments[start])) {
      start++;
    }
    while (end > start && _isChatterSegment(segments[end - 1])) {
      end--;
    }
    return segments.sublist(start, end);
  }

  bool _isChatterSegment(String s) =>
      _introChatter.hasMatch(s) || _outroChatter.hasMatch(s);

  /// Folds a stray fragment ("mix again") back into the previous step so we
  /// don't emit one- or two-word "steps".
  List<String> _mergeShortSegments(List<String> segments) {
    final out = <String>[];
    for (final seg in segments) {
      final count = seg.split(' ').where((w) => w.isNotEmpty).length;
      if (count < 3 && out.isNotEmpty) {
        out[out.length - 1] = '${out.last} $seg';
      } else {
        out.add(seg);
      }
    }
    return out;
  }

  /// Strips leading/trailing conjunctions left dangling by a clause split.
  String _trimConnectives(String s) {
    var t = s.trim();
    t = t.replaceFirst(
        RegExp(r'^(?:and|then|but|or|so)\s+', caseSensitive: false), '');
    t = t.replaceFirst(
        RegExp(r'\s+(?:and|then|but|or|so|to|for|with|of|the|a|an)$',
            caseSensitive: false),
        '');
    return t.trim();
  }

  /// Re-splits any step that is really an unsegmented block of prose (e.g. a
  /// whole transcript that slipped through as one step), leaving well-formed
  /// steps untouched.
  List<String> _resegmentLongSteps(List<String> steps) {
    if (!steps.any(_looksLikeProse)) return steps;
    final out = <String>[];
    for (final s in steps) {
      if (_looksLikeProse(s)) {
        out.addAll(_segmentProse(s));
      } else {
        out.add(s);
      }
    }
    return _finalizeSteps(out);
  }

  bool _looksLikeProse(String step) =>
      step.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length > 28;

  // ---- Cleaning & finalising -----------------------------------------------

  List<String> _finalizeIngredients(List<String> raw) {
    final out = <String>[];
    for (final line in raw) {
      for (final piece in _explode(line)) {
        final cleaned = _capitalize(_baseClean(piece));
        if (cleaned.length >= 2 &&
            cleaned.length < 200 &&
            !out.contains(cleaned)) {
          out.add(cleaned);
        }
      }
    }
    return out;
  }

  List<String> _finalizeSteps(List<String> raw) {
    final out = <String>[];
    for (final line in raw) {
      final cleaned = _cleanStep(line);
      if (cleaned.isEmpty) continue;
      if (cleaned.split(' ').length < 2 || cleaned.length < 6) continue;
      if (cleaned.length >= 1000) continue;
      if (!out.contains(cleaned)) out.add(cleaned);
    }
    return out;
  }

  /// Splits a single "line" that actually packs several ingredients — bullet
  /// separated, or comma separated with multiple quantities.
  List<String> _explode(String line) {
    if (RegExp(r'[•·▪▫◦‣▶►●○]').hasMatch(line)) {
      return line.split(RegExp(r'\s*[•·▪▫◦‣▶►●○]\s*'));
    }
    final quantities =
        RegExp(r'(?:\d+(?:[./]\d+)?|[½⅓⅔¼¾])').allMatches(line).length;
    if (line.contains(',') && quantities >= 2) {
      return line.split(RegExp(r'\s*,\s*'));
    }
    return [line];
  }

  String _baseClean(String s) {
    var t = s.replaceAll(_emoji, '');
    t = t.replaceAll(_hashtag, '');
    t = t.replaceFirst(_leadingBullet, '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceFirst(RegExp(r'^[-:–—•*\s]+'), '').trim();
    return t;
  }

  String _cleanStep(String s) {
    var t = _capitalize(_baseClean(s));
    if (t.isEmpty) return t;
    if (!RegExp(r'[.!?]$').hasMatch(t)) t = '$t.';
    return t;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ---- Line helpers --------------------------------------------------------

  /// Inserts line breaks ahead of section headers and numbered steps so a
  /// single-line description (common in `og:description`) still segments.
  String _preNormalize(String text) {
    var t = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    t = t.replaceAllMapped(
      RegExp(
        r'(?<=\S)\s+(Ingredients?|Instructions?|Directions?|Method|Steps?|You.?ll need|What you.?ll need|What I used)\b',
        caseSensitive: false,
      ),
      (m) => '\n${m.group(1)}',
    );
    t = t.replaceAllMapped(
      RegExp(r'(?<=\S)\s+(\d{1,2}[.)])\s'),
      (m) => '\n${m.group(1)} ',
    );
    return t;
  }

  List<String> _toLines(String text) {
    var lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      final single = lines.isEmpty ? '' : lines.first;
      if (RegExp(r'[•·▪▫◦‣▶►●○]').hasMatch(single)) {
        lines = single
            .split(RegExp(r'\s*[•·▪▫◦‣▶►●○]\s*'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
      }
    }
    return lines;
  }

  bool _isIngredientsHeader(String line) {
    final m = _ingredientsHeader.firstMatch(line);
    if (m == null) return false;
    final matched = line.substring(0, m.end);
    final rem = line.substring(m.end).trim();
    if (matched.contains(':') || rem.isEmpty) return true;
    return _looksLikeIngredient(rem) ||
        RegExp(r'^[•·▪▫◦‣▶►●○]').hasMatch(rem);
  }

  bool _isStepsHeader(String line) {
    final m = _stepsHeader.firstMatch(line);
    if (m == null) return false;
    final matched = line.substring(0, m.end);
    final rem = line.substring(m.end).trim();
    if (matched.contains(':') || rem.isEmpty) return true;
    return _isNumberedStep(rem) || _startsWithCookingVerb(rem);
  }

  bool _isNumberedStep(String line) =>
      RegExp(r'^\s*\d{1,2}[.)]\s').hasMatch(line);

  bool _startsWithCookingVerb(String line) {
    final first =
        RegExp(r'^\s*([a-z]+)', caseSensitive: false).firstMatch(line)?.group(1);
    return first != null && _cookingVerbs.contains(first.toLowerCase());
  }

  bool _startsWithQuantity(String line) => RegExp(
        r'^\s*(\d+([./]\d+)?|[½⅓⅔¼¾⅛⅜⅝⅞]|a\s|an\s|one\s|two\s|three\s|four\s|five\s|six\s|seven\s|eight\s|half\s)',
        caseSensitive: false,
      ).hasMatch(line);

  bool _looksLikeIngredient(String line) {
    if (_isNumberedStep(line)) return false;
    if (_startsWithQuantity(line)) return true;
    return line.length < 60 && _unit.hasMatch(line);
  }

  dynamic _dig(dynamic node, List<String> keys) {
    var current = node;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  String _fallbackTitle(String? creator) => 'Recipe by ${creator ?? 'TikTok'}';

  // ---- Patterns ------------------------------------------------------------

  static final _ingredientsHeader = RegExp(
    r"^(ingredients?|you'?ll need|what you'?ll need|what i used|shopping list)\s*:?",
    caseSensitive: false,
  );
  static final _stepsHeader = RegExp(
    r'^(instructions?|directions?|method|steps?|how to make|preparation|to make|to prepare)\s*:?',
    caseSensitive: false,
  );
  static final _unit = RegExp(
    r'\b(cups?|tbsps?|tablespoons?|tsps?|teaspoons?|oz|ounces?|lbs?|lb|pounds?|grams?|g|kg|ml|cloves?|cans?|sticks?|slices?|pinch|dash|handful|bunch)\b',
    caseSensitive: false,
  );
  static final _hashtag = RegExp(r'[#@][\w]+');
  static final _leadingBullet =
      RegExp(r'^\s*(?:[-*•·▪▫◦‣▶►●○➡]+|\d{1,2}[.)])\s*');
  static final _emoji = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}\u{2300}-\u{23FF}\u{FE00}-\u{FE0F}\u{200D}\u{20E3}]',
    unicode: true,
  );

  static const _cookingVerbs = {
    'add', 'mix', 'stir', 'combine', 'heat', 'cook', 'bake', 'pour', 'whisk',
    'season', 'serve', 'chop', 'slice', 'dice', 'mince', 'saute', 'sauté',
    'fry', 'boil', 'simmer', 'preheat', 'place', 'put', 'spread', 'layer',
    'top', 'garnish', 'blend', 'melt', 'cut', 'remove', 'drain', 'cover',
    'let', 'transfer', 'roast', 'grill', 'fold', 'beat', 'knead', 'roll',
    'brush', 'sprinkle', 'drizzle', 'marinate', 'set', 'bring', 'grate',
    'toss', 'coat', 'rinse', 'wash', 'peel', 'crush', 'reduce', 'flip',
  };

  // ---- Prose segmentation --------------------------------------------------

  /// Minimum words a clause must already hold before a fresh cooking verb is
  /// allowed to start a new step (keeps "add salt and pepper" as one step).
  static const _minClauseWords = 4;

  /// Sequencing words that mark the start of a new step.
  static const _transitionCues = {
    'then', 'next', 'once', 'meanwhile', 'finally',
  };

  /// Lead-in words whose main verb belongs to the same step ("once it releases,
  /// break it up" is one step, not two).
  static const _subordinateStarts = {
    'once', 'when', 'after', 'while', 'as', 'if', 'until', 'unless',
  };

  /// Words that shouldn't precede a step break — a verb glued to one of these
  /// continues the current clause ("and let it chill", "to mix").
  static const _glueWords = {
    'and', 'or', 'but', 'so', 'then', 'to', 'of', 'the', 'a', 'an', 'with',
    'into', 'in', 'on', 'at', 'for', 'it', 'its', 'that', 'this', 'your', 'my',
    'some', 'until', 'till',
  };

  /// Recipe components introduced by "for the …".
  static const _components = {
    'sauce', 'sauces', 'marinade', 'dressing', 'filling', 'topping', 'garnish',
    'glaze', 'batter', 'dough', 'crust', 'base', 'seasoning', 'rub', 'cream',
    'assembly', 'coating', 'crumb', 'crumble', 'frosting', 'icing',
  };

  /// Vessels introduced by "to/in another …".
  static const _containers = {
    'bowl', 'pan', 'pot', 'skillet', 'dish', 'tray', 'plate', 'sheet', 'mixer',
    'blender', 'processor', 'saucepan', 'jar', 'glass', 'cup', 'wok', 'container',
  };

  static final _introChatter = RegExp(
    r"best recipe|recipe of the year|you ?won'?t believe|for the last time"
    r"|(?:we|i) finally|finally made|wait (?:for it|till|until)"
    r"|watch (?:me|this)|welcome back|in this (?:video|one)|part \d"
    r"|new york times recipes|i'?m cooking",
    caseSensitive: false,
  );
  static final _outroChatter = RegExp(
    r"shout ?out|thanks? (?:for|to) (?:watching|you)|follow (?:for|me)"
    r"|for more recipes|link in (?:my )?bio|full recipe|like and subscribe"
    r"|subscribe|comment (?:below|down|if)|save this|don'?t forget to"
    r"|hit the (?:follow|like)|check (?:out|the) (?:link|description|bio)",
    caseSensitive: false,
  );
}

/// Metadata scraped from a TikTok video page.
class _TiktokMeta {
  const _TiktokMeta(this.creator, this.description, this.subtitleUrls);

  final String? creator;
  final String? description;
  final List<String> subtitleUrls;
}

/// A parsed (title, ingredients, steps) triple.
class _ParsedRecipe {
  const _ParsedRecipe(this.title, this.ingredients, this.steps);

  final String title;
  final List<String> ingredients;
  final List<String> steps;
}
