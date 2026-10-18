import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// How an imported schedule's bins map onto the user's bins.
class ImportMatch {
  /// Incoming bin → the user's bin that gets its dates.
  final Map<TrashType, TrashType> existing;

  /// Incoming custom bins the user doesn't have; created on import, one
  /// per name.
  final List<TrashType> toCreate;

  /// Further incoming bins with the name of one in [toCreate]; their dates
  /// go to that new bin.
  final Map<TrashType, TrashType> sameAsNew;

  /// Incoming custom bins that don't fit under [TrashType.maxBins]; their
  /// dates are skipped.
  final List<TrashType> noRoom;

  const ImportMatch({
    required this.existing,
    required this.toCreate,
    required this.noRoom,
    this.sameAsNew = const {},
  });

  /// Matches every incoming bin that has dates. Built-ins go to the same
  /// built-in; custom bins to the user's bin with the same id (a backup of
  /// this phone), else with the same name (ignoring case), else they are
  /// created while there is room.
  static ImportMatch of(Schedule schedule, List<TrashType> userBins) {
    String key(TrashType type) =>
        TrashTypeHelper.getDisplayName(type).trim().toLowerCase();

    final existing = <TrashType, TrashType>{};
    final toCreate = <TrashType>[];
    final sameAsNew = <TrashType, TrashType>{};
    final noRoom = <TrashType>[];
    for (final entry in schedule.dates.entries) {
      if (entry.value.isEmpty) continue;
      final incoming = entry.key;
      final match =
          userBins.where((bin) => bin.id == incoming.id).firstOrNull ??
          (incoming.isBuiltIn
              ? null
              : userBins.where((bin) => key(bin) == key(incoming)).firstOrNull);
      final twin = incoming.isBuiltIn
          ? null
          : toCreate.where((bin) => key(bin) == key(incoming)).firstOrNull;
      if (match != null) {
        existing[incoming] = match;
      } else if (twin != null) {
        sameAsNew[incoming] = twin;
      } else if (incoming.isBuiltIn) {
        // Every install has the built-ins; only a broken list lacks one.
        noRoom.add(incoming);
      } else if (userBins.length + toCreate.length < TrashType.maxBins) {
        toCreate.add(incoming);
      } else {
        noRoom.add(incoming);
      }
    }
    return ImportMatch(
      existing: existing,
      toCreate: toCreate,
      noRoom: noRoom,
      sameAsNew: sameAsNew,
    );
  }
}
