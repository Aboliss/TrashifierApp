import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/l10n/l10n.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Names and texts of a bin: a custom name when the user set one, else the
/// built-in's translated name.
class TrashTypeHelper {
  static Color getColor(TrashType type) => TrashColors.getColorByType(type);

  static Color getContainerColor(BuildContext context, TrashType type) =>
      TrashColors.getContainerColor(context, type);

  static Color getContainerTextColor(BuildContext context, TrashType type) =>
      TrashColors.getContainerTextColor(context, type);

  static String getDisplayName(TrashType type) {
    final custom = type.customName;
    if (custom != null) return custom;
    final l = L10n.current;
    return switch (type.id) {
      'plastic' => l.binPlastic,
      'paper' => l.binPaper,
      'trash' => l.binTrash,
      'bio' => l.binBio,
      _ => type.id,
    };
  }

  /// Name for tight spots: chips, pills and calendar filters.
  static String getShortName(TrashType type) {
    final custom = type.customName;
    if (custom != null) return custom;
    final l = L10n.current;
    return switch (type.id) {
      'plastic' => l.binShortPlastic,
      'paper' => l.binShortPaper,
      'trash' => l.binShortTrash,
      'bio' => l.binShortBio,
      _ => type.id,
    };
  }

  /// What typically goes in a built-in bin (rules vary by town); custom bins
  /// have none.
  static String? getDescription(TrashType type) {
    if (type.customName != null) return null;
    final l = L10n.current;
    return switch (type.id) {
      'plastic' => l.binHintPlastic,
      'paper' => l.binHintPaper,
      'trash' => l.binHintTrash,
      'bio' => l.binHintBio,
      _ => null,
    };
  }

  static String getNotificationTitle(TrashType type) {
    final l = L10n.current;
    if (type.customName != null) {
      return l.notificationTitleCustom(type.customName!);
    }
    return switch (type.id) {
      'plastic' => l.notificationTitlePlastic,
      'paper' => l.notificationTitlePaper,
      'trash' => l.notificationTitleTrash,
      'bio' => l.notificationTitleBio,
      _ => l.notificationTitleCustom(type.id),
    };
  }

  static String getNotificationBody(TrashType type) {
    final l = L10n.current;
    if (type.customName != null) {
      return l.notificationBodyCustom(type.customName!);
    }
    return switch (type.id) {
      'plastic' => l.notificationBodyPlastic,
      'paper' => l.notificationBodyPaper,
      'trash' => l.notificationBodyTrash,
      'bio' => l.notificationBodyBio,
      _ => l.notificationBodyCustom(type.id),
    };
  }
}
