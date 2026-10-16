import '../providers/locale_provider.dart' show MeasurementSystem;

/// Rewrites the measurements in a line of free-text recipe content (an
/// ingredient or a step) into the reader's chosen [MeasurementSystem].
///
/// This is deliberately conservative: it only touches spans it recognises as a
/// quantity followed by a known unit, converts *toward* the requested system
/// (imperial units when going metric, and vice-versa), and leaves everything
/// else — including units already in the target system and any text it can't
/// parse — exactly as written. On [MeasurementSystem.asWritten] the input is
/// returned untouched.
String convertMeasurements(String text, MeasurementSystem target) {
  if (target == MeasurementSystem.asWritten || text.isEmpty) return text;
  return text.replaceAllMapped(_measurement, (m) {
    // Groups: 1 = first amount, 2 = range separator, 3 = second amount, 4 = unit.
    final unit = _unitFor(m.group(4)!);
    if (unit == null) return m.group(0)!;
    // Only convert units that come *from* the other system; leave anything
    // already in the target system as written.
    if (target == MeasurementSystem.metric && unit.isMetric) return m.group(0)!;
    if (target == MeasurementSystem.imperial && !unit.isMetric) {
      return m.group(0)!;
    }
    final a = _parseAmount(m.group(1)!);
    if (a == null) return m.group(0)!;
    final sep = m.group(2); // range separator, e.g. " to ", "-", null
    final b = sep == null ? null : _parseAmount(m.group(3) ?? '');
    return _convert(a, b, sep, unit, target) ?? m.group(0)!;
  });
}

/// Multiplies the quantities in one ingredient line by [factor], for cooking a
/// half, double or triple batch.
///
/// Like [convertMeasurements] this only touches what it can read:
///
/// * A line led by a measurement ("1 cup (120 g) flour") has every
///   measurement in it scaled, so a weight given alongside stays in step.
/// * A line led by a plain count ("2 eggs", "1 (14 oz) can tomatoes") has only
///   that count scaled — the can size describes the can, not how many.
/// * Otherwise any measurement in the line is scaled ("Flour, 2 cups").
///
/// Sizes and temperatures are never scaled ("9-inch pan", "2% milk", "65°F").
/// Imperial amounts come out as kitchen fractions, metric ones as decimals.
String scaleQuantities(String text, double factor) {
  if (factor == 1 || text.trim().isEmpty) return text;
  final start = text.length - text.trimLeft().length;
  if (_scalableMeasurement.matchAsPrefix(text, start) == null) {
    final count = _leadingCount.firstMatch(text);
    if (count != null) {
      final a = _parseAmount(count.group(2)!);
      final sep = count.group(3);
      final b = sep == null ? null : _parseAmount(count.group(4)!);
      if (a == null || (sep != null && b == null)) return text;
      final style = _NumberStyle.of(count.group(0)!);
      return '${count.group(1)}${style.format(a * factor)}'
          '${sep == null ? '' : '$sep${style.format(b! * factor)}'}'
          '${text.substring(count.end)}';
    }
  }
  return text.replaceAllMapped(_scalableMeasurement, (m) {
    // Groups: 1 = first amount, 2 = separator + second amount, 3 = second
    // amount, 4 = space before the unit, 5 = unit.
    final unit = _unitFor(m.group(5)!);
    if (unit == null || unit.kind == _Kind.temp) return m.group(0)!;
    final a = _parseAmount(m.group(1)!);
    final range = m.group(2);
    final b = range == null ? null : _parseAmount(m.group(3)!);
    if (a == null || (range != null && b == null)) return m.group(0)!;
    final style = _NumberStyle.of(m.group(0)!, metric: unit.isMetric);
    final sep = range?.substring(0, range.length - m.group(3)!.length);
    return '${style.format(a * factor)}'
        '${sep == null ? '' : '$sep${style.format(b! * factor)}'}'
        '${m.group(4)}${_agreeUnit(m.group(5)!, (b ?? a) * factor)}';
  });
}

// ---- Matching --------------------------------------------------------------

const _vulgarChars = '½⅓⅔¼¾⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚';

