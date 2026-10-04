// Widget tests for the shared UI pieces. They render with the app's real
// theme and localizations, but nothing here touches Firebase.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_the_crumbs_mobile/l10n/gen/app_localizations.dart';
import 'package:just_the_crumbs_mobile/models/category.dart';
import 'package:just_the_crumbs_mobile/models/recipe.dart';
import 'package:just_the_crumbs_mobile/providers/locale_provider.dart';
import 'package:just_the_crumbs_mobile/theme/app_theme.dart';
import 'package:just_the_crumbs_mobile/widgets/empty_state.dart';
import 'package:just_the_crumbs_mobile/widgets/recipe_card.dart';
import 'package:just_the_crumbs_mobile/widgets/recipe_view.dart';
import 'package:just_the_crumbs_mobile/widgets/search_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tart = Recipe(
  id: 'r1',
  userId: 'u1',
  authorName: 'Sam',
  title: 'lemon tart',
  description: 'Bright and sharp.',
  ingredientGroups: [
    IngredientGroup(title: 'Crust', items: ['1 cup flour', '100 g butter']),
    IngredientGroup(title: 'Filling', items: ['3 lemons']),
  ],
  steps: ['Make the crust.', 'Fill and bake.'],
  sourceUrl: 'https://www.example.com/lemon-tart?ref=feed',
  position: 0,
  isPublic: false,
  categoryIds: ['c1'],
);

const _dessert = Category(
  id: 'c1',
  userId: 'u1',
  name: 'Dessert',
  color: '#F2CC8F',
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A tall phone-width screen, so long views build without scrolling.
void _useTallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360 * 3, 2000 * 3);
  addTearDown(tester.view.reset);
}

void main() {
  group('Recipe.matchesSearch', () {
    test('matches title, description and ingredients, ignoring case', () {
      expect(_tart.matchesSearch('TART'), isTrue);
      expect(_tart.matchesSearch('sharp'), isTrue);
      expect(_tart.matchesSearch('Butter'), isTrue);
      expect(_tart.matchesSearch('chicken'), isFalse);
    });

    test('an empty or blank query matches everything', () {
      expect(_tart.matchesSearch(''), isTrue);
      expect(_tart.matchesSearch('   '), isTrue);
    });
  });

  testWidgets('EmptyState.fromText splits the headline from the detail',
      (tester) async {
    await _pump(
      tester,
      EmptyState.fromText('No categories yet.\nCreate one.',
          icon: Icons.label_outline),
    );
    expect(find.text('No categories yet.'), findsOneWidget);
    expect(find.text('Create one.'), findsOneWidget);
  });

  testWidgets('SearchField shows a clear button once text is entered',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await _pump(
      tester,
      SearchField(
        controller: controller,
        hintText: 'Search recipes',
        onChanged: changes.add,
      ),
    );

    expect(find.byTooltip('Clear'), findsNothing);
    await tester.enterText(find.byType(TextField), 'tart');
    await tester.pump();
    expect(find.byTooltip('Clear'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes.last, '');
    expect(find.byTooltip('Clear'), findsNothing);
  });

  testWidgets('RecipeCard lays out at phone width with monogram and category',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      RecipeCard(
        recipe: _tart,
        categoriesById: const {'c1': _dessert},
        showAuthor: true,
        showLanguage: true,
        showLikes: true,
        onTap: () {},
      ),
    );
    expect(find.text('L'), findsOneWidget);
    expect(find.text('Dessert'), findsOneWidget);
    expect(find.text('by Sam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RecipeView', () {
    // Leaving the view releases the wakelock, which has no platform side under
    // `flutter test`; answer its channel so disposal stays quiet.
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
    });

    testWidgets('ticking items shows progress and "uncheck all" resets it',
        (tester) async {
      _useTallPhone(tester);
      await _pump(tester, const RecipeView(recipe: _tart));

      expect(find.text('1/3'), findsNothing);
      await tester.tap(find.text('100 g butter'));
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);

      await tester.tap(find.byTooltip('Uncheck all'));
      await tester.pump();
      expect(find.text('1/3'), findsNothing);
      expect(find.byTooltip('Uncheck all'), findsNothing);
    });

    testWidgets('copies the ingredients grouped under their headings',
        (tester) async {
      _useTallPhone(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _pump(tester, const RecipeView(recipe: _tart));
      await tester.tap(find.byTooltip('Copy ingredients'));
      await tester.pump();

      expect(
        copied,
        'Crust\n• 1 cup flour\n• 100 g butter\n\nFilling\n• 3 lemons',
      );
      expect(find.text('Ingredients copied to the clipboard'), findsOneWidget);
    });

    testWidgets('shows the source as its domain', (tester) async {
      _useTallPhone(tester);
      await _pump(tester, const RecipeView(recipe: _tart));
      expect(find.text('Source: example.com'), findsOneWidget);
    });
  });
}
