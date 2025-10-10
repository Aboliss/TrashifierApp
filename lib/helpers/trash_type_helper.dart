import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_type.dart';

class TrashTypeHelper {
  static IconData getIcon(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return Icons.recycling;
      case TrashType.paper:
        return Icons.description;
      case TrashType.trash:
        return Icons.delete;
      case TrashType.bio:
        return Icons.eco;
    }
  }

  static Color getIconColor(TrashType type) {
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

  static Color getColor(TrashType type) {
    return TrashColors.getColorByType(type);
  }

  static Color getBackgroundColor(TrashType type) {
    return TrashColors.getBackgroundColorByType(type);
  }

  static Color getContainerColor(BuildContext context, TrashType type) {
    return TrashColors.getContainerColor(context, type);
  }

  static Color getContainerTextColor(BuildContext context, TrashType type) {
    return TrashColors.getContainerTextColor(context, type);
  }

  static String getNotificationTitle(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return 'Plastic Collection Reminder';
      case TrashType.paper:
        return 'Paper Collection Reminder';
      case TrashType.trash:
        return 'General Trash Reminder';
      case TrashType.bio:
        return 'Bio Waste Collection Reminder';
    }
  }

  static String getNotificationBody(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return 'Remember to take out your plastic trash!';
      case TrashType.paper:
        return 'Remember to take out your paper trash!';
      case TrashType.trash:
        return 'Remember to take out your trash!';
      case TrashType.bio:
        return 'Remember to take out your bio waste!';
    }
  }

  static bool shouldUseWhiteText(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return false;
      case TrashType.paper:
      case TrashType.trash:
      case TrashType.bio:
        return true;
    }
  }

  static List<TrashType> getAllTypes() {
    return TrashType.values;
  }
}