// A single amount, kept as its own fragment so the range pattern can reuse it.
// Mixed numbers come in every shape recipes write them — "3 1/2", "3-1/2",
// "3 and 1/2", "3½", "3 ½" — and must match whole: matching only the fraction
// converts it and strands the whole number in front ("3 ½ cups" → "3 120 ml").
// Recipe sites often use the fraction slash (⁄, U+2044) instead of "/".
// Then plain fractions (1/2), decimals (1.5), integers (2) and a lone vulgar
// fraction (½).
const _amount =
    r'(?:\d+(?:\s+and\s+|\s*-\s*|\s+)\d+\s*[/⁄]\s*\d+'
    '|\\d+\\s*[$_vulgarChars]'
    r'|\d+\s*[/⁄]\s*\d+'
    r'|\d+(?:[.,]\d+)?'
    '|[$_vulgarChars])';

// amount, optional range (`-`, en/em dash or "to") + second amount, then a unit.
const _units =
    r'cups?|tablespoons?|tbsps?|tbs|teaspoons?|tsps?|fluid\s+ounces?|fl\.?\s*oz|ounces?|oz|pounds?|lbs?|millis?litres?|milliliters?|millilitres?|ml|litres?|liters?|l|grams?|g|kilograms?|kilos?|kg|°\s*[cf]|degrees?\s+[cf]|celsius|centigrade|fahrenheit';

final _measurement = RegExp(
  '($_amount)'
  '(?:\\s*(-|–|—|\\s+to\\s+)\\s*($_amount))?'
  r'\s*'
  '($_units)\\b',
  caseSensitive: false,
);

// [_measurement] with every piece captured, so a scaled amount can be put back
// with the line's own spacing and separators.
final _scalableMeasurement = RegExp(
  '($_amount)'
  '(\\s*(?:-|–|—|\\s+to\\s+)\\s*($_amount))?'
  r'(\s*)'
  '($_units)\\b',
  caseSensitive: false,
);

// A count at the start of a line ("2 eggs", "2-3 cloves"). The lookahead keeps
// it from stopping partway through a number ("10" as "1") or a range, and
// skips sizes and percentages ("9-inch pan", "2% milk") that aren't amounts.
final _leadingCount = RegExp(
  '^(\\s*)($_amount)'
  '(?:(\\s*(?:-|–|—|\\s+to\\s+)\\s*)($_amount))?'
  '(?!\\d|[.,]\\d|[/⁄$_vulgarChars]|\\s*[-–—]\\s*\\d|\\s+to\\s+\\d'
  r'''|\s*-?\s*(?:inch|in\b|"|”|cm\b|mm\b|%|°))''',
  caseSensitive: false,
);

/// [unit] made to agree with a new [amount] when it is spelled out: "1 cup"
/// doubles to "2 cups", "1 1/2 cups" halves to "3/4 cup". Abbreviations
/// ("tbsp", "lb", "g") read the same either way and are left alone.
String _agreeUnit(String unit, double amount) {
  final m = _wordUnit.firstMatch(unit);
  if (m == null) return unit;
  if (amount <= 1) return m.group(1)!;
  return '${m.group(1)}${unit == unit.toUpperCase() ? 'S' : 's'}';
}

final _wordUnit = RegExp(
  r'^(cup|tablespoon|teaspoon|pound|ounce|gram|kilogram|kilo|liter|litre'
  r'|milliliter|millilitre)s?$',
  caseSensitive: false,
);

/// How to write a scaled amount, following how the original was written.
class _NumberStyle {
  const _NumberStyle(this.decimal, this.comma);

  /// Decimals for metric amounts and ones written as decimals ("1.5 lb");
  /// kitchen fractions otherwise.
  factory _NumberStyle.of(String original, {bool metric = false}) {
    final decimal =
        metric || (_decimalMark.hasMatch(original) && !original.contains('/'));
    return _NumberStyle(decimal, original.contains(RegExp(r'\d,\d')));
  }

  static final _decimalMark = RegExp(r'\d[.,]\d');

  final bool decimal;

  /// Keep a decimal comma ("1,5 kg" halves to "0,75 kg").
  final bool comma;

  String format(double v) {
    if (!decimal) return _kitchenFraction(v);
    final s = v
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return comma ? s.replaceAll('.', ',') : s;
  }
}

// Normalise the captured range separator back into display text.
String _sepText(String sep) => sep.trim().toLowerCase() == 'to' ? ' to ' : '–';

// ---- Units -----------------------------------------------------------------

enum _Kind { volume, weight, temp }

class _Unit {
  const _Unit(this.kind, this.isMetric, this.metricBase);

  final _Kind kind;
  final bool isMetric;

  /// Value of one of this unit in the metric base for its kind:
  /// millilitres (volume), grams (weight). Unused for temperature.
  final double metricBase;
}

