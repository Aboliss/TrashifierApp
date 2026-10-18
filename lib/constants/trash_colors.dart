import 'package:flutter/material.dart';
import 'package:trashifier_app/models/bin_style.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Bin colors. The four built-in colors stay named constants for Bin Buddy's
/// stripes; a bin's colors come from its [TrashType.color] (see BinStyle).
/// Keep in sync with android/app/src/main/res/values/colors.xml.
class TrashColors {
  // Text on these keeps 4.5:1 contrast: ink on plastic, white on the rest.
  static const plasticColor = Color(0xFFFFC83D);
  static const paperColor = Color(0xFF2F6BEA);
  static const trashColor = Color(0xFF454C55);
  static const bioColor = Color(0xFF13804A);

  static const plasticColorLight = Color(0xFFFFE08A);
  static const paperColorLight = Color(0xFF8DB0F5);
  static const trashColorLight = Color(0xFF9AA2AB);
  static const bioColorLight = Color(0xFF7CCFA0);

  // Brighter trash and bio for marks on dark surfaces, where the base colors
  // would disappear. Not for backgrounds behind text.
  static const trashOnDark = Color(0xFF8E98A3);
  static const bioOnDark = Color(0xFF2FB36E);

  // Dark mode cards are nearly as dark as trashColor itself.
  static const trashColorDarkMode = Color(0xFF6B737D);

  static Color getColorByType(TrashType type) =>
      BinStyle.color(type.color).base;

  static Color getLightColorByType(TrashType type) =>
      BinStyle.color(type.color).light;

  static Color getBackgroundColorByType(TrashType type) => getColorByType(type);

  /// Color for small marks (dots, bars, stripes) drawn on a dark surface.
  static Color getMarkColorOnDark(TrashType type) =>
      BinStyle.color(type.color).onDark;

  static Color getTextColorForType(TrashType type) =>
      BinStyle.color(type.color).text;

  /// Background for a bin-colored element in the current theme.
  static Color getContainerColor(BuildContext context, TrashType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = BinStyle.color(type.color);
    return isDark ? color.darkMode : color.base;
  }

  /// Text and icon color on [getContainerColor].
  static Color getContainerTextColor(BuildContext context, TrashType type) {
    return getTextColorForType(type);
  }
}
