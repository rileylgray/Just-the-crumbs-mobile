import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models/recipe.dart';

/// Builds shareable text for a recipe and invokes the OS share sheet.
///
/// Sharing is code-based and requires no hosted domain: the recipient opens the
/// custom-scheme link (`justthecrumbs://share/<code>`) to jump straight to the
/// recipe, or pastes the short code into the app. Both resolve a self-contained
/// snapshot stored in Firestore under that code.
class ShareService {
  /// Custom-scheme deep link that opens the app to a shared recipe.
  static String shareLink(String code) =>
      '${AppConfig.deepLinkScheme}://share/$code';

  static String _formatRecipe(Recipe recipe) {
    final buffer = StringBuffer()
      ..writeln('🥐 ${recipe.title}')
      ..writeln();
    if (recipe.description.isNotEmpty) {
      buffer
        ..writeln(recipe.description)
        ..writeln();
    }
    buffer.writeln('Ingredients');
    for (final item in recipe.ingredients) {
      buffer.writeln('• $item');
    }
    buffer
      ..writeln()
      ..writeln('Steps');
    for (var i = 0; i < recipe.steps.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.steps[i]}');
    }
    return buffer.toString();
  }

  /// Shares [recipe] using the given share [code].
  Future<void> shareRecipe(Recipe recipe, String code) async {
    final text = StringBuffer(_formatRecipe(recipe))
      ..writeln()
      ..writeln('— — —')
      ..writeln('Open in Just The Crumbs:')
      ..writeln(shareLink(code))
      ..writeln()
      ..writeln('No link? Open the app and enter this code:')
      ..writeln(code);

    await SharePlus.instance.share(
      ShareParams(text: text.toString(), subject: recipe.title),
    );
  }
}