_Unit? _unitFor(String raw) {
  var u = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  u = u.replaceAll('.', '');
  switch (u) {
    case 'cup':
    case 'cups':
      return const _Unit(_Kind.volume, false, 236.588);
    case 'tablespoon':
    case 'tablespoons':
    case 'tbsp':
    case 'tbsps':
    case 'tbs':
      return const _Unit(_Kind.volume, false, 14.7868);
    case 'teaspoon':
    case 'teaspoons':
    case 'tsp':
    case 'tsps':
      return const _Unit(_Kind.volume, false, 4.92892);
    case 'fluid ounce':
    case 'fluid ounces':
    case 'fl oz':
    case 'floz':
      return const _Unit(_Kind.volume, false, 29.5735);
    case 'ounce':
    case 'ounces':
    case 'oz':
      return const _Unit(_Kind.weight, false, 28.3495);
    case 'pound':
    case 'pounds':
    case 'lb':
    case 'lbs':
      return const _Unit(_Kind.weight, false, 453.592);
    case 'ml':
    case 'milliliter':
    case 'milliliters':
    case 'millilitre':
    case 'millilitres':
      return const _Unit(_Kind.volume, true, 1);
    case 'l':
    case 'liter':
    case 'liters':
    case 'litre':
    case 'litres':
      return const _Unit(_Kind.volume, true, 1000);
    case 'g':
    case 'gram':
    case 'grams':
      return const _Unit(_Kind.weight, true, 1);
    case 'kg':
    case 'kilo':
    case 'kilos':
    case 'kilogram':
    case 'kilograms':
      return const _Unit(_Kind.weight, true, 1000);
  }
  if (u.endsWith('c') || u == 'celsius' || u == 'centigrade') {
    return const _Unit(_Kind.temp, true, 1);
  }
  if (u.endsWith('f') || u == 'fahrenheit') {
    return const _Unit(_Kind.temp, false, 1);
  }
  return null;
}

// ---- Conversion ------------------------------------------------------------

String? _convert(
  double a,
  double? b,
  String? sep,
  _Unit unit,
  MeasurementSystem target,
) {
  if (unit.kind == _Kind.temp) {
    final ca = _convertTemp(a, unit.isMetric).round();
    final label = target == MeasurementSystem.metric ? '°C' : '°F';
    if (b != null) {
      return '$ca${_sepText(sep!)}${_convertTemp(b, unit.isMetric).round()}$label';
    }
    return '$ca$label';
  }

  // Everything else routes through the metric base (ml or g).
  final baseA = a * unit.metricBase;
  final baseB = b == null ? null : b * unit.metricBase;
  final peak = baseB ?? baseA;

  var (factor, label, fractional) = target == MeasurementSystem.metric
      ? _metricUnit(unit.kind, peak)
      : _imperialUnit(unit.kind, peak);
  // "1 cup", "3/4 cup" — only more than one is "cups". Values within 1/16 of a
  // cup display as 1 once rounded to eighths.
  if (label == 'cups' && peak / factor < 1.0625) label = 'cup';

  String fmt(double base) {
    var value = base / factor;
    // Nobody weighs out "8 7/8 oz": past a few ounces, the nearest half will do.
    if (label == 'oz' && value >= 3) value = (value * 2).round() / 2;
    return fractional ? _fraction(value) : _metricNumber(value);
  }

  final head = fmt(baseA);
  if (baseB != null) return '$head${_sepText(sep!)}${fmt(baseB)} $label';
  return '$head $label';
}

double _convertTemp(double value, bool fromMetric) =>
    fromMetric ? value * 9 / 5 + 32 : (value - 32) * 5 / 9;

/// Picks the metric unit (and its factor from the base) for a [peak] amount,
/// so large volumes read as litres and large weights as kilograms.
(double, String, bool) _metricUnit(_Kind kind, double peakBase) {
  if (kind == _Kind.volume) {
    return peakBase >= 1000 ? (1000, 'l', false) : (1, 'ml', false);
  }
  return peakBase >= 1000 ? (1000, 'kg', false) : (1, 'g', false);
}

/// Picks the imperial unit for a [peak] amount in the metric base. Volumes step
/// down cups → tablespoons → teaspoons; weights step pounds → ounces.
(double, String, bool) _imperialUnit(_Kind kind, double peakBase) {
  if (kind == _Kind.volume) {
    if (peakBase >= 177.0) return (236.588, 'cups', true); // ≥ ¾ cup
    if (peakBase >= 11.0) return (14.7868, 'tbsp', true); // ≥ ¾ tbsp
    return (4.92892, 'tsp', true);
  }
  // Pounds from the point the amount rounds to 1 lb; below that, a 400 g can
  // reads as "14 oz" rather than "7/8 lb".
  if (peakBase >= 430.0) return (453.592, 'lb', true);
  return (28.3495, 'oz', true);
}

