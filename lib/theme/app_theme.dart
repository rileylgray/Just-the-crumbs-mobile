import 'package:flutter/material.dart';

/// Warm "Just The Crumbs" brand palette, ported from the Rails app's CSS.
class AppColors {
  static const Color primary = Color(0xFFD4A574); // wheat / burnt sienna
  static const Color primaryDark = Color(0xFFC4935F);

  /// Deep crust brown for brand-colored *text* and icons. The wheat [primary]
  /// is a fill color: as text on a light surface it reads at roughly 2:1, so
  /// titles, section headings and text buttons use this instead.
  static const Color primaryDeep = Color(0xFF8B5E34);

  /// Pale wheat tint for selected states and soft accent fills.
  static const Color primarySoft = Color(0xFFF6EBDD);

  static const Color background = Color(0xFFFAF6F1); // warm cream
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFEDE3D8);
  static const Color inputBorder = Color(0xFFE2D6C8);
  static const Color danger = Color(0xFFDC3545);
  static const Color dangerDark = Color(0xFFC82333);
  static const Color success = Color(0xFF28A745);
  static const Color text = Color(0xFF2F2925);
  static const Color textMuted = Color(0xFF7A7068);

  /// Preset swatches offered when creating a category (hex strings).
  static const List<String> categorySwatches = [
    '#D4A574', '#E07A5F', '#81B29A', '#3D405B', '#F2CC8F',
    '#A8763E', '#6D6875', '#B5838D', '#457B9D', '#2A9D8F',
    '#E76F51', '#8D99AE',
  ];

  /// A legible foreground (text/icon) color to sit on a [background] fill.
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.5 ? text : Colors.white;

  /// [color] darkened enough to read as text on a pale tint of itself, so
  /// even the lightest category swatches stay legible.
  static Color ink(Color color) => Color.lerp(color, Colors.black, 0.35)!;
}

class AppTheme {
  static const double _radius = 16;
  static const double _controlRadius = 12;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      error: AppColors.danger,
      brightness: Brightness.light,
    ).copyWith(
      // Material 3 draws selected states (nav indicator, segmented buttons,
      // selected chips) from the containers, so pin them to the brand tint.
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.primaryDeep,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      // Strong enough for unselected controls (an off switch's thumb and
      // border); dividers and card edges use the paler outlineVariant.
      outline: const Color(0xFF9C8F84),
      outlineVariant: AppColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );

    // Component text styles start from the text theme, so they keep its font.
    final text = base.textTheme;

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_controlRadius),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x22000000),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AppColors.primaryDeep,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          shape: controlShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          side: const BorderSide(color: AppColors.inputBorder),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle:
            text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder(AppColors.inputBorder),
        enabledBorder: inputBorder(AppColors.inputBorder),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 2),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        checkmarkColor: AppColors.primaryDeep,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.inputBorder),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primaryDeep
                : AppColors.textMuted,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDeep
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDeep
                : AppColors.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.inputBorder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: text.titleLarge?.copyWith(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3A3029),
        contentTextStyle:
            text.bodyMedium?.copyWith(color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.primaryDeep),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primaryDeep,
        selectionColor: AppColors.primary.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
