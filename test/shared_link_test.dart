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
}
