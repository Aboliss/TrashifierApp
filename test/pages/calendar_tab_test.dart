import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/season_helper.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

import '../widgets/day_pickups_sheet_test.dart' show usePhoneScreen;

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Centers of the shown month's first outside cells: the one just before
/// day 1 and the one just after the last day, or null when the month starts
/// on a Monday or ends on a Sunday (the grids start on Monday).
({Offset? leading, Offset? trailing}) outsideCellCenters(
  WidgetTester tester,
  DateTime month,
) {
  Offset center(int d) => tester.getCenter(find.text('$d').hitTestable());
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  double? width;
  for (var d = 1; d < 28 && width == null; d++) {
    final a = center(d);
    final b = center(d + 1);
    if ((a.dy - b.dy).abs() < 1) width = b.dx - a.dx;
  }
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month, daysInMonth);
  return (
    leading: first.weekday == DateTime.monday
        ? null
        : center(1) - Offset(width!, 0),
    trailing: last.weekday == DateTime.sunday
        ? null
        : center(daysInMonth) + Offset(width!, 0),
  );
}

void main() {
  group('CalendarTab special days', () {
    // The calendar opens on the real current month, so the tests walk
    // forward from there to the month they need; October and December are
    // always within its one-year range.
    /// Pumps the tab with [override] saved, or without a SeasonService when
    /// null.
    Future<SeasonService?> pumpTab(
      WidgetTester tester,
      SeasonOverride? override,
    ) async {
      usePhoneScreen(tester);
      SeasonService? service;
      if (override != null) {
        SharedPreferences.setMockInitialValues({
          SeasonService.overrideKey: override.name,
        });
        service = SeasonService(random: Random(1));
      }
      // Themed for the season once the saved override has loaded, like
      // MyApp.
      final tab = Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.lightTheme(context.season),
          home: Scaffold(
            body: CalendarTab(datesByType: const {}, onEditDay: (_) {}),
          ),
        ),
      );
      await tester.pumpWidget(
        service == null
            ? tab
            : ChangeNotifierProvider<SeasonService?>.value(
                value: service,
                child: tab,
              ),
      );
      // Let the saved override load.
      await tester.pump();
      if (override != null) {
        expect(service!.override, override);
      }
      return service;
    }

    int shownMonth(WidgetTester tester) {
      final header = find.textContaining(
        RegExp('^(${_monthNames.join('|')}) '),
        findRichText: true,
      );
      expect(header, findsOneWidget);
      final text = tester.widget<RichText>(header).text.toPlainText();
      return _monthNames.indexOf(text.split(' ').first) + 1;
    }

    Future<void> nextMonth(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      // Let the month page slide in. Not pumpAndSettle: Halloween bats
      // flutter forever.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    /// Steps forward until [month] is shown (at most a year ahead).
    Future<void> goToMonth(WidgetTester tester, int month) async {
      for (var i = 0; i < 12 && shownMonth(tester) != month; i++) {
        await nextMonth(tester);
      }
      expect(shownMonth(tester), month);
    }

    Set<SpecialDay> drawnSpecialDays(WidgetTester tester) => tester
        .widgetList<SpecialDayArt>(find.byType(SpecialDayArt))
        .map((art) => art.day)
        .toSet();

    Future<void> selectDay(WidgetTester tester, int day) async {
      // The month pages to either side stay built off screen; only the
      // shown month's cell is hit-testable. (No ensureVisible: it would
      // scroll the month pages too.)
      final onScreen = find.text('$day').hitTestable();
      expect(onScreen, findsOneWidget);
      await tester.tap(onScreen);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    /// The small caps line above the selected day's date.
    String eyebrow(WidgetTester tester) {
      final relative = find.textContaining(
        RegExp(r'(TODAY|TOMORROW|YESTERDAY|IN \d+ DAYS|\d+ DAYS AGO)$'),
      );
      expect(relative, findsOneWidget);
      return tester.widget<Text>(relative).data!;
    }

    testWidgets('Christmas draws its days in December only', (tester) async {
      await pumpTab(tester, SeasonOverride.christmas);

      // Every month up to December, then January.
      for (var i = 0; i < 13; i++) {
        final month = shownMonth(tester);
        if (month == DateTime.december) {
          expect(drawnSpecialDays(tester), {
            SpecialDay.christmasEve,
            SpecialDay.christmasDay,
            SpecialDay.boxingDay,
            SpecialDay.newYearsEve,
          });
          expect(find.byType(SpecialDayArt), findsNWidgets(4));
        } else {
          expect(
            find.byType(SpecialDayArt),
            findsNothing,
            reason: _monthNames[month - 1],
          );
        }
        if (month == DateTime.january && i > 0) break;
        await nextMonth(tester);
      }
      expect(shownMonth(tester), DateTime.january);
    });

    testWidgets('selecting a Christmas day names it on the card', (
      tester,
    ) async {
      await pumpTab(tester, SeasonOverride.christmas);
      await goToMonth(tester, DateTime.december);

      await selectDay(tester, 25);
      expect(eyebrow(tester), startsWith('CHRISTMAS DAY · '));

      await selectDay(tester, 31);
      expect(eyebrow(tester), startsWith('NEW YEAR’S EVE · '));

      await selectDay(tester, 15);
      expect(eyebrow(tester), isNot(contains('·')));
    });

    /// The 46 x 50 cell drawn for [day] in the shown month.
    BoxDecoration cellDecoration(WidgetTester tester, int day) {
      final cell = find
          .ancestor(
            of: find.text('$day').hitTestable(),
            matching: find.byType(Container),
          )
          .first;
      return tester.widget<Container>(cell).decoration! as BoxDecoration;
    }

    testWidgets('a selected Christmas day keeps its art and its own ring', (
      tester,
    ) async {
      await pumpTab(tester, SeasonOverride.christmas);
      final palette = Theme.of(
        tester.element(find.byType(CalendarTab)),
      ).extension<AppPalette>()!;
      expect(palette, isNotNull);
      expect(palette.fab, isNot(palette.ink));

      // Today's ring, seen once another day of this month is selected.
      final today = DateTime.now();
      await selectDay(tester, today.day == 15 ? 14 : 15);
      final todayBorder = cellDecoration(tester, today.day).border! as Border;
      expect(todayBorder.top.color, palette.ink);
      expect(todayBorder.top.width, 2);

      // Pick special days that aren't today, so today's look can't mix in.
      bool isToday(int day) =>
          today.month == DateTime.december && today.day == day;
      final selected = [25, 24, 26].firstWhere((day) => !isToday(day));
      final other = [
        24,
        26,
        25,
      ].firstWhere((day) => day != selected && !isToday(day));

      await goToMonth(tester, DateTime.december);
      await selectDay(tester, selected);
      expect(tester.takeException(), isNull);

      // The accent ring, not today's ink one, and the art stays.
      final selectedBorder = cellDecoration(tester, selected).border! as Border;
      expect(selectedBorder.top.color, palette.fab);
      expect(selectedBorder.top.width, 3);
      expect(selectedBorder, isNot(todayBorder));
      expect(cellDecoration(tester, other).border, isNull);
      expect(cellDecoration(tester, other).color, isNull);

      final selectedCell = find
          .ancestor(
            of: find.text('$selected').hitTestable(),
            matching: find.byType(Container),
          )
          .first;
      final art = find.descendant(
        of: selectedCell,
        matching: find.byType(SpecialDayArt),
      );
      expect(art, findsOneWidget);
      expect(
        tester.widget<SpecialDayArt>(art).day,
        SeasonHelper.specialDayFor(
          DateTime(today.year, 12, selected),
          Season.christmas,
        ),
      );
      expect(find.byType(SpecialDayArt), findsNWidgets(4));

      // Selecting another special day moves the ring.
      await selectDay(tester, other);
      expect(cellDecoration(tester, selected).border, isNull);
      expect(
        (cellDecoration(tester, other).border! as Border).top.color,
        palette.fab,
      );
      expect(find.byType(SpecialDayArt), findsNWidgets(4));
    });

    testWidgets('Halloween draws Oct 31 and names it on the card', (
      tester,
    ) async {
      await pumpTab(tester, SeasonOverride.halloween);
      await goToMonth(tester, DateTime.october);

      expect(drawnSpecialDays(tester), {SpecialDay.halloween});
      expect(find.byType(SpecialDayArt), findsOneWidget);

      await selectDay(tester, 31);
      expect(eyebrow(tester), startsWith('HALLOWEEN · '));

      // December is not decorated during Halloween.
      await goToMonth(tester, DateTime.december);
      expect(find.byType(SpecialDayArt), findsNothing);
    });

    testWidgets('no special days with the season turned off', (tester) async {
      await pumpTab(tester, SeasonOverride.normal);
      await goToMonth(tester, DateTime.december);

      expect(find.byType(SpecialDayArt), findsNothing);
      await selectDay(tester, 25);
      expect(eyebrow(tester), isNot(contains('·')));
    });

    testWidgets('no special days without a SeasonService', (tester) async {
      await pumpTab(tester, null);
      await goToMonth(tester, DateTime.december);

      expect(find.byType(SpecialDayArt), findsNothing);
      await selectDay(tester, 25);
      expect(eyebrow(tester), isNot(contains('·')));
    });
  });

  group('CalendarTab outside days', () {
    testWidgets('tapping where a next or previous month day would be '
        'changes nothing', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: CalendarTab(datesByType: const {}, onEditDay: (_) {}),
          ),
        ),
      );
      await tester.pump();

      final now = DateTime.now();
      String eyebrow() {
        final relative = find.textContaining(
          RegExp(r'(TODAY|TOMORROW|YESTERDAY|IN \d+ DAYS|\d+ DAYS AGO)$'),
        );
        expect(relative, findsOneWidget);
        return tester.widget<Text>(relative).data!;
      }

      String header() => tester
          .widget<RichText>(
            find.textContaining(
              RegExp('^(${_monthNames.join('|')}) '),
              findRichText: true,
            ),
          )
          .text
          .toPlainText();

      // Find a month with trailing next-month cells (at most two steps).
      var month = DateTime(now.year, now.month);
      var cells = outsideCellCenters(tester, month);
      for (var i = 0; i < 2 && cells.trailing == null; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        month = DateTime(month.year, month.month + 1);
        cells = outsideCellCenters(tester, month);
      }
      expect(cells.trailing, isNotNull);

      final before = eyebrow();
      final shown = header();
      for (final position in [cells.trailing, cells.leading]) {
        if (position == null) continue;
        await tester.tapAt(position);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(eyebrow(), before);
        expect(header(), shown);
      }

      // A real day of the month still selects (one that isn't selected).
      final other =
          month.year == now.year && month.month == now.month && now.day == 15
          ? 16
          : 15;
      await tester.tap(find.text('$other').hitTestable());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(eyebrow(), isNot(before));
    });
  });
}
