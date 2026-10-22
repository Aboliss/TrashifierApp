import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:trashifier_app/models/bin_style.dart';

/// A kind of bin: one of the four built-ins (plastic, paper, trash, bio) or
/// one the user added in Settings › Bins.
///
/// Two instances are equal when their [id] is, so a bin keeps finding its
/// dates in maps after it is renamed, re-colored or moved.
@immutable
class TrashType {
  /// Built-ins plus custom bins.
  static const int maxBins = 10;

  /// Longest name, in characters.
  static const int maxNameLength = 24;

  /// Longest name in UTF-8 bytes; a share link stores the length in one
  /// byte, and emoji can take many bytes each.
  static const int maxNameBytes = 96;

  /// "plastic", "paper", "trash", "bio", or "c" plus a few lowercase letters
  /// and digits for custom bins.
  final String id;

  /// 0-9, unique and stable for the bin's lifetime; part of reminder IDs.
  final int slot;

  /// Place in the user's order (Settings › Bins); sorts bins on a day.
  final int position;

  /// Set when the user named the bin; null shows the built-in's translated
  /// name.
  final String? customName;

  /// Index into [BinStyle.colors] and [BinStyle.icons].
  final int color;
  final int icon;

  /// Hidden bins keep their dates but don't show or remind.
  final bool hidden;

  const TrashType({
    required this.id,
    required this.slot,
    required this.position,
    this.customName,
    required this.color,
    required this.icon,
    this.hidden = false,
  });

  static const plastic = TrashType(
    id: 'plastic',
    slot: 0,
    position: 0,
    color: 0,
    icon: 0,
  );
  static const paper = TrashType(
    id: 'paper',
    slot: 1,
    position: 1,
    color: 1,
    icon: 1,
  );
  static const trash = TrashType(
    id: 'trash',
    slot: 2,
    position: 2,
    color: 2,
    icon: 2,
  );
  static const bio = TrashType(
    id: 'bio',
    slot: 3,
    position: 3,
    color: 3,
    icon: 3,
  );

  /// The four bins every install starts with.
  static const List<TrashType> builtIns = [plastic, paper, trash, bio];

  static final RegExp _customId = RegExp(r'^c[a-z0-9]{1,16}$');

  bool get isBuiltIn => builtIns.any((type) => type.id == id);

  /// Order key, so a list of bins sorts like Settings › Bins.
  int get index => position;

  /// SharedPreferences key of the bin's dates. Built-ins keep the keys the
  /// enum used, so existing dates survive. Also read by the Android widgets.
  String get storageKey => isBuiltIn ? 'TrashType.$id' : 'bin.$id';

  /// [name] cleaned up for storage: trimmed, control characters removed and
  /// cut to [maxNameLength]. Null when nothing is left.
  static String? cleanName(String? name) {
    if (name == null) return null;
    final cleaned = name
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return null;
    var chars = cleaned.characters.take(maxNameLength);
    while (utf8.encode(chars.toString()).length > maxNameBytes) {
      chars = chars.take(chars.length - 1);
    }
    final result = chars.toString().trim();
    return result.isEmpty ? null : result;
  }

  static bool isValidId(String id) =>
      builtIns.any((type) => type.id == id) || _customId.hasMatch(id);

  TrashType copyWith({
    int? position,
    String? customName,
    bool clearCustomName = false,
    int? color,
    int? icon,
    bool? hidden,
  }) {
    return TrashType(
      id: id,
      slot: slot,
      position: position ?? this.position,
      customName: clearCustomName ? null : (customName ?? this.customName),
      color: color ?? this.color,
      icon: icon ?? this.icon,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'slot': slot,
    if (customName != null) 'name': customName,
    'color': color,
    'icon': icon,
    if (hidden) 'hidden': true,
  };

  /// Reads one stored bin; null when anything is missing or out of range.
  /// [position] comes from the bin's place in the stored list.
  static TrashType? fromJson(Object? json, int position) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final slot = json['slot'];
    final color = json['color'];
    final icon = json['icon'];
    final hidden = json['hidden'] ?? false;
    final name = json['name'];
    if (id is! String || !isValidId(id)) return null;
    if (slot is! int || slot < 0 || slot >= maxBins) return null;
    if (color is! int || color < 0 || color >= BinStyle.colors.length) {
      return null;
    }
    if (icon is! int || icon < 0 || icon >= BinStyle.icons.length) return null;
    if (hidden is! bool) return null;
    if (name != null && name is! String) return null;
    final builtIn = builtIns.where((type) => type.id == id).firstOrNull;
    // A built-in always keeps its slot; custom bins can't take 0-3.
    if (builtIn != null ? slot != builtIn.slot : slot < builtIns.length) {
      return null;
    }
    final customName = cleanName(name as String?);
    if (builtIn == null && customName == null) return null;
    return TrashType(
      id: id,
      slot: slot,
      position: position,
      customName: customName,
      color: color,
      icon: icon,
      hidden: hidden,
    );
  }

  @override
  bool operator ==(Object other) => other is TrashType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TrashType.$id';
}
