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

  static Color getColorByType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return plasticColor;
      case TrashType.paper:
        return paperColor;
      case TrashType.trash:
        return trashColor;
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
    }
  }
}
