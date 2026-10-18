import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/l10n/l10n.dart';

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

  static String getDisplayName(TrashType type) {
    final l = L10n.current;
    switch (type) {
      case TrashType.plastic:
        return l.binPlastic;
      case TrashType.paper:
        return l.binPaper;
      case TrashType.trash:
        return l.binTrash;
      case TrashType.bio:
        return l.binBio;
    }
  }

  /// Name for tight spots: chips, pills and calendar filters.
  static String getShortName(TrashType type) {
    final l = L10n.current;
    switch (type) {
      case TrashType.plastic:
        return l.binShortPlastic;
      case TrashType.paper:
        return l.binShortPaper;
      case TrashType.trash:
        return l.binShortTrash;
      case TrashType.bio:
        return l.binShortBio;
    }
  }

  /// What typically goes in the bin. Kept general: rules vary by town.
  static String getDescription(TrashType type) {
    final l = L10n.current;
    switch (type) {
      case TrashType.plastic:
        return l.binHintPlastic;
      case TrashType.paper:
        return l.binHintPaper;
      case TrashType.trash:
        return l.binHintTrash;
      case TrashType.bio:
        return l.binHintBio;
    }
  }

  static String getNotificationTitle(TrashType type) {
    final l = L10n.current;
    switch (type) {
      case TrashType.plastic:
        return l.notificationTitlePlastic;
      case TrashType.paper:
        return l.notificationTitlePaper;
      case TrashType.trash:
        return l.notificationTitleTrash;
      case TrashType.bio:
        return l.notificationTitleBio;
    }
  }

  static String getNotificationBody(TrashType type) {
    final l = L10n.current;
    switch (type) {
      case TrashType.plastic:
        return l.notificationBodyPlastic;
      case TrashType.paper:
        return l.notificationBodyPaper;
      case TrashType.trash:
        return l.notificationBodyTrash;
      case TrashType.bio:
        return l.notificationBodyBio;
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
