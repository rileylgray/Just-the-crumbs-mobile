import 'package:share_plus/share_plus.dart';

import '../models/recipe.dart';

/// Builds shareable text for a recipe and invokes the OS share sheet.
///
/// Sharing is code-based and requires no hosted domain: the recipient installs
/// the app from the download link, then pastes the short code to resolve a
/// self-contained snapshot stored in Firestore under that code.
class ShareService {
  /// Link to download the app.
  static const String downloadLink =
      'https://rileylgray.github.io/just-the-crumbs.html';

  /// Shares [recipe] using the given share [code].
  Future<void> shareRecipe(Recipe recipe, String code) async {
    final text = StringBuffer()
      ..writeln('🥐 ${recipe.title}')
      ..writeln()
      ..writeln('Share code: $code')
      ..writeln()
      ..writeln('Get Just The Crumbs:')
      ..writeln(downloadLink);

    await SharePlus.instance.share(
      ShareParams(text: text.toString(), subject: recipe.title),
    );
  }
}
