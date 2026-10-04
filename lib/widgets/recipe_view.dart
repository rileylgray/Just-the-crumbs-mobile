import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/category.dart';
import '../models/recipe.dart';
import '../providers/locale_provider.dart';
import '../services/measurement_converter.dart';
import '../theme/app_theme.dart';
import 'category_chip.dart';

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
    HapticFeedback.selectionClick();
    setState(() => _cookMode = enabled);
    WakelockPlus.toggle(enable: enabled);
  }

  void _toggle(Set<int> checked, int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!checked.remove(index)) checked.add(index);
    });
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
        16,
        4,
        16,
        40 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: TextStyle(
                  fontSize: _scaled(26),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.recipeByAuthor(recipe.authorName),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final c in chips) CategoryChip(category: c)],
                ),
              ],
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  recipe.description,
                  style: TextStyle(
                    fontSize: _scaled(16),
                    height: 1.45,
                    color: AppColors.text,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _settingsCard(l10n, units),
        const SizedBox(height: 16),
        _Section(
          title: l10n.ingredientsTitle,
          titleSize: _scaled(19),
          checked: _checkedIngredients.length,
          total: recipe.ingredients.length,
          onUncheckAll: () => setState(_checkedIngredients.clear),
          uncheckAllTooltip: l10n.uncheckAll,
          extraAction: IconButton(
            tooltip: l10n.copyIngredients,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_all_outlined,
                size: 20, color: AppColors.textMuted),
            onPressed: () => _copyIngredients(l10n, units),
          ),
          children: _ingredientList(units),
        ),
        const SizedBox(height: 16),
        _Section(
          title: l10n.stepsTitle,
          titleSize: _scaled(19),
          checked: _checkedSteps.length,
          total: recipe.steps.length,
          onUncheckAll: () => setState(_checkedSteps.clear),
          uncheckAllTooltip: l10n.uncheckAll,
          children: [
            for (var i = 0; i < recipe.steps.length; i++)
              _stepRow(i, convertMeasurements(recipe.steps[i], units)),
          ],
        ),
        if (recipe.sourceUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sourceLink(l10n, recipe.sourceUrl),
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
          padding: EdgeInsets.fromLTRB(8, rows.isEmpty ? 0 : 12, 8, 4),
          child: Text(
            group.title,
            style: TextStyle(
              fontSize: _scaled(15),
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
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

  /// Puts the ingredient list on the clipboard — in the units currently
  /// shown, with part headings for multi-part recipes — ready to paste into a
  /// shopping list.
  Future<void> _copyIngredients(
    AppLocalizations l10n,
    MeasurementSystem units,
  ) async {
    final recipe = widget.recipe;
    final buffer = StringBuffer();
    for (final group in recipe.ingredientGroups) {
      if (recipe.hasIngredientGroups && group.title.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln(group.title);
      }
      for (final item in group.items) {
        buffer.writeln('• ${convertMeasurements(item, units)}');
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    HapticFeedback.lightImpact();
    messenger.showSnackBar(SnackBar(content: Text(l10n.ingredientsCopied)));
  }

  /// Cook mode and the units selector, grouped as "how to show this recipe".
  Widget _settingsCard(AppLocalizations l10n, MeasurementSystem units) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: _cookMode ? AppColors.primarySoft : null,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleCookMode(!_cookMode),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.soup_kitchen_outlined,
                      size: 22,
                      color: _cookMode
                          ? AppColors.primaryDeep
                          : AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cookMode,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _cookMode
                                ? AppColors.primaryDeep
                                : AppColors.text,
                          ),
                        ),
                        Text(
                          l10n.cookModeOnHint,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _cookMode, onChanged: _toggleCookMode),
                ],
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.straighten,
                        size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Text(
                      l10n.unitsLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Full width on its own row: three labels beside a heading
                // overflow a phone screen in longer languages.
                SegmentedButton<MeasurementSystem>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: _scaled(13),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  /// The recipe's source as a tappable domain ("seriouseats.com") rather than
  /// a full, often very long, URL.
  Widget _sourceLink(AppLocalizations l10n, String url) {
    final host = Uri.tryParse(url.trim())?.host.replaceFirst('www.', '');
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openSource(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: AppColors.primaryDeep),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.recipeSource(host == null || host.isEmpty ? url : host),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new,
                size: 16, color: AppColors.primaryDeep),
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _ingredientRow(int index, String text) {
    final checked = _checkedIngredients.contains(index);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggle(_checkedIngredients, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                size: _scaled(20),
                color: checked ? AppColors.primary : AppColors.inputBorder,
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

  Widget _stepRow(int index, String text) {
    final checked = _checkedSteps.contains(index);
    final badgeSize = _scaled(28);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggle(_checkedSteps, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: checked
                  ? Icon(Icons.check, color: Colors.white, size: _scaled(16))
                  : Text('${index + 1}',
                      style: TextStyle(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: _scaled(13))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: _scaled(16),
                    height: 1.45,
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

/// A white card holding one part of a recipe (ingredients or steps), with a
/// heading that shows how many items are ticked off and a quick "uncheck all".
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.titleSize,
    required this.checked,
    required this.total,
    required this.onUncheckAll,
    required this.uncheckAllTooltip,
    required this.children,
    this.extraAction,
  });

  final String title;
  final double titleSize;
  final int checked;
  final int total;
  final VoidCallback onUncheckAll;
  final String uncheckAllTooltip;
  final List<Widget> children;
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    final done = total > 0 && checked == total;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A minimum height so the heading doesn't jump as the progress
            // pill and the uncheck button appear.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  if (checked > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            done ? AppColors.primary : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$checked/$total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: done ? Colors.white : AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (checked > 0)
                    IconButton(
                      tooltip: uncheckAllTooltip,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.restart_alt,
                          size: 20, color: AppColors.textMuted),
                      onPressed: onUncheckAll,
                    ),
                  ?extraAction,
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
