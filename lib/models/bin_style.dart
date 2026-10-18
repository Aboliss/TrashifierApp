import 'package:flutter/painting.dart';

/// One bin color and its variants. Keep in sync with the bin_color_* values
/// in android/app/src/main/res/values/colors.xml (home screen widgets).
class BinColor {
  /// Fill behind text and icons.
  final Color base;

  /// Pale tint, e.g. selected calendar days.
  final Color light;

  /// Brighter version for small marks (dots, bars) on dark surfaces, where
  /// dark bases would disappear. Not for backgrounds behind text.
  final Color onDark;

  /// Fill in dark mode, where a dark base would melt into the cards.
  final Color darkMode;

  /// Text and icons on [base]; keeps 4.5:1 contrast.
  final Color text;

  const BinColor({
    required this.base,
    required this.light,
    required this.onDark,
    required this.darkMode,
    required this.text,
  });
}

/// The fixed set of bin colors and icons people pick from. A set, not a free
/// picker, so every combination keeps its contrast and the Android widgets
/// can draw it.
class BinStyle {
  static const Color _ink = Color(0xFF16201B);
  static const Color _white = Color(0xFFFFFFFF);

  /// Indexes 0-3 are the built-in bins' colors (plastic, paper, trash, bio).
  static const List<BinColor> colors = [
    BinColor(
      base: Color(0xFFFFC83D),
      light: Color(0xFFFFE08A),
      onDark: Color(0xFFFFC83D),
      darkMode: Color(0xFFFFC83D),
      text: _ink,
    ),
    BinColor(
      base: Color(0xFF2F6BEA),
      light: Color(0xFF8DB0F5),
      onDark: Color(0xFF2F6BEA),
      darkMode: Color(0xFF2F6BEA),
      text: _white,
    ),
    BinColor(
      base: Color(0xFF454C55),
      light: Color(0xFF9AA2AB),
      onDark: Color(0xFF8E98A3),
      darkMode: Color(0xFF6B737D),
      text: _white,
    ),
    BinColor(
      base: Color(0xFF13804A),
      light: Color(0xFF7CCFA0),
      onDark: Color(0xFF2FB36E),
      darkMode: Color(0xFF13804A),
      text: _white,
    ),
    // Teal
    BinColor(
      base: Color(0xFF0B7F7B),
      light: Color(0xFF7FCFCB),
      onDark: Color(0xFF22B3AD),
      darkMode: Color(0xFF0B7F7B),
      text: _white,
    ),
    // Purple
    BinColor(
      base: Color(0xFF8E44AD),
      light: Color(0xFFC9A2DA),
      onDark: Color(0xFFB67AD1),
      darkMode: Color(0xFF8E44AD),
      text: _white,
    ),
    // Olive
    BinColor(
      base: Color(0xFF5A7A1C),
      light: Color(0xFFAFC57F),
      onDark: Color(0xFF8DB33F),
      darkMode: Color(0xFF5A7A1C),
      text: _white,
    ),
    // Brown
    BinColor(
      base: Color(0xFF8B5E3C),
      light: Color(0xFFC9A88E),
      onDark: Color(0xFFB98560),
      darkMode: Color(0xFF8B5E3C),
      text: _white,
    ),
    // Ochre
    BinColor(
      base: Color(0xFFE0A04A),
      light: Color(0xFFF0CF9F),
      onDark: Color(0xFFE0A04A),
      darkMode: Color(0xFFE0A04A),
      text: _ink,
    ),
    // Red
    BinColor(
      base: Color(0xFFC62F36),
      light: Color(0xFFE89A9D),
      onDark: Color(0xFFE5565C),
      darkMode: Color(0xFFC62F36),
      text: _white,
    ),
    // Pink
    BinColor(
      base: Color(0xFFC2185B),
      light: Color(0xFFE58FB1),
      onDark: Color(0xFFE04C86),
      darkMode: Color(0xFFC2185B),
      text: _white,
    ),
    // Sky
    BinColor(
      base: Color(0xFF6EC6F5),
      light: Color(0xFFB7E3FA),
      onDark: Color(0xFF6EC6F5),
      darkMode: Color(0xFF6EC6F5),
      text: _ink,
    ),
  ];

  /// Stroke paths on a 24-unit grid, one list per icon. Indexes 0-3 are the
  /// built-in bins' icons. The Android widgets use the same shapes
  /// (res/drawable/ic_bin_*.xml, in this order, see TrashifierWidget.kt).
  static const List<List<String>> icons = [
    // 0 bottle
    [
      'M10 2.5h4',
      'M10.5 2.5v2.8L8.2 8.6A2 2 0 0 0 8 9.6V19.5a2 2 0 0 0 2 2h4a2 2 0 0 0 '
          '2-2V9.6a2 2 0 0 0-.2-1L13.5 5.3V2.5',
      'M8 13h8',
    ],
    // 1 paper
    ['M6 3h8.5L19 7.5V21H6Z', 'M14 3v5h5', 'M9 13h7M9 17h5'],
    // 2 trash can
    [
      'M4 6.5h16',
      'M9 6.5V4h6v2.5',
      'M6.5 6.5 7.5 21h9l1-14.5M10 10.5v6.5M14 10.5v6.5',
    ],
    // 3 leaf
    [
      'M20 4C11 4 5 8.5 5 15.5c0 1.6.4 3 1 4.5 1.5.6 2.9 1 4.5 1C17 21 20 13 '
          '20 4Z',
      'M4 21c3-5 6.5-8.5 11-11',
    ],
    // 4 glass
    ['M7 3h10l-1 6a4 4 0 0 1-8 0Z', 'M12 13v7M8 21h8'],
    // 5 shirt
    ['M8 3 3 6l2 5 3-1v11h8V10l3 1 2-5-5-3c0 2-2 3-4 3S8 5 8 3Z'],
    // 6 tree
    ['M12 22v-7', 'M12 15c-4 0-6-3-6-6a6 6 0 0 1 12 0c0 3-2 6-6 6Z', 'M9 22h6'],
    // 7 sofa
    [
      'M4 11V8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3',
      'M3 11h18v6H3Z',
      'M5 17v3M19 17v3',
    ],
    // 8 box
    ['M3 7l9-4 9 4v10l-9 4-9-4Z', 'M3 7l9 4 9-4M12 11v10'],
    // 9 battery
    ['M6 7h12v13H6Z', 'M10 4h4v3', 'M12 11v6M9 14h6'],
    // 10 can
    ['M7 4h10v16H7Z', 'M7 8h10M7 16h10'],
    // 11 bag
    ['M5 8h14l-1 13H6Z', 'M9 8V6a3 3 0 0 1 6 0v2'],
    // 12 light bulb
    [
      'M9 18h6M10 21h4',
      'M12 3a6 6 0 0 0-4 10.5c1 1 1 2 1 3h6c0-1 0-2 1-3A6 6 0 0 0 12 3Z',
    ],
    // 13 recycle
    ['M20 12a8 8 0 1 1-3-6.2', 'M20 4v4h-4'],
    // 14 phone
    ['M8 2h8v20H8Z', 'M11 18h2'],
    // 15 drop
    ['M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11Z'],
  ];

  /// [index] clamped into [colors], so a bad stored value still draws.
  static BinColor color(int index) =>
      colors[index >= 0 && index < colors.length ? index : 0];

  static List<String> icon(int index) =>
      icons[index >= 0 && index < icons.length ? index : 0];
}
