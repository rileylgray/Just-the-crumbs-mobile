import '../../models/recipe.dart';

/// Turns a flat list of scraped/parsed ingredient lines into structured
/// [IngredientGroup]s, so a multi-part recipe ("For the crust" / "For the
/// filling") lands in the editor already split.
///
/// Two in-band shapes are understood, and they may be mixed in one list:
///
/// * `Group — item`, the encoding the HTML scraper emits when the page marks
///   its ingredient groups up with headings.
/// * A heading *entry* sitting in the list itself — `For the sauce:`,
///   `Crust:` — which is how both recipe sites and TikTok captions carry
///   groups when there is no markup to read them from.
///
/// Items before the first heading fall into a leading untitled group, which is
/// how an ordinary single-list recipe stays a plain list. The result always has
/// at least one group so callers can render it unconditionally.
List<IngredientGroup> groupIngredients(List<String> flat) {
  final groups = <IngredientGroup>[];
  var title = '';
  var items = <String>[];

  void flush() {
    if (items.isEmpty) return;
    groups.add(IngredientGroup(title: title, items: items));
    items = <String>[];
  }

  for (final raw in flat) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final heading = ingredientGroupTitle(line);
    if (heading != null) {
      flush();
      title = heading;
      continue;
    }

    // `Group — item` encoding from the HTML scraper.
    final sep = line.indexOf(' — ');
    if (sep > 0) {
      final encodedTitle = line.substring(0, sep).trim();
      final item = line.substring(sep + 3).trim();
      if (item.isEmpty) continue;
      if (encodedTitle != title) {
        flush();
        title = encodedTitle;
      }
      items.add(item);
      continue;
    }

    items.add(line);
  }
  flush();

  if (groups.isEmpty) return [const IngredientGroup()];
  // A heading with nothing under it is noise, not a group; if that left us with
  // a single titled group holding everything, the "heading" was really just the
  // list's own label, so drop it rather than showing a lone header.
  if (groups.length == 1 && !groups.first.isDefault) {
    return [IngredientGroup(items: groups.first.items)];
  }
  return groups;
}

/// The group title [line] announces, or `null` when it reads as an ingredient.
///
/// Accepts `For the sauce` / `To make the glaze` with or without a colon, and
/// any short colon-terminated label (`Crust:`). Quantities disqualify a line —
/// a heading names a part, it doesn't measure one — as do the section words the
/// importers handle themselves.
String? ingredientGroupTitle(String line) {
  final text = line.trim();
  if (text.length < 3 || text.length > 60) return null;
  if (_digit.hasMatch(text)) return null;
  if (_sectionWord.hasMatch(text)) return null;

  final forMatch = _forHeading.firstMatch(text);
  final title = forMatch != null
      ? forMatch.group(1)
      : _colonHeading.firstMatch(text)?.group(1);
  if (title == null) return null;

  final cleaned = title.trim().replaceAll(_trailingPunctuation, '').trim();
  if (cleaned.length < 2) return null;
  if (cleaned.split(_whitespace).length > 6) return null;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

final _digit = RegExp(r'\d');
final _whitespace = RegExp(r'\s+');
final _trailingPunctuation = RegExp(r'[:\s.,;-]+$');

/// Section labels the importers route themselves; never a group of their own.
final _sectionWord = RegExp(
  r'^(ingredients?|instructions?|directions?|method|steps?|notes?|tips?'
  r'|equipment|tools|nutrition|serves|servings|yield|prep|cook|total|makes)\b',
  caseSensitive: false,
);

/// `For the sauce`, `For serving`, `To make the glaze` — the whole line, so an
/// ingredient that merely starts that way ("For serving: rice") isn't stolen.
final _forHeading = RegExp(
  r'^(?:for|to make)\s+(?:the\s+|your\s+)?([^:]{2,40}?)\s*:?$',
  caseSensitive: false,
);

/// A short colon-terminated label: `Crust:`, `Marinade:`.
final _colonHeading = RegExp(r'^([^:]{2,40}?)\s*:$');
