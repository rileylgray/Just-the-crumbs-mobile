import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/category.dart';
import '../models/recipe.dart';
import '../providers/locale_provider.dart';
import '../services/measurement_converter.dart';
import '../theme/app_theme.dart';

/// Read-only rendering of a recipe's contents (title, meta, ingredients,
/// steps). Shared by the owner and public detail screens.
///
/// Ingredients and steps can be ticked off (with a strike-through) while
/// following along. A "cook mode" toggle scales the text up and keeps the
/// screen awake, and a units control converts measurements between metric and
/// imperial on the fly. All checkbox/cook-mode state is local to the widget, so
/// it resets as soon as the recipe screen is left.
class RecipeView extends ConsumerStatefulWidget {
  const RecipeView({
    super.key,
    required this.recipe,
    this.categoriesById = const {},
    this.footer,
  });

  final Recipe recipe;
  final Map<String, Category> categoriesById;
  final Widget? footer;

  @override
  ConsumerState<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<RecipeView> {
  /// Larger text and screen-always-on for hands-busy cooking.
  bool _cookMode = false;

  /// Indices of ingredients/steps the user has ticked off. Ingredients are
  /// indexed across all groups in flat order.
  final Set<int> _checkedIngredients = {};
  final Set<int> _checkedSteps = {};

  /// How much to scale up text when cook mode is on.
  static const double _cookModeScale = 1.3;

  @override
  void dispose() {
    // Never leave the screen forced awake after the user walks away.
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleCookMode(bool enabled) {
    setState(() => _cookMode = enabled);
    WakelockPlus.toggle(enable: enabled);
  }

  double _scaled(double size) => _cookMode ? size * _cookModeScale : size;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(measurementSystemProvider);
    final chips = recipe.categoryIds
        .map((id) => widget.categoriesById[id])
        .whereType<Category>()
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        40 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        _cookModeToggle(l10n),
        const SizedBox(height: 8),
        Text(
          recipe.title,
          style: TextStyle(
            fontSize: _scaled(26),
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recipeByAuthor(recipe.authorName),
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.colorValue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.name,
                      style: TextStyle(
                          color: c.colorValue, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
        if (recipe.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(recipe.description,
              style: TextStyle(fontSize: _scaled(16), height: 1.4)),
        ],
        const SizedBox(height: 20),
        _unitsToggle(l10n, units),
        const SizedBox(height: 20),
        _sectionTitle(l10n.ingredientsTitle),
        const SizedBox(height: 8),
        ..._ingredientList(units),
        const SizedBox(height: 24),
        _sectionTitle(l10n.stepsTitle),
        const SizedBox(height: 8),
        ...List.generate(
          recipe.steps.length,
          (i) => _stepRow(i, i + 1, convertMeasurements(recipe.steps[i], units)),
        ),
        if (recipe.sourceUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _openSource(recipe.sourceUrl),
            child: Text(
              l10n.recipeSource(recipe.sourceUrl),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
        ?widget.footer,
      ],
    );
  }

  /// Builds the ingredient rows across every group, keeping a running flat
  /// index so the checkbox state stays stable regardless of grouping. Group
  /// headings only show for multi-part recipes.
  List<Widget> _ingredientList(MeasurementSystem units) {
    final rows = <Widget>[];
    final groups = widget.recipe.ingredientGroups;
    final showHeadings = widget.recipe.hasIngredientGroups;
    var index = 0;
    for (final group in groups) {
      if (showHeadings && group.title.isNotEmpty) {
        rows.add(Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 12, bottom: 4),
          child: Text(
            group.title,
            style: TextStyle(
              fontSize: _scaled(16),
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ));
      }
      for (final item in group.items) {
        rows.add(_ingredientRow(index, convertMeasurements(item, units)));
        index++;
      }
    }
    return rows;
  }

  Widget _cookModeToggle(AppLocalizations l10n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _cookMode
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu,
                size: 20,
                color: _cookMode ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cookMode,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _cookMode ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  if (_cookMode)
                    Text(
                      l10n.cookModeOnHint,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            Switch(
              value: _cookMode,
              onChanged: _toggleCookMode,
            ),
          ],
        ),
      );

  /// Segmented control to switch the displayed measurements between the
  /// recipe's original text, metric and imperial. Persisted across recipes.
  Widget _unitsToggle(AppLocalizations l10n, MeasurementSystem units) {
    return Row(
      children: [
        const Icon(Icons.straighten, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          l10n.unitsLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const Spacer(),
        SegmentedButton<MeasurementSystem>(
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: _scaled(12))),
          ),
          segments: [
            ButtonSegment(
              value: MeasurementSystem.asWritten,
              label: Text(l10n.unitsAsWritten),
            ),
            ButtonSegment(
              value: MeasurementSystem.metric,
              label: Text(l10n.unitsMetric),
            ),
            ButtonSegment(
              value: MeasurementSystem.imperial,
              label: Text(l10n.unitsImperial),
            ),
          ],
          selected: {units},
          onSelectionChanged: (s) =>
              ref.read(measurementSystemProvider.notifier).set(s.first),
        ),
      ],
    );
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
          fontSize: _scaled(20),
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      );

  Widget _ingredientRow(int index, String text) {
    final checked = _checkedIngredients.contains(index);
    return InkWell(
      onTap: () => setState(() {
        checked
            ? _checkedIngredients.remove(index)
            : _checkedIngredients.add(index);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 10),
              child: Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                size: _scaled(18),
                color: checked ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: _scaled(16),
                  height: 1.35,
                  color: checked ? AppColors.textMuted : AppColors.text,
                  decoration:
                      checked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepRow(int index, int number, String text) {
    final checked = _checkedSteps.contains(index);
    final badgeSize = _scaled(26);
    return InkWell(
      onTap: () => setState(() {
        checked ? _checkedSteps.remove(index) : _checkedSteps.add(index);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.textMuted : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: checked
                  ? Icon(Icons.check, color: Colors.white, size: _scaled(15))
                  : Text('$number',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: _scaled(13))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: _scaled(16),
                    height: 1.4,
                    color: checked ? AppColors.textMuted : AppColors.text,
                    decoration: checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
