import 'package:flutter/material.dart';
import 'package:trashifier_app/models/season.dart';

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

  /// The round + button in the bottom bar.
  final Color fab;
  final Color fabInk;

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
    this.fab = const Color(0xFFFFC83D),
    this.fabInk = const Color(0xFF16201B),
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

  // Seasonal looks: Halloween night purple with pumpkin orange, Christmas
  // pine green with red.
  static const halloweenLight = AppPalette(
    ground: Color(0xFFF7F1E8),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF20152A),
    muted: Color(0xFF5D5268),
    chip: Color(0xFFEEE6F2),
    line: Color(0xFFE2D8E8),
    hero: Color(0xFF2B1838),
    heroInk: Color(0xFFFBF4FF),
    heroMuted: Color(0xFFCDB8DB),
    nav: Color(0xFF20152A),
    navInk: Color(0xFFD3C6DD),
    navActive: Color(0xFFF7F1E8),
    navActiveInk: Color(0xFF20152A),
    fab: Color(0xFFF2852B),
    fabInk: Color(0xFF20152A),
  );

  static const halloweenDark = AppPalette(
    ground: Color(0xFF120C18),
    card: Color(0xFF1F1628),
    ink: Color(0xFFF4EDF8),
    muted: Color(0xFFB6A9C2),
    chip: Color(0xFF2C2136),
    line: Color(0xFF3A2D45),
    hero: Color(0xFF2E1D3D),
    heroInk: Color(0xFFFBF4FF),
    heroMuted: Color(0xFFCDB8DB),
    nav: Color(0xFF22182C),
    navInk: Color(0xFFD3C6DD),
    navActive: Color(0xFFF4EDF8),
    navActiveInk: Color(0xFF120C18),
    fab: Color(0xFFF2852B),
    fabInk: Color(0xFF20152A),
  );

  static const christmasLight = AppPalette(
    ground: Color(0xFFF2F6F2),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF13261C),
    muted: Color(0xFF4F6158),
    chip: Color(0xFFE4EDE7),
    line: Color(0xFFD5E0D9),
    hero: Color(0xFF14402B),
    heroInk: Color(0xFFFFF8EC),
    heroMuted: Color(0xFFCFE3D6),
    nav: Color(0xFF13261C),
    navInk: Color(0xFFC9D9CF),
    navActive: Color(0xFFF2F6F2),
    navActiveInk: Color(0xFF13261C),
    fab: Color(0xFFD3343A),
    fabInk: Color(0xFFFFFFFF),
  );

  static const christmasDark = AppPalette(
    ground: Color(0xFF0D1712),
    card: Color(0xFF16231C),
    ink: Color(0xFFEEF5F0),
    muted: Color(0xFFA7BAAF),
    chip: Color(0xFF213029),
    line: Color(0xFF2E3F36),
    hero: Color(0xFF1A3A2A),
    heroInk: Color(0xFFFFF8EC),
    heroMuted: Color(0xFFCFE3D6),
    nav: Color(0xFF1A2620),
    navInk: Color(0xFFC9D9CF),
    navActive: Color(0xFFEEF5F0),
    navActiveInk: Color(0xFF0D1712),
    fab: Color(0xFFD3343A),
    fabInk: Color(0xFFFFFFFF),
  );

  static AppPalette of(Season season, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (season) {
      case Season.halloween:
        return dark ? halloweenDark : halloweenLight;
      case Season.christmas:
        return dark ? christmasDark : christmasLight;
      case Season.none:
        return dark ? AppPalette.dark : AppPalette.light;
    }
  }

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
      fab: mix(fab, other.fab),
      fabInk: mix(fabInk, other.fabInk),
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
  static ThemeData lightTheme([Season season = Season.none]) =>
      _build(Brightness.light, AppPalette.of(season, Brightness.light));

  static ThemeData darkTheme([Season season = Season.none]) =>
      _build(Brightness.dark, AppPalette.of(season, Brightness.dark));

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
