import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/helpers/schedule_import.dart';
import 'package:trashifier_app/models/trash_type.dart';

TrashType custom(String id, String name, {int slot = 4}) => TrashType(
  id: id,
  slot: slot,
  position: slot,
  customName: name,
  color: 5,
  icon: 6,
);

/// [bins] with one date each, after the four (empty) built-ins, like a
/// decoded schedule.
Schedule scheduleOf(Map<TrashType, int> counts) => Schedule({
  for (final type in TrashType.builtIns) type: <DateTime>[],
  for (final entry in counts.entries)
    entry.key: [for (var i = 0; i < entry.value; i++) DateTime(2026, 1, 1 + i)],
});

/// The user's bins: the built-ins plus [extra] custom ones.
List<TrashType> userBinsWith(int extra) => [
  ...TrashType.builtIns,
  for (var i = 0; i < extra; i++) custom('cuser$i', 'User $i', slot: 4 + i),
];

void main() {
  group('ImportMatch.of', () {
    test('built-ins go to the same built-in, renamed or hidden', () {
      final userBins = [
        TrashType.plastic.copyWith(customName: 'Yellow bag', hidden: true),
        TrashType.paper,
        TrashType.trash,
        TrashType.bio,
      ];
      final match = ImportMatch.of(
        scheduleOf({TrashType.plastic: 2, TrashType.bio: 1}),
        userBins,
      );
      expect(match.existing.length, 2);
      expect(match.existing[TrashType.plastic]!.customName, 'Yellow bag');
      expect(match.existing[TrashType.bio], TrashType.bio);
      expect(match.toCreate, isEmpty);
      expect(match.noRoom, isEmpty);
    });

    test('bins without dates are left out', () {
      final match = ImportMatch.of(
        scheduleOf({TrashType.paper: 1, custom('cq1', 'Glass'): 0}),
        TrashType.builtIns,
      );
      expect(match.existing.keys, [TrashType.paper]);
      expect(match.toCreate, isEmpty);
      expect(match.noRoom, isEmpty);
    });

    test('a custom bin with the same id matches (own backup)', () {
      final mine = custom('cglass', 'Glass');
      final incoming = custom('cglass', 'Bottles', slot: 6);
      final match = ImportMatch.of(scheduleOf({incoming: 3}), [
        ...TrashType.builtIns,
        mine,
      ]);
      expect(match.existing[incoming], same(mine));
      expect(match.toCreate, isEmpty);
    });

    test('the id wins over a name match', () {
      final byId = custom('cglass', 'Bottles');
      final byName = custom('cother', 'Glass', slot: 5);
      final incoming = custom('cglass', 'Glass');
      final match = ImportMatch.of(scheduleOf({incoming: 1}), [
        ...TrashType.builtIns,
        byName,
        byId,
      ]);
      expect(match.existing[incoming], same(byId));
    });

    test('otherwise the same name matches, ignoring case and spaces', () {
      final mine = custom('cmine', 'Glass');
      final incoming = custom('cq1', '  GLASS ');
      final match = ImportMatch.of(scheduleOf({incoming: 1}), [
        ...TrashType.builtIns,
        mine,
      ]);
      expect(match.existing[incoming], same(mine));
      expect(match.toCreate, isEmpty);
    });

    test('a custom bin can match a built-in by its shown name', () {
      final incoming = custom('cq1', 'bio waste');
      final renamed = TrashType.paper.copyWith(customName: 'Cardboard');
      final cardboard = custom('cq2', 'Cardboard', slot: 5);
      final match = ImportMatch.of(scheduleOf({incoming: 1, cardboard: 1}), [
        TrashType.plastic,
        renamed,
        TrashType.trash,
        TrashType.bio,
      ]);
      expect(match.existing[incoming], TrashType.bio);
      expect(match.existing[cardboard], renamed);
    });

    test('unknown custom bins are created while there is room', () {
      final glass = custom('cq1', 'Glass');
      final metal = custom('cq2', 'Metal', slot: 5);
      final match = ImportMatch.of(
        scheduleOf({TrashType.trash: 1, glass: 2, metal: 1}),
        userBinsWith(4),
      );
      expect(match.existing.keys, [TrashType.trash]);
      expect(match.toCreate, [glass, metal]);
      expect(match.noRoom, isEmpty);
    });

    test('incoming bins sharing a new name create one bin', () {
      final first = custom('cq1', 'Glass');
      final second = custom('cq2', 'glass ', slot: 5);
      final match = ImportMatch.of(
        scheduleOf({first: 1, second: 2}),
        TrashType.builtIns,
      );
      expect(match.toCreate, [first]);
      expect(match.sameAsNew, {second: first});
      expect(match.sameAsNew[second], same(first));
      expect(match.existing, isEmpty);
      expect(match.noRoom, isEmpty);
    });

    test('a twin of a new bin takes no room of its own', () {
      // 4 built-ins + 5 custom: room for one more.
      final first = custom('cq1', 'Glass');
      final second = custom('cq2', 'GLASS', slot: 5);
      final other = custom('cq3', 'Metal', slot: 6);
      final match = ImportMatch.of(
        scheduleOf({first: 1, second: 1, other: 1}),
        userBinsWith(5),
      );
      expect(match.toCreate, [first]);
      expect(match.sameAsNew.keys, [second]);
      expect(match.noRoom, [other]);
    });

    test('sameAsNew is empty without twins', () {
      final match = ImportMatch.of(
        scheduleOf({custom('cq1', 'Glass'): 1}),
        TrashType.builtIns,
      );
      expect(match.sameAsNew, isEmpty);
    });

    test('custom bins past ten bins have no room', () {
      final a = custom('cq1', 'A');
      final b = custom('cq2', 'B', slot: 5);
      final c = custom('cq3', 'C', slot: 6);
      // 4 built-ins + 4 custom: room for two more.
      final match = ImportMatch.of(
        scheduleOf({a: 1, b: 1, c: 1}),
        userBinsWith(4),
      );
      expect(match.toCreate, [a, b]);
      expect(match.noRoom, [c]);
    });

    test('a full set of bins has no room, but matches still work', () {
      final match10 = userBinsWith(6);
      expect(match10.length, TrashType.maxBins);
      final known = custom('cq1', 'User 2');
      final unknown = custom('cq2', 'New', slot: 5);
      final match = ImportMatch.of(
        scheduleOf({known: 1, unknown: 1, TrashType.bio: 1}),
        match10,
      );
      expect(match.existing[known]!.id, 'cuser2');
      expect(match.existing[TrashType.bio], TrashType.bio);
      expect(match.toCreate, isEmpty);
      expect(match.noRoom, [unknown]);
    });

    test('a built-in missing from the user list has no room', () {
      final match = ImportMatch.of(scheduleOf({TrashType.bio: 1}), [
        TrashType.plastic,
        TrashType.paper,
        TrashType.trash,
      ]);
      expect(match.existing, isEmpty);
      expect(match.toCreate, isEmpty);
      expect(match.noRoom, [TrashType.bio]);
    });
  });
}
