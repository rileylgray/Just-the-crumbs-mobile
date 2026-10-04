/// Helpers for the text that arrives when a recipe is shared *into* the app
/// from another app's share sheet.
library;

/// Matches the first http(s) link in a block of text.
final _link = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

/// Trailing punctuation that belongs to the sentence, not the URL.
final _trailingPunctuation = RegExp(r'[.,;:!?)\]}"]+$');

/// The first link in [text], or `null` when there isn't one.
///
/// Share sheets rarely hand over a bare URL: TikTok sends something like
/// `Check out this recipe! https://vm.tiktok.com/ZGabc123/ #food`, so the link
/// has to be picked out of the surrounding caption before it can be imported.
String? firstLinkIn(String text) {
  final match = _link.firstMatch(text);
  if (match == null) return null;
  final url = match.group(0)!.replaceFirst(_trailingPunctuation, '');
  return url.isEmpty ? null : url;
}

/// A share link (`justthecrumbs://share/K7Q2M9AZ`) or the "Share code: …"
/// line of the message the app's own share sheet sends.
final _shareCodeInLink = RegExp(r'share/([a-z0-9]+)', caseSensitive: false);
final _shareCodeInMessage = RegExp(r'code:\s*([a-z0-9]+)', caseSensitive: false);

/// The recipe share code in [text], uppercased, or `null` when there isn't one.
///
/// Recipients often copy the whole share message, or the link, rather than
/// just the code, so the code is picked out of either. Anything else is taken
/// as a hand-typed code, with spaces and dashes dropped.
String? shareCodeIn(String text) {
  final match =
      _shareCodeInLink.firstMatch(text) ?? _shareCodeInMessage.firstMatch(text);
  if (match != null) return match.group(1)!.toUpperCase();
  final typed = text.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^[a-z0-9]+$', caseSensitive: false).hasMatch(typed)
      ? typed.toUpperCase()
      : null;
}
