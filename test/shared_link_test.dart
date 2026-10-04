import 'package:flutter_test/flutter_test.dart';
import 'package:just_the_crumbs_mobile/services/import/shared_link.dart';

void main() {
  group('firstLinkIn', () {
    test('returns a bare url unchanged', () {
      expect(
        firstLinkIn('https://vm.tiktok.com/ZGabc123/'),
        'https://vm.tiktok.com/ZGabc123/',
      );
    });

    test('pulls the link out of a shared caption', () {
      expect(
        firstLinkIn(
          'Check out this recipe! https://www.tiktok.com/@cook/video/123 '
          '#pasta #dinner',
        ),
        'https://www.tiktok.com/@cook/video/123',
      );
    });

    test('drops sentence punctuation stuck to the end', () {
      expect(
        firstLinkIn('Made this: https://example.com/recipe.'),
        'https://example.com/recipe',
      );
    });

    test('keeps query strings intact', () {
      expect(
        firstLinkIn('https://example.com/r?id=7&utm_source=tiktok now cook'),
        'https://example.com/r?id=7&utm_source=tiktok',
      );
    });

    test('returns null when there is no link', () {
      expect(firstLinkIn('just some text about dinner'), isNull);
    });
  });

  group('shareCodeIn', () {
    test('uppercases a hand-typed code and drops spaces and dashes', () {
      expect(shareCodeIn(' k7q2-m9az '), 'K7Q2M9AZ');
    });

    test('pulls the code out of a pasted share message', () {
      expect(
        shareCodeIn(
          '🥐 Lemon tart\n\nShare code: K7Q2M9AZ\n\nGet Just The Crumbs:\n'
          'https://rileylgray.github.io/just-the-crumbs.html',
        ),
        'K7Q2M9AZ',
      );
    });

    test('pulls the code out of a share link', () {
      expect(shareCodeIn('justthecrumbs://share/K7Q2M9AZ'), 'K7Q2M9AZ');
    });

    test('returns null for text that is not a code', () {
      expect(shareCodeIn('not a code!'), isNull);
      expect(shareCodeIn('   '), isNull);
    });
  });
}
