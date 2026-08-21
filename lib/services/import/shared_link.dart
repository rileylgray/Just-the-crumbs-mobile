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
