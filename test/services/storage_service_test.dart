import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService.instance;
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        expect(StorageService.instance, same(StorageService.instance));
      });
    });

    group('encode/decode', () {
      test('encodes as yyyy-MM-dd', () {
        expect(
          StorageService.encodeDate(DateTime(2025, 3, 7, 22, 15)),
          equals('2025-03-07'),
        );
      });

      test('decodes yyyy-MM-dd to local midnight', () {
        final date = StorageService.decodeDate('2025-10-05');

        expect(date, equals(DateTime(2025, 10, 5)));
        expect(date!.isUtc, isFalse);
      });

      test('decodes legacy UTC timestamps to the same calendar day', () {
        expect(
          StorageService.decodeDate('2025-10-05T00:00:00.000Z'),
          equals(DateTime(2025, 10, 5)),
        );
      });

      test('rejects invalid values', () {
        expect(StorageService.decodeDate('garbage'), isNull);
        expect(StorageService.decodeDate('2025-02-31'), isNull);
      });
    });

    group('saveDates', () {
      test(
        'should save dates for different trash types independently',
        () async {
          await storageService.saveDates([
            DateTime(2025, 9, 25),
          ], TrashType.plastic);
          await storageService.saveDates([
            DateTime(2025, 9, 26),
          ], TrashType.paper);

          final loadedPlastic = await storageService.loadDates(
            TrashType.plastic,
          );
          final loadedPaper = await storageService.loadDates(TrashType.paper);

          expect(loadedPlastic, equals([DateTime(2025, 9, 25)]));
          expect(loadedPaper, equals([DateTime(2025, 9, 26)]));
        },
      );

      test('stores calendar days only', () async {
        await storageService.saveDates([
          DateTime.utc(2025, 10, 5),
          DateTime(2025, 10, 6, 14, 45),
        ], TrashType.trash);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('TrashType.trash'),
          equals(['2025-10-05', '2025-10-06']),
        );
      });

      test('should save empty list successfully', () async {
        await expectLater(
          storageService.saveDates(<DateTime>[], TrashType.paper),
          completes,
        );
        expect(await storageService.loadDates(TrashType.paper), isEmpty);
      });
    });

    group('loadDates', () {
      test('should return empty list when no dates are saved', () async {
        expect(await storageService.loadDates(TrashType.bio), isEmpty);
      });

      test('returns sorted, deduplicated local dates', () async {
        await storageService.saveDates([
          DateTime(2025, 9, 27),
          DateTime(2025, 9, 25, 10, 30),
          DateTime(2025, 9, 25, 18, 0),
        ], TrashType.trash);

        expect(
          await storageService.loadDates(TrashType.trash),
          equals([DateTime(2025, 9, 25), DateTime(2025, 9, 27)]),
        );
      });

      test('reads data written by older app versions', () async {
        SharedPreferences.setMockInitialValues({
          'TrashType.plastic': [
            '2025-10-05T00:00:00.000Z',
            '2025-10-12T00:00:00.000Z',
          ],
        });

        expect(
          await storageService.loadDates(TrashType.plastic),
          equals([DateTime(2025, 10, 5), DateTime(2025, 10, 12)]),
        );
      });

      test('skips corrupt entries instead of failing', () async {
        SharedPreferences.setMockInitialValues({
          'TrashType.bio': ['2025-10-05', 'not a date'],
        });

        expect(
          await storageService.loadDates(TrashType.bio),
          equals([DateTime(2025, 10, 5)]),
        );
      });
    });

    group('clearDates', () {
      test('should clear only the given type', () async {
        await storageService.saveDates([
          DateTime(2025, 9, 25),
        ], TrashType.plastic);
        await storageService.saveDates([
          DateTime(2025, 9, 26),
        ], TrashType.paper);

        await storageService.clearDates(TrashType.plastic);

        expect(await storageService.loadDates(TrashType.plastic), isEmpty);
        expect((await storageService.loadDates(TrashType.paper)).length, 1);
      });

      test('should not throw when clearing non-existent data', () async {
        await expectLater(
          storageService.clearDates(TrashType.trash),
          completes,
        );
      });
    });

    group('All TrashType Support', () {
      test('should work with all trash types', () async {
        final testDate = DateTime(2025, 9, 25);

        for (final trashType in TrashType.values) {
          await storageService.saveDates([testDate], trashType);
          final loaded = await storageService.loadDates(trashType);

          expect(loaded, equals([testDate]), reason: 'Failed for $trashType');

          await storageService.clearDates(trashType);
          expect(
            await storageService.loadDates(trashType),
            isEmpty,
            reason: 'Failed to clear $trashType',
          );
        }
      });

      test('should handle large date lists', () async {
        final largeDateList = List.generate(
          1000,
          (index) => DateTime(2025, 1, 1 + index),
        );

        await storageService.saveDates(largeDateList, TrashType.plastic);

        final loaded = await storageService.loadDates(TrashType.plastic);
        expect(loaded.length, equals(1000));
      });
    });
  });
}
