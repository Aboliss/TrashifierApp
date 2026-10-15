import 'package:flutter/material.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Bin colors. Keep in sync with android/app/src/main/res/values/colors.xml,
/// which the home screen widgets use.
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

  static Color getColorByType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return plasticColor;
      case TrashType.paper:
        return paperColor;
      case TrashType.trash:
        return trashColor;
      case TrashType.bio:
        return bioColor;
    }
  }

  static Color getLightColorByType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return plasticColorLight;
      case TrashType.paper:
        return paperColorLight;
      case TrashType.trash:
        return trashColorLight;
      case TrashType.bio:
        return bioColorLight;
    }
  }

  static Color getBackgroundColorByType(TrashType type) => getColorByType(type);

  /// Color for small marks (dots, bars, stripes) drawn on a dark surface.
  static Color getMarkColorOnDark(TrashType type) {
    switch (type) {
      case TrashType.trash:
        return trashOnDark;
      case TrashType.bio:
        return bioOnDark;
      case TrashType.plastic:
      case TrashType.paper:
        return getColorByType(type);
    }
  }

  static Color getTextColorForType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return const Color(0xFF16201B);
      case TrashType.paper:
      case TrashType.trash:
      case TrashType.bio:
        return Colors.white;
    }
  }

  /// Background for a bin-colored element in the current theme.
  static Color getContainerColor(BuildContext context, TrashType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark && type == TrashType.trash) return trashColorDarkMode;
    return getColorByType(type);
  }

  /// Text and icon color on [getContainerColor].
  static Color getContainerTextColor(BuildContext context, TrashType type) {
    return getTextColorForType(type);
  }
}
