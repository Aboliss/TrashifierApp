import 'package:flutter/material.dart';
import 'package:trashifier_app/models/trash_type.dart';

class TrashColors {
  // Plastic colors
  static final plasticColor = Colors.yellow.shade600;
  static final plasticColorLight = Colors.yellow.shade300;

  // Paper colors
  static final paperColor = Colors.blue.shade600;
  static final paperColorLight = Colors.blue.shade300;

  // Trash colors
  static final trashColor = Colors.grey.shade600;
  static final trashColorLight = Colors.grey.shade500;

  // Bio colors
  static final bioColor = Colors.green.shade800;
  static final bioColorLight = Colors.green.shade400;

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

  static Color getBackgroundColorByType(TrashType type) {
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

  static Color getTextColorForType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return Colors.black;
      case TrashType.paper:
        return Colors.white;
      case TrashType.trash:
        return Colors.white;
      case TrashType.bio:
        return Colors.white;
    }
  }

  static Color getContainerColor(BuildContext context, TrashType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case TrashType.plastic:
        return isDark ? plasticColor.withValues(alpha: 0.8) : plasticColor;
      case TrashType.paper:
        return isDark ? paperColor.withValues(alpha: 0.8) : paperColor;
      case TrashType.trash:
        return isDark ? trashColor.withValues(alpha: 0.8) : trashColor;
      case TrashType.bio:
        return isDark ? bioColor.withValues(alpha: 0.8) : bioColor;
    }
  }

  static Color getContainerTextColor(BuildContext context, TrashType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case TrashType.plastic:
        return isDark ? Colors.black87 : Colors.black;
      case TrashType.paper:
        return Colors.white;
      case TrashType.trash:
        return Colors.white;
      case TrashType.bio:
        return Colors.white;
    }
  }
}
