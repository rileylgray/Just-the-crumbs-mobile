import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/public/public_feed_screen.dart';
import '../screens/public/public_recipe_detail_screen.dart';
import '../screens/recipes/import_screen.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import '../screens/recipes/recipe_form_screen.dart';
import '../screens/recipes/recipes_list_screen.dart';
import '../screens/recipes/shared_recipe_screen.dart';
import '../services/import/recipe_import_service.dart';
import '../widgets/scaffold_with_nav.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/recipes',
  // A location that matches nothing throws by default, which in a release build
  // means a broken app rather than a broken link. Land on the recipe list
  // instead — routes here are reached from deep links and share sheets, so bad
  // input arrives from outside the app.
  onException: (context, state, router) {
    debugPrint('No route for ${state.uri}: ${state.error}');
    router.go('/recipes');
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellKey,
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipesListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/public',
              builder: (context, state) => const PublicFeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Full-screen routes (outside the bottom nav).
    GoRoute(
      path: '/recipes/new',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          RecipeFormScreen(initial: state.extra as ImportedRecipe?),
    ),
    // `?url=` is set when the screen is opened from a share sheet
    // (justthecrumbs://import) — see CrumbsApp's deep-link handling.
    GoRoute(
      path: '/recipes/import',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          ImportScreen(initialUrl: state.uri.queryParameters['url']),
    ),
    GoRoute(
      path: '/recipes/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          RecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipes/:id/edit',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          RecipeFormScreen(recipeId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/categories/new',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const CategoryFormScreen(),
    ),
    GoRoute(
      path: '/categories/:id/edit',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          CategoryFormScreen(categoryId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/public/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          PublicRecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
    // Deep-link / paste target: justthecrumbs://share/:code
    GoRoute(
      path: '/share/:code',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          SharedRecipeScreen(code: state.pathParameters['code']!),
    ),
  ],
);
