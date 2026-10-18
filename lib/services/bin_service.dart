import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/widget_service.dart';

/// The user's bins (Settings › Bins): the four built-ins plus up to six
/// custom ones, in the user's order. Dates live in StorageService; deleting
/// a bin's dates is the caller's job.
class BinService extends ChangeNotifier {
  /// JSON list of bins; also read by the Android widgets
  /// (`flutter.bins`).
  static const String binsKey = 'bins';

  List<TrashType> _bins = TrashType.builtIns;
  final Completer<void> _loaded = Completer<void>();

  // Set once the user changes the bins; a list that finishes loading later
  // must not undo that.
  bool _changed = false;

  BinService() {
    _load();
  }

  /// Every bin in the user's order, hidden ones included.
  List<TrashType> get all => List.unmodifiable(_bins);

  /// The bins that show and remind.
  List<TrashType> get visible =>
      List.unmodifiable(_bins.where((type) => !type.hidden));

  bool get isFull => _bins.length >= TrashType.maxBins;

  /// Completes once the saved list has been read (or failed to).
  Future<void> get ready => _loaded.future;

  /// The current version of [type] (by id), or null if it was deleted.
  TrashType? find(TrashType type) =>
      _bins.where((bin) => bin == type).firstOrNull;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_changed) {
        final loaded = decode(prefs.getString(binsKey));
        if (!listEquals(_describe(loaded), _describe(_bins))) {
          _bins = loaded;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to load bins: $e');
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// The stored list, validated: bad entries, duplicate ids or slots and
  /// anything past [TrashType.maxBins] are dropped, and a missing built-in
  /// is added back at the end.
  static List<TrashType> decode(String? json) {
    if (json == null) return TrashType.builtIns;
    Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      return TrashType.builtIns;
    }
    if (data is! List) return TrashType.builtIns;

    final bins = <TrashType>[];
    for (final entry in data) {
      if (bins.length >= TrashType.maxBins) break;
      final bin = TrashType.fromJson(entry, bins.length);
      if (bin == null) continue;
      if (bins.any((b) => b.id == bin.id || b.slot == bin.slot)) continue;
      bins.add(bin);
    }
    for (final builtIn in TrashType.builtIns) {
      if (bins.contains(builtIn)) continue;
      // Make room: a built-in matters more than the last custom bin.
      if (bins.length >= TrashType.maxBins) bins.removeLast();
      bins.add(builtIn.copyWith(position: bins.length));
    }
    return _renumber(bins);
  }

  static String encode(List<TrashType> bins) =>
      jsonEncode([for (final bin in bins) bin.toJson()]);

  /// Adds a custom bin at the end; null when there are already
  /// [TrashType.maxBins] or the name is empty.
  Future<TrashType?> add({
    required String name,
    required int color,
    required int icon,
  }) async {
    final cleaned = TrashType.cleanName(name);
    if (isFull || cleaned == null) return null;
    final usedSlots = _bins.map((bin) => bin.slot).toSet();
    final slot = List.generate(TrashType.maxBins, (i) => i).firstWhere(
      (i) => i >= TrashType.builtIns.length && !usedSlots.contains(i),
    );
    final bin = TrashType(
      id: _newId(),
      slot: slot,
      position: _bins.length,
      customName: cleaned,
      color: color,
      icon: icon,
    );
    await _save([..._bins, bin]);
    return bin;
  }

  /// Replaces the bin with [updated]'s id (name, color, icon, hidden).
  Future<void> update(TrashType updated) async {
    final name = TrashType.cleanName(updated.customName);
    await _save([
      for (final bin in _bins)
        if (bin == updated)
          updated.copyWith(
            // A cleared name brings back a built-in's own name; a custom bin
            // can't lose its name (it would be dropped on the next load).
            customName: name ?? bin.customName,
            clearCustomName: name == null && updated.isBuiltIn,
          )
        else
          bin,
    ]);
  }

  Future<void> setHidden(TrashType type, bool hidden) async {
    final bin = find(type);
    if (bin == null || bin.hidden == hidden) return;
    await update(bin.copyWith(hidden: hidden));
  }

  /// Moves the bin at [oldIndex] to [newIndex] (indexes into [all], the
  /// way ReorderableListView reports them).
  Future<void> move(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _bins.length) return;
    final bins = [..._bins];
    final bin = bins.removeAt(oldIndex);
    final target = (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(
      0,
      bins.length,
    );
    bins.insert(target, bin);
    await _save(bins);
  }

  /// Removes a custom bin. Built-ins can only be hidden.
  Future<void> remove(TrashType type) async {
    if (type.isBuiltIn) return;
    await _save(_bins.where((bin) => bin != type).toList());
  }

  Future<void> _save(List<TrashType> bins) async {
    _changed = true;
    _bins = _renumber(bins);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(binsKey, encode(_bins));
    } catch (e) {
      debugPrint('Failed to save bins: $e');
    }
    // The widgets show bin colors, icons and names.
    await WidgetService.updateWidget();
  }

  static List<TrashType> _renumber(List<TrashType> bins) => [
    for (var i = 0; i < bins.length; i++) bins[i].copyWith(position: i),
  ];

  static final Random _random = Random.secure();

  static String _newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'c${List.generate(10, (_) => chars[_random.nextInt(chars.length)]).join()}';
  }

  /// What a bin looks like, to tell whether a reload changed anything.
  static List<String> _describe(List<TrashType> bins) => [
    for (final bin in bins) jsonEncode(bin.toJson()),
  ];
}

extension BinContext on BuildContext {
  /// The visible bins in the user's order; the built-ins when no BinService
  /// is provided (e.g. in widget tests). Rebuilds the caller on changes.
  List<TrashType> get visibleBins =>
      Provider.of<BinService?>(this)?.visible ?? TrashType.builtIns;
}
