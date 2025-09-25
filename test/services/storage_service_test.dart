import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService.instance;
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = StorageService.instance;
        final instance2 = StorageService.instance;

        expect(instance1, same(instance2));
      });
    });

    group('saveDates', () {
      test('should save dates successfully', () async {
        final dates = [DateTime(2025, 9, 25), DateTime(2025, 9, 26), DateTime(2025, 9, 27)];

        await expectLater(storageService.saveDates(dates, TrashType.plastic), completes);
      });

      test('should save empty list successfully', () async {
        final dates = <DateTime>[];

        await expectLater(storageService.saveDates(dates, TrashType.paper), completes);
      });

      test('should save dates for different trash types independently', () async {
        final plasticDates = [DateTime(2025, 9, 25)];
        final paperDates = [DateTime(2025, 9, 26)];

        await storageService.saveDates(plasticDates, TrashType.plastic);
        await storageService.saveDates(paperDates, TrashType.paper);

        final loadedPlastic = await storageService.loadDates(TrashType.plastic);
        final loadedPaper = await storageService.loadDates(TrashType.paper);

        expect(loadedPlastic.length, equals(1));
        expect(loadedPaper.length, equals(1));
        expect(loadedPlastic.first.day, equals(25));
        expect(loadedPaper.first.day, equals(26));
      });
    });

    group('loadDates', () {
      test('should return empty list when no dates are saved', () async {
        final dates = await storageService.loadDates(TrashType.bio);

        expect(dates, isEmpty);
      });

      test('should load previously saved dates', () async {
        final originalDates = [DateTime(2025, 9, 25, 10, 30), DateTime(2025, 9, 26, 14, 45)];

        await storageService.saveDates(originalDates, TrashType.trash);
        final loadedDates = await storageService.loadDates(TrashType.trash);

        expect(loadedDates.length, equals(2));
        expect(loadedDates[0], equals(originalDates[0]));
        expect(loadedDates[1], equals(originalDates[1]));
      });

      test('should preserve date time precision', () async {
        final originalDate = DateTime(2025, 9, 25, 15, 30, 45, 123, 456);

        await storageService.saveDates([originalDate], TrashType.plastic);
        final loadedDates = await storageService.loadDates(TrashType.plastic);

        expect(loadedDates.first, equals(originalDate));
      });

      test('should handle dates with different timezones', () async {
        final utcDate = DateTime.utc(2025, 9, 25, 12, 0);
        final localDate = DateTime(2025, 9, 25, 12, 0);

        await storageService.saveDates([utcDate], TrashType.plastic);
        await storageService.saveDates([localDate], TrashType.paper);

        final loadedUtc = await storageService.loadDates(TrashType.plastic);
        final loadedLocal = await storageService.loadDates(TrashType.paper);

        expect(loadedUtc.first.isUtc, equals(utcDate.isUtc));
        expect(loadedLocal.first.isUtc, equals(localDate.isUtc));
      });
    });

    group('clearDates', () {
      test('should clear previously saved dates', () async {
        final dates = [DateTime(2025, 9, 25)];

        // Save some dates
        await storageService.saveDates(dates, TrashType.bio);

        // Verify they were saved
        final beforeClear = await storageService.loadDates(TrashType.bio);
        expect(beforeClear.length, equals(1));

        // Clear the dates
        await storageService.clearDates(TrashType.bio);

        // Verify they were cleared
        final afterClear = await storageService.loadDates(TrashType.bio);
        expect(afterClear, isEmpty);
      });

      test('should not affect other trash types when clearing', () async {
        final plasticDates = [DateTime(2025, 9, 25)];
        final paperDates = [DateTime(2025, 9, 26)];

        // Save dates for both types
        await storageService.saveDates(plasticDates, TrashType.plastic);
        await storageService.saveDates(paperDates, TrashType.paper);

        // Clear only plastic
        await storageService.clearDates(TrashType.plastic);

        // Verify plastic is cleared but paper remains
        final clearedPlastic = await storageService.loadDates(TrashType.plastic);
        final remainingPaper = await storageService.loadDates(TrashType.paper);

        expect(clearedPlastic, isEmpty);
        expect(remainingPaper.length, equals(1));
      });

      test('should not throw when clearing non-existent data', () async {
        await expectLater(storageService.clearDates(TrashType.trash), completes);
      });
    });

    group('Data Persistence', () {
      test('should maintain data across multiple operations', () async {
        final dates1 = [DateTime(2025, 9, 25)];
        final dates2 = [DateTime(2025, 9, 26), DateTime(2025, 9, 27)];

        await storageService.saveDates(dates1, TrashType.plastic);

        final loaded1 = await storageService.loadDates(TrashType.plastic);
        expect(loaded1.length, equals(1));

        await storageService.saveDates(dates2, TrashType.plastic);

        final loaded2 = await storageService.loadDates(TrashType.plastic);
        expect(loaded2.length, equals(2));
        expect(loaded2[0].day, equals(26));
        expect(loaded2[1].day, equals(27));
      });
    });

    group('All TrashType Support', () {
      test('should work with all trash types', () async {
        final testDate = DateTime(2025, 9, 25);

        for (final trashType in TrashType.values) {
          await storageService.saveDates([testDate], trashType);
          final loaded = await storageService.loadDates(trashType);

          expect(loaded.length, equals(1), reason: 'Failed for $trashType');
          expect(loaded.first, equals(testDate), reason: 'Failed for $trashType');

          await storageService.clearDates(trashType);
          final cleared = await storageService.loadDates(trashType);
          expect(cleared, isEmpty, reason: 'Failed to clear $trashType');
        }
      });
    });

    group('Error Handling', () {
      test('should handle large date lists', () async {
        final largeDateList = List.generate(1000, (index) => DateTime(2025, 1, 1).add(Duration(days: index)));

        await expectLater(storageService.saveDates(largeDateList, TrashType.plastic), completes);

        final loaded = await storageService.loadDates(TrashType.plastic);
        expect(loaded.length, equals(1000));
      });

      test('should handle dates with extreme values', () async {
        final extremeDates = [DateTime(1900, 1, 1), DateTime(2099, 12, 31), DateTime.utc(2025, 1, 1)];

        await storageService.saveDates(extremeDates, TrashType.paper);
        final loaded = await storageService.loadDates(TrashType.paper);

        expect(loaded.length, equals(3));
        expect(loaded[0].year, equals(1900));
        expect(loaded[1].year, equals(2099));
        expect(loaded[2].isUtc, isTrue);
      });
    });
  });
}
