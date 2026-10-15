import 'package:flutter/material.dart';

/// Surface and text colors of the Bin Buddy design, for light and dark mode.
///
/// Bin colors live in TrashColors; everything else is read from here via
/// `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Page background.
  final Color ground;

  /// Cards on the page.
  final Color card;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text. Keeps 4.5:1 contrast on [ground] and [card].
  final Color muted;

  /// Chips, round icon buttons and badges.
  final Color chip;

  /// Outlines of unselected controls.
  final Color line;

  /// The dark "next pickup" card and its text.
  final Color hero;
  final Color heroInk;
  final Color heroMuted;

  /// The floating bottom bar.
  final Color nav;
  final Color navInk;
  final Color navActive;
  final Color navActiveInk;

  const AppPalette({
    required this.ground,
    required this.card,
    required this.ink,
    required this.muted,
    required this.chip,
    required this.line,
    required this.hero,
    required this.heroInk,
    required this.heroMuted,
    required this.nav,
    required this.navInk,
    required this.navActive,
    required this.navActiveInk,
  });

  static const light = AppPalette(
    ground: Color(0xFFF4F5EF),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF16201B),
    muted: Color(0xFF56635C),
    chip: Color(0xFFEBEFE6),
    line: Color(0xFFDDE2D8),
    hero: Color(0xFF16201B),
    heroInk: Color(0xFFF4F5EF),
    heroMuted: Color(0xFFB9C6BF),
    nav: Color(0xFF16201B),
    navInk: Color(0xFFC9D4CD),
    navActive: Color(0xFFF4F5EF),
    navActiveInk: Color(0xFF16201B),
  );

  static const dark = AppPalette(
    ground: Color(0xFF0F1512),
    card: Color(0xFF1A231E),
    ink: Color(0xFFEEF3EF),
    muted: Color(0xFFA3B1A9),
    chip: Color(0xFF26312B),
    line: Color(0xFF34413A),
    hero: Color(0xFF22302A),
    heroInk: Color(0xFFF4F5EF),
    heroMuted: Color(0xFFB9C6BF),
    nav: Color(0xFF1F2924),
    navInk: Color(0xFFC9D4CD),
    navActive: Color(0xFFEEF3EF),
    navActiveInk: Color(0xFF0F1512),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      ground: mix(ground, other.ground),
      card: mix(card, other.card),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      chip: mix(chip, other.chip),
      line: mix(line, other.line),
      hero: mix(hero, other.hero),
      heroInk: mix(heroInk, other.heroInk),
      heroMuted: mix(heroMuted, other.heroMuted),
      nav: mix(nav, other.nav),
      navInk: mix(navInk, other.navInk),
      navActive: mix(navActive, other.navActive),
      navActiveInk: mix(navActiveInk, other.navActiveInk),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Font families bundled in assets/fonts (see pubspec.yaml).
class AppFonts {
  /// Headlines and big numbers.
  static const String display = 'BricolageGrotesque';

  /// Everything else.
  static const String body = 'Figtree';

  /// Headline style: Bricolage Grotesque, extra bold, tight tracking.
  static TextStyle headline(double size, Color color) => TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w800,
    fontSize: size,
    height: 1.05,
    letterSpacing: -0.03 * size,
    color: color,
  );

  /// Small uppercase label, e.g. "NEXT PICKUP".
  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 1.4,
    color: color,
  );
}

class AppTheme {
  static ThemeData lightTheme() => _build(Brightness.light, AppPalette.light);

  static ThemeData darkTheme() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF13804A),
          brightness: brightness,
        ).copyWith(
          primary: palette.ink,
          onPrimary: palette.ground,
          surface: palette.ground,
          onSurface: palette.ink,
          surfaceContainerHighest: palette.chip,
          outline: palette.line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: palette.ground,
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.ground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.ground,
        modalBackgroundColor: palette.ground,
        showDragHandle: true,
        dragHandleColor: palette.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.ink),
      ),
      extensions: [palette],
    );
  }
}
