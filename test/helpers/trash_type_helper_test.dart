import 'package:flutter/material.dart';
import 'package:trashifier_app/models/bin_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('TrashTypeHelper', () {
    group('getNotificationTitle', () {
      test('should return correct notification titles for each trash type', () {
        expect(
          TrashTypeHelper.getNotificationTitle(TrashType.plastic),
          equals('Plastic goes out'),
        );
        expect(
          TrashTypeHelper.getNotificationTitle(TrashType.paper),
          equals('Paper goes out'),
        );
        expect(
          TrashTypeHelper.getNotificationTitle(TrashType.trash),
          equals('General trash goes out'),
        );
        expect(
          TrashTypeHelper.getNotificationTitle(TrashType.bio),
          equals('Bio waste goes out'),
        );
      });
    });

    group('getNotificationBody', () {
      test('should return correct notification bodies for each trash type', () {
        expect(
          TrashTypeHelper.getNotificationBody(TrashType.plastic),
          equals('Remember to take out your plastic bin!'),
        );
        expect(
          TrashTypeHelper.getNotificationBody(TrashType.paper),
          equals('Remember to take out your paper bin!'),
        );
        expect(
          TrashTypeHelper.getNotificationBody(TrashType.trash),
          equals('Remember to take out your trash bin!'),
        );
        expect(
          TrashTypeHelper.getNotificationBody(TrashType.bio),
          equals('Remember to take out your bio bin!'),
        );
      });
    });

    group('Color methods integration', () {
      testWidgets('getColor should delegate to TrashColors', (
        WidgetTester tester,
      ) async {
        // Test that the method calls don't throw exceptions
        expect(
          () => TrashTypeHelper.getColor(TrashType.plastic),
          returnsNormally,
        );
        expect(
          () => TrashTypeHelper.getColor(TrashType.paper),
          returnsNormally,
        );
        expect(
          () => TrashTypeHelper.getColor(TrashType.trash),
          returnsNormally,
        );
        expect(() => TrashTypeHelper.getColor(TrashType.bio), returnsNormally);
      });

      testWidgets('getContainerColor should work with BuildContext', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Test that the method calls don't throw exceptions
                expect(
                  () => TrashTypeHelper.getContainerColor(
                    context,
                    TrashType.plastic,
                  ),
                  returnsNormally,
                );
                expect(
                  () => TrashTypeHelper.getContainerColor(
                    context,
                    TrashType.paper,
                  ),
                  returnsNormally,
                );
                expect(
                  () => TrashTypeHelper.getContainerColor(
                    context,
                    TrashType.trash,
                  ),
                  returnsNormally,
                );
                expect(
                  () =>
                      TrashTypeHelper.getContainerColor(context, TrashType.bio),
                  returnsNormally,
                );
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('getContainerTextColor should work with BuildContext', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(
                  () => TrashTypeHelper.getContainerTextColor(
                    context,
                    TrashType.plastic,
                  ),
                  returnsNormally,
                );
                expect(
                  () => TrashTypeHelper.getContainerTextColor(
                    context,
                    TrashType.paper,
                  ),
                  returnsNormally,
                );
                expect(
                  () => TrashTypeHelper.getContainerTextColor(
                    context,
                    TrashType.trash,
                  ),
                  returnsNormally,
                );
                expect(
                  () => TrashTypeHelper.getContainerTextColor(
                    context,
                    TrashType.bio,
                  ),
                  returnsNormally,
                );
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('custom and renamed bins', () {
      const glass = TrashType(
        id: 'cglass',
        slot: 4,
        position: 4,
        customName: 'Glass',
        color: 5,
        icon: 6,
      );

      test('use the custom name everywhere', () {
        expect(TrashTypeHelper.getDisplayName(glass), 'Glass');
        expect(TrashTypeHelper.getShortName(glass), 'Glass');
        expect(TrashTypeHelper.getNotificationTitle(glass), 'Glass goes out');
        expect(
          TrashTypeHelper.getNotificationBody(glass),
          'Remember to take out your Glass bin!',
        );
      });

      test('have no description', () {
        expect(TrashTypeHelper.getDescription(glass), isNull);
        expect(
          TrashTypeHelper.getDescription(
            TrashType.paper.copyWith(customName: 'Cardboard'),
          ),
          isNull,
        );
        expect(TrashTypeHelper.getDescription(TrashType.paper), isNotNull);
      });

      test('a renamed built-in uses the custom texts', () {
        final paper = TrashType.paper.copyWith(customName: 'Cardboard');
        expect(TrashTypeHelper.getDisplayName(paper), 'Cardboard');
        expect(TrashTypeHelper.getShortName(paper), 'Cardboard');
        expect(
          TrashTypeHelper.getNotificationTitle(paper),
          'Cardboard goes out',
        );
        expect(
          TrashTypeHelper.getNotificationBody(paper),
          'Remember to take out your Cardboard bin!',
        );
        // Clearing the name brings back the built-in texts.
        final reset = paper.copyWith(clearCustomName: true);
        expect(TrashTypeHelper.getDisplayName(reset), 'Paper');
        expect(TrashTypeHelper.getNotificationTitle(reset), 'Paper goes out');
      });

      test('colors come from the bin color index', () {
        expect(TrashTypeHelper.getColor(glass), BinStyle.colors[5].base);
        expect(
          TrashTypeHelper.getColor(TrashType.bio.copyWith(color: 7)),
          BinStyle.colors[7].base,
        );
      });

      testWidgets('container colors follow the theme', (tester) async {
        late Color light;
        late Color dark;
        late Color text;
        Widget probe(ThemeData theme, void Function(BuildContext) read) =>
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) {
                  read(context);
                  return const SizedBox();
                },
              ),
            );
        await tester.pumpWidget(
          probe(ThemeData.light(), (context) {
            light = TrashTypeHelper.getContainerColor(context, glass);
            text = TrashTypeHelper.getContainerTextColor(context, glass);
          }),
        );
        await tester.pumpWidget(
          probe(ThemeData.dark(), (context) {
            dark = TrashTypeHelper.getContainerColor(context, glass);
          }),
        );
        expect(light, BinStyle.colors[5].base);
        expect(dark, BinStyle.colors[5].darkMode);
        expect(text, BinStyle.colors[5].text);
      });
    });

    group('Consistency checks', () {
      test('every built-in has names, texts and colors', () {
        for (final trashType in TrashType.builtIns) {
          expect(TrashTypeHelper.getDisplayName(trashType), isNotEmpty);
          expect(TrashTypeHelper.getShortName(trashType), isNotEmpty);
          expect(TrashTypeHelper.getDescription(trashType), isNotEmpty);
          expect(
            () => TrashTypeHelper.getNotificationTitle(trashType),
            returnsNormally,
          );
          expect(
            () => TrashTypeHelper.getNotificationBody(trashType),
            returnsNormally,
          );
          expect(() => TrashTypeHelper.getColor(trashType), returnsNormally);
        }
      });

      test('notification titles should not be empty', () {
        for (final trashType in TrashType.builtIns) {
          final title = TrashTypeHelper.getNotificationTitle(trashType);
          expect(title.isNotEmpty, isTrue);
          expect(title.endsWith('goes out'), isTrue);
        }
      });

      test('notification bodies should not be empty', () {
        for (final trashType in TrashType.builtIns) {
          final body = TrashTypeHelper.getNotificationBody(trashType);
          expect(body.isNotEmpty, isTrue);
          expect(body.contains('Remember'), isTrue);
        }
      });
    });
  });
}
