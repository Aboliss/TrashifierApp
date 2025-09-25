import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('TrashTypeHelper', () {
    group('getIcon', () {
      test('should return correct icons for each trash type', () {
        expect(TrashTypeHelper.getIcon(TrashType.plastic), equals(Icons.recycling));
        expect(TrashTypeHelper.getIcon(TrashType.paper), equals(Icons.description));
        expect(TrashTypeHelper.getIcon(TrashType.trash), equals(Icons.delete));
        expect(TrashTypeHelper.getIcon(TrashType.bio), equals(Icons.eco));
      });
    });

    group('getIconColor', () {
      test('should return correct icon colors for each trash type', () {
        expect(TrashTypeHelper.getIconColor(TrashType.plastic), equals(Colors.black));
        expect(TrashTypeHelper.getIconColor(TrashType.paper), equals(Colors.white));
        expect(TrashTypeHelper.getIconColor(TrashType.trash), equals(Colors.white));
        expect(TrashTypeHelper.getIconColor(TrashType.bio), equals(Colors.white));
      });
    });

    group('getNotificationTitle', () {
      test('should return correct notification titles for each trash type', () {
        expect(TrashTypeHelper.getNotificationTitle(TrashType.plastic), equals('Plastic Collection Reminder'));
        expect(TrashTypeHelper.getNotificationTitle(TrashType.paper), equals('Paper Collection Reminder'));
        expect(TrashTypeHelper.getNotificationTitle(TrashType.trash), equals('General Trash Reminder'));
        expect(TrashTypeHelper.getNotificationTitle(TrashType.bio), equals('Bio Waste Collection Reminder'));
      });
    });

    group('getNotificationBody', () {
      test('should return correct notification bodies for each trash type', () {
        expect(TrashTypeHelper.getNotificationBody(TrashType.plastic), equals('Remember to take out your plastic trash!'));
        expect(TrashTypeHelper.getNotificationBody(TrashType.paper), equals('Remember to take out your paper trash!'));
        expect(TrashTypeHelper.getNotificationBody(TrashType.trash), equals('Remember to take out your trash!'));
        expect(TrashTypeHelper.getNotificationBody(TrashType.bio), equals('Remember to take out your bio waste!'));
      });
    });

    group('shouldUseWhiteText', () {
      test('should return correct text color preferences for each trash type', () {
        expect(TrashTypeHelper.shouldUseWhiteText(TrashType.plastic), isFalse);
        expect(TrashTypeHelper.shouldUseWhiteText(TrashType.paper), isTrue);
        expect(TrashTypeHelper.shouldUseWhiteText(TrashType.trash), isTrue);
        expect(TrashTypeHelper.shouldUseWhiteText(TrashType.bio), isTrue);
      });
    });

    group('getAllTypes', () {
      test('should return all trash types', () {
        final allTypes = TrashTypeHelper.getAllTypes();

        expect(allTypes.length, equals(4));
        expect(allTypes, contains(TrashType.plastic));
        expect(allTypes, contains(TrashType.paper));
        expect(allTypes, contains(TrashType.trash));
        expect(allTypes, contains(TrashType.bio));
        expect(allTypes, equals(TrashType.values));
      });
    });

    group('Color methods integration', () {
      testWidgets('getColor should delegate to TrashColors', (WidgetTester tester) async {
        // Test that the method calls don't throw exceptions
        expect(() => TrashTypeHelper.getColor(TrashType.plastic), returnsNormally);
        expect(() => TrashTypeHelper.getColor(TrashType.paper), returnsNormally);
        expect(() => TrashTypeHelper.getColor(TrashType.trash), returnsNormally);
        expect(() => TrashTypeHelper.getColor(TrashType.bio), returnsNormally);
      });

      testWidgets('getBackgroundColor should delegate to TrashColors', (WidgetTester tester) async {
        expect(() => TrashTypeHelper.getBackgroundColor(TrashType.plastic), returnsNormally);
        expect(() => TrashTypeHelper.getBackgroundColor(TrashType.paper), returnsNormally);
        expect(() => TrashTypeHelper.getBackgroundColor(TrashType.trash), returnsNormally);
        expect(() => TrashTypeHelper.getBackgroundColor(TrashType.bio), returnsNormally);
      });

      testWidgets('getContainerColor should work with BuildContext', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Test that the method calls don't throw exceptions
                expect(() => TrashTypeHelper.getContainerColor(context, TrashType.plastic), returnsNormally);
                expect(() => TrashTypeHelper.getContainerColor(context, TrashType.paper), returnsNormally);
                expect(() => TrashTypeHelper.getContainerColor(context, TrashType.trash), returnsNormally);
                expect(() => TrashTypeHelper.getContainerColor(context, TrashType.bio), returnsNormally);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('getContainerTextColor should work with BuildContext', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(() => TrashTypeHelper.getContainerTextColor(context, TrashType.plastic), returnsNormally);
                expect(() => TrashTypeHelper.getContainerTextColor(context, TrashType.paper), returnsNormally);
                expect(() => TrashTypeHelper.getContainerTextColor(context, TrashType.trash), returnsNormally);
                expect(() => TrashTypeHelper.getContainerTextColor(context, TrashType.bio), returnsNormally);
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('Consistency checks', () {
      test('all enum values should have corresponding implementations', () {
        for (final trashType in TrashType.values) {
          expect(() => TrashTypeHelper.getIcon(trashType), returnsNormally);
          expect(() => TrashTypeHelper.getIconColor(trashType), returnsNormally);
          expect(() => TrashTypeHelper.getNotificationTitle(trashType), returnsNormally);
          expect(() => TrashTypeHelper.getNotificationBody(trashType), returnsNormally);
          expect(() => TrashTypeHelper.shouldUseWhiteText(trashType), returnsNormally);
          expect(() => TrashTypeHelper.getColor(trashType), returnsNormally);
          expect(() => TrashTypeHelper.getBackgroundColor(trashType), returnsNormally);
        }
      });

      test('notification titles should not be empty', () {
        for (final trashType in TrashType.values) {
          final title = TrashTypeHelper.getNotificationTitle(trashType);
          expect(title.isNotEmpty, isTrue);
          expect(title.contains('Reminder'), isTrue);
        }
      });

      test('notification bodies should not be empty', () {
        for (final trashType in TrashType.values) {
          final body = TrashTypeHelper.getNotificationBody(trashType);
          expect(body.isNotEmpty, isTrue);
          expect(body.contains('Remember'), isTrue);
        }
      });
    });
  });
}
