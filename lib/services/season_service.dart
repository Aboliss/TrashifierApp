import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/helpers/season_helper.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/services/widget_service.dart';

/// Spots on the screens where a Halloween decoration may appear. Each is
/// clear of text.
enum DecorAnchor {
  header,
  heroPerch,
  heroSky,
  weekTitle,
  comingUpTitle,
  calendarHeader,
  addSheet,
}

enum DecorKind { ghost, spider, pumpkin }

/// The active seasonal theme, and the debug override that can force one.
class SeasonService extends ChangeNotifier {
  /// Also read by the Android widgets (as `flutter.season_override`).
  static const String overrideKey = 'season_override';

  static const Map<DecorAnchor, List<DecorKind>> _allowedDecor = {
    // Spiders hang from the top of a row; ghosts float anywhere.
    DecorAnchor.header: [DecorKind.ghost, DecorKind.spider],
    DecorAnchor.heroPerch: [DecorKind.pumpkin],
    DecorAnchor.heroSky: [DecorKind.ghost],
    DecorAnchor.weekTitle: [DecorKind.ghost, DecorKind.pumpkin],
    DecorAnchor.comingUpTitle: [DecorKind.pumpkin, DecorKind.ghost],
    DecorAnchor.calendarHeader: [DecorKind.ghost, DecorKind.spider],
    DecorAnchor.addSheet: [
      DecorKind.spider,
      DecorKind.ghost,
      DecorKind.pumpkin,
    ],
  };

  final DateTime Function() _now;
  SeasonOverride _override = SeasonOverride.auto;

  // Set once the user picks an override; a saved value that finishes loading
  // later must not undo that choice.
  bool _overrideChosen = false;
  late Season _season = SeasonHelper.seasonFor(_now(), _override);

  /// Which Halloween decoration sits on each anchor; rolled once per app
  /// start so it looks random but doesn't jump around while in use.
  final Map<DecorAnchor, DecorKind> decor;

  SeasonService({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      decor = Map.unmodifiable(_rollDecor(random ?? Random())) {
    _load();
  }

  SeasonOverride get override => _override;
  Season get season => _season;
  BuddyCostume get costume => SeasonHelper.costumeFor(_season);

  static Map<DecorAnchor, DecorKind> _rollDecor(Random random) {
    final picks = <DecorAnchor, DecorKind>{};
    for (final entry in _allowedDecor.entries) {
      if (random.nextDouble() < 0.4) continue;
      final kinds = entry.value;
      picks[entry.key] = kinds[random.nextInt(kinds.length)];
    }
    return picks;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_overrideChosen) return;
      _override = SeasonHelper.decodeOverride(prefs.getString(overrideKey));
      _update(notify: true);
    } catch (e) {
      debugPrint('Failed to load season override: $e');
    }
  }

  /// Re-checks the date, e.g. when the app comes back on the first of a
  /// month.
  void refresh() => _update();

  Future<void> setOverride(SeasonOverride override) async {
    _overrideChosen = true;
    if (override == _override) return;
    _override = override;
    // The debug panel shows the override even when the season stays the same.
    _update(notify: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(overrideKey, SeasonHelper.encodeOverride(override));
    } catch (e) {
      debugPrint('Failed to save season override: $e');
    }
    // The widgets read the override too.
    await WidgetService.updateWidget();
  }

  void _update({bool notify = false}) {
    final season = SeasonHelper.seasonFor(_now(), _override);
    if (season == _season && !notify) return;
    _season = season;
    notifyListeners();
  }
}

extension SeasonContext on BuildContext {
  /// The active season; [Season.none] when no SeasonService is provided
  /// (e.g. in widget tests). Rebuilds the caller when it changes.
  Season get season => Provider.of<SeasonService?>(this)?.season ?? Season.none;

  BuddyCostume get buddyCostume => SeasonHelper.costumeFor(season);
}
