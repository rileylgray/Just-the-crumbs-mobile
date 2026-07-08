import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_the_crumbs_mobile/services/import/recipe_import_service.dart';

http.Client _clientReturning(String body) =>
    MockClient((request) async => http.Response(body, 200));

void main() {
  group('RecipeImportService', () {
    test('parses Schema.org JSON-LD (HowToStep instructions)', () async {
      const html = '''
<html><head>
<title>Chocolate Chip Cookies | Best Site</title>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Recipe","name":"Chocolate Chip Cookies",
"recipeIngredient":["1 cup flour","2 eggs","1/2 cup sugar"],
"recipeInstructions":[
 {"@type":"HowToStep","text":"Mix the dry ingredients together well."},
 {"@type":"HowToStep","text":"Beat in the eggs and stir until smooth."},
 {"@type":"HowToStep","text":"Bake for twenty minutes at 350F."}]}
</script></head><body></body></html>''';

      final result = await RecipeImportService(
        'https://example.com/cookies',
        client: _clientReturning(html),
      ).call();

      expect(result.title, 'Chocolate Chip Cookies');
      expect(result.ingredients, ['1 cup flour', '2 eggs', '1/2 cup sugar']);
      expect(result.steps.length, 3);
      expect(result.steps.first, contains('Mix the dry ingredients'));
    });

    test('flattens @graph wrapper and HowToSection instructions', () async {
      const html = '''
<html><head><title>Soup</title>
<script type="application/ld+json">
{"@graph":[
 {"@type":"WebPage","name":"ignore me"},
 {"@type":"Recipe","name":"Tomato Soup",
  "recipeIngredient":["2 lb tomatoes","1 onion"],
  "recipeInstructions":[
    {"@type":"HowToSection","itemListElement":[
      {"@type":"HowToStep","text":"Chop the tomatoes and onion finely."},
      {"@type":"HowToStep","text":"Simmer everything for thirty minutes."}]}]}]}
</script></head><body></body></html>''';

      final result = await RecipeImportService(
        'https://example.com/soup',
        client: _clientReturning(html),
      ).call();

      expect(result.title, 'Soup'); // from <title>, no pipe
      expect(result.ingredients, ['2 lb tomatoes', '1 onion']);
      expect(result.steps.length, 2);
      expect(result.steps.last, contains('Simmer'));
    });

    test('falls back to HTML lists when no JSON-LD is present', () async {
      const html = '''
<html><head><title>Pancakes</title></head><body>
<h1 class="recipe-title">Fluffy Pancakes</h1>
<div class="ingredients"><ul>
  <li>1 cup flour</li><li>1 cup milk</li><li>1 egg</li>
</ul></div>
<div class="instructions"><ol>
  <li>Whisk the flour and milk together in a bowl.</li>
  <li>Add the egg and stir until combined.</li>
  <li>Cook on a griddle until golden and serve warm.</li>
  <li>Combine with syrup and enjoy immediately.</li>
</ol></div>
</body></html>''';

      final result = await RecipeImportService(
        'https://example.com/pancakes',
        client: _clientReturning(html),
      ).call();

      expect(result.title, 'Fluffy Pancakes');
      expect(result.ingredients, ['1 cup flour', '1 cup milk', '1 egg']);
      expect(result.steps.length, 4);
    });

    test('throws a friendly error when nothing can be extracted', () async {
      const html = '<html><head><title>Blank</title></head><body></body></html>';
      expect(
        () => RecipeImportService('https://example.com/blank',
            client: _clientReturning(html)).call(),
        throwsA(isA<String>()),
      );
    });
  });
}
