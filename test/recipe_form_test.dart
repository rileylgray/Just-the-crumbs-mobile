// The recipe form's ingredient rows: a pasted list splits into one row per
// ingredient. Firebase-backed providers are overridden, so nothing here
// touches the network.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_the_crumbs_mobile/l10n/gen/app_localizations.dart';
import 'package:just_the_crumbs_mobile/models/category.dart';
import 'package:just_the_crumbs_mobile/providers/locale_provider.dart';
import 'package:just_the_crumbs_mobile/providers/providers.dart';
import 'package:just_the_crumbs_mobile/screens/recipes/recipe_form_screen.dart';
import 'package:just_the_crumbs_mobile/services/import/ingredient_grouping.dart';
import 'package:just_the_crumbs_mobile/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpForm(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360 * 3, 2000 * 3);
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        userCategoriesProvider
            .overrideWith((ref) => Stream.value(const <Category>[])),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RecipeFormScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The text of every ingredient row, in order.
List<String> _ingredientRows(WidgetTester tester) => tester
    .widgetList<TextField>(find.byType(TextField))
    .where((f) => f.decoration?.hintText == 'e.g. 2 cups flour')
    .map((f) => f.controller!.text)
    .toList();

void main() {
  group('ingredientLines', () {
    test('splits on line breaks and drops list markers and blanks', () {
      expect(
        ingredientLines('• 2 cups flour\r\n\n- 1 tsp salt\n▢ 3 eggs\n[ ] milk'),
        ['2 cups flour', '1 tsp salt', '3 eggs', 'milk'],
      );
    });

    test('leaves quantities alone', () {
      expect(ingredientLines('1 cup sugar\n½ tsp vanilla'),
          ['1 cup sugar', '½ tsp vanilla']);
    });
  });

  testWidgets('a list pasted into one row becomes a row per ingredient',
      (tester) async {
    await _pumpForm(tester);
    expect(_ingredientRows(tester), ['']);

    final firstRow = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'e.g. 2 cups flour');
    await tester.enterText(firstRow, '• 2 cups flour\n• 1 tsp salt\n• 3 eggs');
    await tester.pump();

    expect(_ingredientRows(tester), ['2 cups flour', '1 tsp salt', '3 eggs']);
  });

  testWidgets('a line break at the end starts the next ingredient',
      (tester) async {
    await _pumpForm(tester);
    final firstRow = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'e.g. 2 cups flour');
    await tester.enterText(firstRow, '2 cups flour\n');
    await tester.pump();

    expect(_ingredientRows(tester), ['2 cups flour', '']);
  });
}
