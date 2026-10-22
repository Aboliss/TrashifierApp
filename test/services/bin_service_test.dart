import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/bin_service.dart';

Map<String, Object?> customJson(
  String id,
  int slot, {
  String name = 'Glass',
  int color = 5,
  int icon = 6,
  bool hidden = false,
}) => {
  'id': id,
  'slot': slot,
  'name': name,
  'color': color,
  'icon': icon,
  if (hidden) 'hidden': true,
};

List<String> ids(List<TrashType> bins) => [for (final b in bins) b.id];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<BinService> loadedService([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final service = BinService();
    await service.ready;
    return service;
  }

  group('BinService.decode', () {
    test('falls back to the built-ins for missing or broken data', () {
      for (final json in [null, '', 'not json', '{"a":1}', '42', '"bins"']) {
        expect(
          BinService.decode(json),
          equals(TrashType.builtIns),
          reason: '$json',
        );
      }
    });

    test('keeps the stored order and renumbers positions', () {
      final bins = BinService.decode(
        jsonEncode([
          TrashType.bio.toJson(),
          customJson('cglass', 4),
          TrashType.plastic.toJson(),
          TrashType.trash.toJson(),
          TrashType.paper.toJson(),
        ]),
      );
      expect(ids(bins), ['bio', 'cglass', 'plastic', 'trash', 'paper']);
      expect(bins.map((b) => b.position), [0, 1, 2, 3, 4]);
      expect(bins.map((b) => b.index), [0, 1, 2, 3, 4]);
      expect(bins[1].customName, 'Glass');
      expect(bins[1].slot, 4);
    });

    test('drops invalid entries and re-adds missing built-ins at the end', () {
      final bins = BinService.decode(
        jsonEncode([
          customJson('cglass', 4),
          {'id': 'paper', 'slot': 7, 'color': 1, 'icon': 1}, // wrong slot
          'garbage',
          null,
          customJson('BAD', 5),
          customJson('cnoname', 6, name: '   '),
          TrashType.trash.toJson(),
        ]),
      );
      expect(ids(bins), ['cglass', 'trash', 'plastic', 'paper', 'bio']);
      expect(bins.map((b) => b.position), [0, 1, 2, 3, 4]);
      expect(bins.where((b) => b.isBuiltIn).length, 4);
    });

    test('drops entries with a duplicate id or slot (first one wins)', () {
      final bins = BinService.decode(
        jsonEncode([
          ...TrashType.builtIns.map((b) => b.toJson()),
          customJson('cglass', 4, name: 'Glass'),
          customJson('cglass', 5, name: 'Glass again'),
          customJson('cmetal', 4, name: 'Metal'),
          customJson('cpaper', 5, name: 'Cardboard'),
          {...TrashType.bio.toJson(), 'name': 'Second bio'},
        ]),
      );
      expect(ids(bins), [
        'plastic',
        'paper',
        'trash',
        'bio',
        'cglass',
        'cpaper',
      ]);
      expect(bins.firstWhere((b) => b.id == 'cglass').customName, 'Glass');
      expect(bins.firstWhere((b) => b.id == 'bio').customName, isNull);
    });

    test('caps the list at ten bins', () {
      final bins = BinService.decode(
        jsonEncode([
          ...TrashType.builtIns.map((b) => b.toJson()),
          for (var slot = 4; slot < 10; slot++) customJson('c$slot', slot),
          // An 11th bin can't even get a free slot; one on a taken slot is
          // dropped as a duplicate either way.
          customJson('cextra', 9),
        ]),
      );
      expect(bins.length, TrashType.maxBins);
      expect(ids(bins).contains('cextra'), isFalse);
    });

    test('re-adds a missing built-in to a full set of custom bins', () {
      // Custom bins can't use slots 0-3, so there is always room.
      final bins = BinService.decode(
        jsonEncode([
          TrashType.plastic.toJson(),
          TrashType.paper.toJson(),
          TrashType.trash.toJson(),
          for (var slot = 4; slot < 10; slot++) customJson('c$slot', slot),
        ]),
      );
      expect(bins.length, 10);
      expect(ids(bins).last, 'bio');
      expect(ids(bins).where((id) => id.startsWith('c')).length, 6);
    });

    test('keeps hidden flags, renamed built-ins and colors', () {
      final bins = BinService.decode(
        jsonEncode([
          {...TrashType.plastic.toJson(), 'hidden': true, 'name': 'Yellow'},
          TrashType.paper.toJson(),
          TrashType.trash.toJson(),
          TrashType.bio.toJson(),
          customJson('cglass', 4, color: 11, icon: 15, hidden: true),
        ]),
      );
      expect(bins[0].hidden, isTrue);
      expect(bins[0].customName, 'Yellow');
      expect(bins[4].hidden, isTrue);
      expect(bins[4].color, 11);
      expect(bins[4].icon, 15);
    });

    test('encode and decode round-trip', () {
      final bins = BinService.decode(
        jsonEncode([
          TrashType.paper.toJson(),
          customJson('cglass', 7, hidden: true),
          TrashType.plastic.toJson(),
          TrashType.trash.toJson(),
          TrashType.bio.toJson(),
        ]),
      );
      final again = BinService.decode(BinService.encode(bins));
      expect(again.map((b) => jsonEncode(b.toJson())), [
        for (final b in bins) jsonEncode(b.toJson()),
      ]);
      expect(again.map((b) => b.position), [0, 1, 2, 3, 4]);
    });
  });

  group('BinService', () {
    test('starts with the built-ins', () async {
      final service = await loadedService();
      expect(service.all, equals(TrashType.builtIns));
      expect(service.visible, equals(TrashType.builtIns));
      expect(service.isFull, isFalse);
    });

    test('loads the stored list and notifies', () async {
      SharedPreferences.setMockInitialValues({
        BinService.binsKey: jsonEncode([
          customJson('cglass', 4),
          ...TrashType.builtIns.map((b) => b.toJson()),
        ]),
      });
      final service = BinService();
      var notified = 0;
      service.addListener(() => notified++);
      await service.ready;

      expect(ids(service.all), ['cglass', 'plastic', 'paper', 'trash', 'bio']);
      expect(notified, 1);
    });

    test('lists are unmodifiable', () async {
      final service = await loadedService();
      expect(() => service.all.add(TrashType.bio), throwsUnsupportedError);
      expect(() => service.visible.clear(), throwsUnsupportedError);
    });

    group('add', () {
      test('appends a custom bin on the first free slot from 4', () async {
        final service = await loadedService();
        final glass = await service.add(name: '  Glass ', color: 5, icon: 6);

        expect(glass, isNotNull);
        expect(glass!.isBuiltIn, isFalse);
        expect(TrashType.isValidId(glass.id), isTrue);
        expect(glass.id, startsWith('c'));
        expect(glass.slot, 4);
        expect(glass.position, 4);
        expect(glass.customName, 'Glass');
        expect(glass.color, 5);
        expect(glass.icon, 6);
        expect(service.all.last, glass);
        expect(service.find(glass), isNotNull);
        expect(glass.storageKey, 'bin.${glass.id}');

        final metal = await service.add(name: 'Metal', color: 0, icon: 0);
        expect(metal!.slot, 5);
        expect(metal.id, isNot(glass.id));
      });

      test('reuses the slot of a removed bin', () async {
        final service = await loadedService();
        final a = await service.add(name: 'A', color: 4, icon: 4);
        await service.add(name: 'B', color: 4, icon: 4);
        await service.remove(a!);

        final c = await service.add(name: 'C', color: 4, icon: 4);
        expect(c!.slot, 4);
        expect(service.all.map((b) => b.slot).toSet().length, 6);
      });

      test('refuses an empty name', () async {
        final service = await loadedService();
        expect(await service.add(name: '', color: 4, icon: 4), isNull);
        expect(await service.add(name: ' \n\t ', color: 4, icon: 4), isNull);
        expect(service.all, equals(TrashType.builtIns));
      });

      test('refuses an 11th bin', () async {
        final service = await loadedService();
        for (var i = 0; i < 6; i++) {
          expect(
            await service.add(name: 'Bin $i', color: 4, icon: 4),
            isNotNull,
          );
        }
        expect(service.isFull, isTrue);
        expect(service.all.length, TrashType.maxBins);
        expect(service.all.map((b) => b.slot).toSet(), {
          for (var i = 0; i < 10; i++) i,
        });
        expect(await service.add(name: 'One more', color: 4, icon: 4), isNull);
        expect(service.all.length, TrashType.maxBins);
      });

      test('cuts long names to 24 characters', () async {
        final service = await loadedService();
        final bin = await service.add(name: 'x' * 40, color: 4, icon: 4);
        expect(bin!.customName, 'x' * 24);
      });

      test('notifies listeners', () async {
        final service = await loadedService();
        var notified = 0;
        service.addListener(() => notified++);
        await service.add(name: 'Glass', color: 4, icon: 4);
        expect(notified, 1);
      });
    });

    group('update', () {
      test('renames and restyles a custom bin', () async {
        final service = await loadedService();
        final glass = await service.add(name: 'Glass', color: 4, icon: 4);

        await service.update(
          glass!.copyWith(customName: ' Bottles ', color: 9, icon: 10),
        );
        final updated = service.find(glass)!;
        expect(updated.customName, 'Bottles');
        expect(updated.color, 9);
        expect(updated.icon, 10);
        expect(updated.slot, glass.slot);
        expect(updated.position, glass.position);
      });

      test('renames a built-in and a blank name brings back its own', () async {
        final service = await loadedService();
        await service.update(TrashType.paper.copyWith(customName: 'Cardboard'));
        expect(service.find(TrashType.paper)!.customName, 'Cardboard');

        await service.update(
          service.find(TrashType.paper)!.copyWith(customName: '   '),
        );
        expect(service.find(TrashType.paper)!.customName, isNull);

        await service.update(TrashType.paper.copyWith(customName: 'Cardboard'));
        await service.update(
          service.find(TrashType.paper)!.copyWith(clearCustomName: true),
        );
        expect(service.find(TrashType.paper)!.customName, isNull);
      });

      test('ignores a bin that is not in the list', () async {
        final service = await loadedService();
        await service.update(
          const TrashType(
            id: 'cghost',
            slot: 4,
            position: 4,
            customName: 'Ghost',
            color: 4,
            icon: 4,
          ),
        );
        expect(service.all, equals(TrashType.builtIns));
      });

      test('never stores a custom bin without a name', () async {
        final service = await loadedService();
        final glass = await service.add(name: 'Glass', color: 4, icon: 4);
        await service.update(glass!.copyWith(customName: '  '));

        // The stored list must still load the bin back.
        final reloaded = await loadedService({
          BinService.binsKey: (await SharedPreferences.getInstance()).getString(
            BinService.binsKey,
          )!,
        });
        expect(reloaded.find(glass), isNotNull);
        // A blank name keeps the previous one.
        expect(service.find(glass)!.customName, 'Glass');
        expect(reloaded.find(glass)!.customName, 'Glass');
      });

      test(
        'a blank name on a custom bin still saves its other changes',
        () async {
          final service = await loadedService();
          final glass = await service.add(name: 'Glass', color: 4, icon: 4);
          await service.update(
            glass!.copyWith(clearCustomName: true, color: 9, icon: 10),
          );
          final updated = service.find(glass)!;
          expect(updated.customName, 'Glass');
          expect(updated.color, 9);
          expect(updated.icon, 10);
        },
      );
    });

    group('setHidden', () {
      test('hides and shows a bin', () async {
        final service = await loadedService();
        await service.setHidden(TrashType.trash, true);

        expect(service.find(TrashType.trash)!.hidden, isTrue);
        expect(ids(service.visible), ['plastic', 'paper', 'bio']);
        expect(service.all.length, 4);

        await service.setHidden(TrashType.trash, false);
        expect(service.visible, equals(TrashType.builtIns));
      });

      test('does nothing when unchanged or unknown', () async {
        final service = await loadedService();
        var notified = 0;
        service.addListener(() => notified++);
        await service.setHidden(TrashType.trash, false);
        await service.setHidden(
          const TrashType(
            id: 'cghost',
            slot: 4,
            position: 4,
            customName: 'Ghost',
            color: 4,
            icon: 4,
          ),
          true,
        );
        expect(notified, 0);
      });
    });

    group('move', () {
      test('follows ReorderableListView indexes', () async {
        final service = await loadedService();

        // Down: newIndex counts the moved item's old place.
        await service.move(0, 2);
        expect(ids(service.all), ['paper', 'plastic', 'trash', 'bio']);

        // To the end.
        await service.move(0, 4);
        expect(ids(service.all), ['plastic', 'trash', 'bio', 'paper']);

        // Up.
        await service.move(3, 0);
        expect(ids(service.all), ['paper', 'plastic', 'trash', 'bio']);
        expect(service.all.map((b) => b.position), [0, 1, 2, 3]);
      });

      test('ignores bad indexes and clamps the target', () async {
        final service = await loadedService();
        await service.move(-1, 0);
        await service.move(4, 0);
        expect(service.all, equals(TrashType.builtIns));

        await service.move(0, 99);
        expect(ids(service.all), ['paper', 'trash', 'bio', 'plastic']);
      });

      test('keeps slots, so reminder IDs survive a reorder', () async {
        final service = await loadedService();
        await service.move(3, 0);
        expect(service.find(TrashType.bio)!.slot, 3);
        expect(service.find(TrashType.bio)!.position, 0);
      });
    });

    group('remove', () {
      test('removes a custom bin and renumbers', () async {
        final service = await loadedService();
        final glass = await service.add(name: 'Glass', color: 4, icon: 4);
        await service.move(4, 0);
        expect(ids(service.all).first, glass!.id);

        await service.remove(glass);
        expect(service.all, equals(TrashType.builtIns));
        expect(service.all.map((b) => b.position), [0, 1, 2, 3]);
        expect(service.find(glass), isNull);
      });

      test('is a no-op for built-ins', () async {
        final service = await loadedService();
        var notified = 0;
        service.addListener(() => notified++);
        await service.remove(TrashType.plastic);
        await service.remove(TrashType.bio.copyWith(customName: 'Compost'));
        expect(service.all, equals(TrashType.builtIns));
        expect(notified, 0);
      });
    });

    group('persistence', () {
      test('a new service reads back every change', () async {
        final service = await loadedService();
        final glass = await service.add(name: 'Glass', color: 7, icon: 8);
        await service.setHidden(TrashType.paper, true);
        await service.update(TrashType.bio.copyWith(customName: 'Compost'));
        await service.move(4, 0);

        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(BinService.binsKey)!;
        final reloaded = await loadedService({BinService.binsKey: stored});

        expect(ids(reloaded.all), [
          glass!.id,
          'plastic',
          'paper',
          'trash',
          'bio',
        ]);
        final again = reloaded.find(glass)!;
        expect(again.customName, 'Glass');
        expect(again.color, 7);
        expect(again.icon, 8);
        expect(again.slot, 4);
        expect(reloaded.find(TrashType.paper)!.hidden, isTrue);
        expect(reloaded.find(TrashType.bio)!.customName, 'Compost');
        expect(ids(reloaded.visible), [glass.id, 'plastic', 'trash', 'bio']);
      });

      test(
        'a change before loading finishes is not undone by the load',
        () async {
          SharedPreferences.setMockInitialValues({
            BinService.binsKey: jsonEncode([
              {...TrashType.plastic.toJson(), 'hidden': true},
              TrashType.paper.toJson(),
              TrashType.trash.toJson(),
              TrashType.bio.toJson(),
            ]),
          });
          final service = BinService();
          // Not awaited on purpose: runs before the stored list is read.
          final adding = service.add(name: 'Glass', color: 4, icon: 4);
          await service.ready;
          final glass = await adding;

          expect(glass, isNotNull);
          expect(service.find(glass!), isNotNull);
          expect(service.all.length, 5);
          final prefs = await SharedPreferences.getInstance();
          expect(
            ids(BinService.decode(prefs.getString(BinService.binsKey))),
            ids(service.all),
          );
        },
      );

      test('ready completes even when the stored list is broken', () async {
        final service = await loadedService({BinService.binsKey: '[{'});
        expect(service.all, equals(TrashType.builtIns));
      });
    });
  });
}