// ---- Number parsing & formatting -------------------------------------------

const _vulgar = {
  '½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75,
  '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
  '⅕': 0.2, '⅖': 0.4, '⅗': 0.6, '⅘': 0.8, '⅙': 1 / 6, '⅚': 5 / 6,
};

double? _parseAmount(String raw) {
  // Fold the mixed-number spellings [_amount] accepts into "1 1/2" or "1½".
  final s = raw
      .trim()
      .replaceAll('⁄', '/')
      .replaceAll(RegExp(r'\s+and\s+'), ' ')
      .replaceFirstMapped(
        RegExp(r'^(\d+)\s*-\s*(\d+\s*/)'),
        (m) => '${m[1]} ${m[2]}',
      )
      .replaceFirstMapped(
        RegExp('^(\\d+)\\s+([$_vulgarChars])\$'),
        (m) => '${m[1]}${m[2]}',
      );
  if (s.isEmpty) return null;
  if (s.length == 1 && _vulgar.containsKey(s)) return _vulgar[s];

  // Mixed number with a trailing vulgar fraction, e.g. "1½".
  if (s.length >= 2 && _vulgar.containsKey(s[s.length - 1])) {
    final whole = double.tryParse(s.substring(0, s.length - 1).trim());
    if (whole != null) return whole + _vulgar[s[s.length - 1]]!;
  }

  // Mixed number "1 1/2".
  final mixed = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (mixed != null) {
    final w = double.parse(mixed.group(1)!);
    final n = double.parse(mixed.group(2)!);
    final d = double.parse(mixed.group(3)!);
    if (d != 0) return w + n / d;
  }

  // Plain fraction "1/2".
  final frac = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (frac != null) {
    final d = double.parse(frac.group(2)!);
    if (d != 0) return double.parse(frac.group(1)!) / d;
  }

  return double.tryParse(s.replaceAll(',', '.'));
}

/// Rounds a metric quantity to a readable value: nearest 10 when large, nearest
/// 5 in the mid range, otherwise a whole number (or one decimal when tiny).
String _metricNumber(double v) {
  double rounded;
  if (v >= 100) {
    rounded = (v / 10).round() * 10;
  } else if (v >= 20) {
    rounded = (v / 5).round() * 5;
  } else if (v >= 1) {
    rounded = v.roundToDouble();
  } else {
    return _round(v, 1);
  }
  return rounded.toStringAsFixed(0);
}

/// Formats an imperial quantity as a friendly fraction to the nearest ⅛
/// (e.g. 1.5 → "1 1/2", 0.75 → "3/4").
String _fraction(double v) {
  if (v <= 0) return '0';
  final whole = v.floor();
  final eighths = ((v - whole) * 8).round();
  if (eighths == 0) return '$whole';
  if (eighths == 8) return '${whole + 1}';

  var num = eighths;
  var den = 8;
  for (final g in const [2, 4]) {
    if (num % g == 0 && den % g == 0) {
      num ~/= g;
      den ~/= g;
    }
  }
  final frac = '$num/$den';
  return whole == 0 ? frac : '$whole $frac';
}

String _round(double v, int decimals) {
  final s = v.toStringAsFixed(decimals);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Like [_fraction], but also reaches for thirds and sixths, which scaling
/// produces all the time (⅓ cup doubled is ⅔, not ⅝). Picks the simplest
/// fraction that is close enough, so halves and quarters stay halves and
/// quarters. A tiny non-zero amount never rounds away to "0".
String _kitchenFraction(double v) {
  if (v <= 0) return '0';
  var whole = v.floor();
  final frac = v - whole;
  var bestNum = 0;
  var bestDen = 1;
  var bestErr = double.infinity;
  for (final den in const [1, 2, 3, 4, 6, 8]) {
    final num = (frac * den).round();
    final err = (frac - num / den).abs();
    if (err < bestErr) {
      bestNum = num;
      bestDen = den;
      bestErr = err;
    }
    if (bestErr < 0.02) break;
  }
  if (bestNum == bestDen) {
    whole += 1;
    bestNum = 0;
  }
  if (bestNum == 0) return whole == 0 ? '1/16' : '$whole';
  final g = bestNum.gcd(bestDen);
  final f = '${bestNum ~/ g}/${bestDen ~/ g}';
  return whole == 0 ? f : '$whole $f';
}
