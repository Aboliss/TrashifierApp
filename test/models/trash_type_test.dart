import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/bin_style.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('TrashType', () {
    Map<String, Object?> custom({
      Object? id = 'cglass',
      Object? slot = 4,
      Object? name = 'Glass',
      Object? color = 5,
      Object? icon = 6,
      Object? hidden,
    }) => {
      'id': id,
      'slot': slot,
      'name': name,
      'color': color,
      'icon': icon,
      'hidden': ?hidden,
    };

    group('built-ins', () {
      test('are plastic, paper, trash and bio with slots 0-3', () {
        expect(TrashType.builtIns, [
          TrashType.plastic,
          TrashType.paper,
          TrashType.trash,
          TrashType.bio,
        ]);
        expect(TrashType.builtIns.map((t) => t.id), [
          'plastic',
          'paper',
          'trash',
          'bio',
        ]);
        expect(TrashType.builtIns.map((t) => t.slot), [0, 1, 2, 3]);
        expect(TrashType.builtIns.map((t) => t.index), [0, 1, 2, 3]);
        for (final type in TrashType.builtIns) {
          expect(type.isBuiltIn, isTrue);
          expect(type.customName, isNull);
          expect(type.hidden, isFalse);
        }
      });

      test('keep the enum string representation', () {
        expect(TrashType.plastic.toString(), equals('TrashType.plastic'));
        expect(TrashType.bio.toString(), equals('TrashType.bio'));
      });

      test('keep the old storage keys; custom bins use bin.<id>', () {
        expect(TrashType.plastic.storageKey, 'TrashType.plastic');
        expect(TrashType.paper.storageKey, 'TrashType.paper');
        expect(TrashType.trash.storageKey, 'TrashType.trash');
        expect(TrashType.bio.storageKey, 'TrashType.bio');
        expect(TrashType.fromJson(custom(), 4)!.storageKey, 'bin.cglass');
        // Renaming a built-in keeps its key.
        expect(
          TrashType.paper.copyWith(customName: 'Cardboard').storageKey,
          'TrashType.paper',
        );
      });
    });

    group('equality', () {
      test('is by id only', () {
        final renamed = TrashType.plastic.copyWith(
          customName: 'Yellow bag',
          color: 7,
          icon: 9,
          position: 5,
          hidden: true,
        );
        expect(renamed, equals(TrashType.plastic));
        expect(renamed.hashCode, equals(TrashType.plastic.hashCode));
        expect(TrashType.plastic == TrashType.paper, isFalse);

        final map = {TrashType.plastic: 1};
        expect(map[renamed], 1);
      });

      test('custom bins with different ids differ even with equal fields', () {
        const a = TrashType(
          id: 'ca',
          slot: 4,
          position: 4,
          customName: 'Glass',
          color: 4,
          icon: 4,
        );
        const b = TrashType(
          id: 'cb',
          slot: 4,
          position: 4,
          customName: 'Glass',
          color: 4,
          icon: 4,
        );
        expect(a == b, isFalse);
        expect(a.isBuiltIn, isFalse);
      });
    });

    group('cleanName', () {
      test('trims, strips control characters and collapses whitespace', () {
        expect(TrashType.cleanName('  Glass  '), 'Glass');
        expect(TrashType.cleanName('Gl\u0000a\u0007ss\u007F'), 'Glass');
        expect(TrashType.cleanName('Old   \t clothes'), 'Old clothes');
        expect(TrashType.cleanName('Line\nbreak'), 'Linebreak');
      });

      test('is null for null, empty or blank names', () {
        expect(TrashType.cleanName(null), isNull);
        expect(TrashType.cleanName(''), isNull);
        expect(TrashType.cleanName('   '), isNull);
        expect(TrashType.cleanName('\u0001\u0002'), isNull);
      });

      test('cuts to 24 characters', () {
        expect(TrashType.cleanName('a' * 30), 'a' * 24);
        expect(TrashType.cleanName('a' * 24), 'a' * 24);
        // No trailing space after the cut.
        expect(TrashType.cleanName('${'a' * 23} bcd'), 'a' * 23);
      });

      test('counts user-perceived characters, not code units', () {
        final name = 'Ä🍾' * 20;
        final cleaned = TrashType.cleanName(name)!;
        expect(cleaned, 'Ä🍾' * 12);
      });
    });

    group('cleanName byte cap', () {
      test('keeps names within maxNameBytes unchanged', () {
        // 24 four-byte emoji: exactly 96 bytes.
        final emoji = '🍾' * 24;
        expect(utf8.encode(emoji).length, TrashType.maxNameBytes);
        expect(TrashType.cleanName(emoji), emoji);
        expect(TrashType.cleanName('ž' * 24), 'ž' * 24);
      });

      test('drops whole characters from the end until it fits', () {
        const flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'; // 28 bytes, one character
        final cleaned = TrashType.cleanName('${flag * 4}x')!;
        expect(cleaned, flag * 3);
        expect(
          utf8.encode(cleaned).length,
          lessThanOrEqualTo(TrashType.maxNameBytes),
        );
        // Never a broken sequence: the result is made of whole flags.
        expect(cleaned.characters.every((c) => c == flag), isTrue);
      });

      test('trims a space left at the cut', () {
        const flag = '🏴󠁧󠁢󠁳󠁣󠁴󠁿'; // 28 bytes
        // 24 characters, 117 bytes: the flag goes, then the space.
        final cleaned = TrashType.cleanName('${'🍾' * 22} $flag')!;
        expect(cleaned, '🍾' * 22);
      });

      test('fromJson applies the cap to stored names', () {
        final bin = TrashType.fromJson(custom(name: '👨‍👩‍👧‍👦' * 10), 4)!;
        expect(
          utf8.encode(bin.customName!).length,
          lessThanOrEqualTo(TrashType.maxNameBytes),
        );
        expect(bin.customName, '👨‍👩‍👧‍👦' * 3);
      });
    });

    group('isValidId', () {
      test('accepts built-ins and c + 1-16 lowercase letters or digits', () {
        expect(TrashType.isValidId('plastic'), isTrue);
        expect(TrashType.isValidId('bio'), isTrue);
        expect(TrashType.isValidId('c1'), isTrue);
        expect(TrashType.isValidId('cabc123'), isTrue);
        expect(TrashType.isValidId('c${'a' * 16}'), isTrue);
      });

      test('rejects anything else', () {
        for (final id in [
          '',
          'c',
          'c${'a' * 17}',
          'cABC',
          'c-1',
          'glass',
          'Plastic',
          ' cglass',
          'x1',
        ]) {
          expect(TrashType.isValidId(id), isFalse, reason: id);
        }
      });
    });

    group('copyWith', () {
      test('keeps id and slot and changes the rest', () {
        final base = TrashType.fromJson(custom(), 4)!;
        final changed = base.copyWith(
          position: 7,
          customName: 'Bottles',
          color: 1,
          icon: 2,
          hidden: true,
        );
        expect(changed.id, 'cglass');
        expect(changed.slot, 4);
        expect(changed.position, 7);
        expect(changed.customName, 'Bottles');
        expect(changed.color, 1);
        expect(changed.icon, 2);
        expect(changed.hidden, isTrue);
      });

      test('keeps the name unless clearCustomName is set', () {
        final named = TrashType.paper.copyWith(customName: 'Cardboard');
        expect(named.copyWith(color: 3).customName, 'Cardboard');
        expect(named.copyWith(clearCustomName: true).customName, isNull);
        // clearCustomName wins over a given name.
        expect(
          named.copyWith(customName: 'Other', clearCustomName: true).customName,
          isNull,
        );
      });
    });

    group('toJson / fromJson', () {
      test('round-trips a custom bin', () {
        final bin = TrashType.fromJson(custom(hidden: true), 6)!;
        expect(bin.position, 6);
        expect(bin.hidden, isTrue);
        final again = TrashType.fromJson(bin.toJson(), 6)!;
        expect(again.id, bin.id);
        expect(again.slot, bin.slot);
        expect(again.customName, 'Glass');
        expect(again.color, 5);
        expect(again.icon, 6);
        expect(again.hidden, isTrue);
      });

      test('omits name and hidden when unset', () {
        expect(TrashType.bio.toJson(), {
          'id': 'bio',
          'slot': 3,
          'color': 3,
          'icon': 3,
        });
      });

      test('reads a built-in without a name, and a renamed one', () {
        final bio = TrashType.fromJson(TrashType.bio.toJson(), 2)!;
        expect(bio, TrashType.bio);
        expect(bio.customName, isNull);
        expect(bio.position, 2);

        final renamed = TrashType.fromJson({
          ...TrashType.paper.toJson(),
          'name': '  Cardboard ',
        }, 0)!;
        expect(renamed.customName, 'Cardboard');
      });

      test('treats a blank built-in name as no name', () {
        final bin = TrashType.fromJson({
          ...TrashType.trash.toJson(),
          'name': '   ',
        }, 0)!;
        expect(bin.customName, isNull);
      });

      test('rejects a built-in on another slot', () {
        expect(
          TrashType.fromJson({...TrashType.plastic.toJson(), 'slot': 1}, 0),
          isNull,
        );
        expect(
          TrashType.fromJson({...TrashType.bio.toJson(), 'slot': 5}, 0),
          isNull,
        );
      });

      test('rejects a custom bin on a built-in slot or past slot 9', () {
        for (final slot in [0, 3, 10, -1]) {
          expect(
            TrashType.fromJson(custom(slot: slot), 4),
            isNull,
            reason: '$slot',
          );
        }
        expect(TrashType.fromJson(custom(slot: 9), 4), isNotNull);
      });

      test('rejects a custom bin without a usable name', () {
        expect(TrashType.fromJson(custom(name: null), 4), isNull);
        expect(TrashType.fromJson(custom(name: ''), 4), isNull);
        expect(TrashType.fromJson(custom(name: ' \n '), 4), isNull);
        expect(TrashType.fromJson(custom(name: 42), 4), isNull);
      });

      test('rejects out-of-range colors and icons', () {
        expect(TrashType.fromJson(custom(color: -1), 4), isNull);
        expect(
          TrashType.fromJson(custom(color: BinStyle.colors.length), 4),
          isNull,
        );
        expect(
          TrashType.fromJson(custom(color: BinStyle.colors.length - 1), 4),
          isNotNull,
        );
        expect(TrashType.fromJson(custom(icon: -1), 4), isNull);
        expect(
          TrashType.fromJson(custom(icon: BinStyle.icons.length), 4),
          isNull,
        );
        expect(
          TrashType.fromJson(custom(icon: BinStyle.icons.length - 1), 4),
          isNotNull,
        );
      });

      test('rejects wrong types and bad ids', () {
        expect(TrashType.fromJson(null, 0), isNull);
        expect(TrashType.fromJson('plastic', 0), isNull);
        expect(TrashType.fromJson([1, 2], 0), isNull);
        expect(TrashType.fromJson(custom(id: 'glass'), 4), isNull);
        expect(TrashType.fromJson(custom(id: 7), 4), isNull);
        expect(TrashType.fromJson(custom(slot: '4'), 4), isNull);
        expect(TrashType.fromJson(custom(slot: 4.0), 4), isNull);
        expect(TrashType.fromJson(custom(color: '5'), 4), isNull);
        expect(TrashType.fromJson(custom(icon: null), 4), isNull);
        expect(TrashType.fromJson(custom(hidden: 'yes'), 4), isNull);
        expect(TrashType.fromJson(custom(hidden: 1), 4), isNull);
      });

      test('cleans and cuts a stored custom name', () {
        final bin = TrashType.fromJson(custom(name: ' ${'x' * 40} '), 4)!;
        expect(bin.customName, 'x' * 24);
      });
    });
  });
}
