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

// ---- Matching --------------------------------------------------------------

// A single amount: mixed number (1 1/2), fraction (1/2), decimal (1.5),
// integer (2) or a unicode vulgar fraction (½). Kept as its own fragment so the
// range pattern can reuse it.
const _amount =
    r'(?:\d+\s+\d+\s*/\s*\d+|\d+\s*/\s*\d+|\d+(?:[.,]\d+)?|[½⅓⅔¼¾⅛⅜⅝⅞⅕⅖⅗⅘⅙⅚])';

// amount, optional range (`-`, en/em dash or "to") + second amount, then a unit.
final _measurement = RegExp(
  '($_amount)'
  '(?:\\s*(-|–|—|\\s+to\\s+)\\s*($_amount))?'
  r'\s*'
  r'(cups?|tablespoons?|tbsps?|tbs|teaspoons?|tsps?|fluid\s+ounces?|fl\.?\s*oz|ounces?|oz|pounds?|lbs?|millis?litres?|milliliters?|millilitres?|ml|litres?|liters?|l|grams?|g|kilograms?|kilos?|kg|°\s*[cf]|degrees?\s+[cf]|celsius|centigrade|fahrenheit)\b',
  caseSensitive: false,
);

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

  final (factor, label, fractional) = target == MeasurementSystem.metric
      ? _metricUnit(unit.kind, peak)
      : _imperialUnit(unit.kind, peak);

  String fmt(double base) {
    final value = base / factor;
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
  if (peakBase >= 340.0) return (453.592, 'lb', true); // ≥ ~¾ lb
  return (28.3495, 'oz', true);
}

// ---- Number parsing & formatting -------------------------------------------

const _vulgar = {
  '½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75,
  '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
  '⅕': 0.2, '⅖': 0.4, '⅗': 0.6, '⅘': 0.8, '⅙': 1 / 6, '⅚': 5 / 6,
};

double? _parseAmount(String raw) {
  final s = raw.trim();
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
