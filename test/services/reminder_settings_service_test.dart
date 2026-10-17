import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderSettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Lets the constructor's async load from SharedPreferences finish.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    group('loading', () {
      test('defaults when nothing is stored, without notifying', () async {
        final service = ReminderSettingsService();
        var notified = 0;
        service.addListener(() => notified++);
        await settle();

        expect(service.settings, ReminderSettings.defaults);
        expect(notified, 0);
      });

      test('reads stored values and notifies', () async {
        SharedPreferences.setMockInitialValues({
          ReminderSettingsService.daysBeforeKey: 0,
          ReminderSettingsService.hourKey: 6,
          ReminderSettingsService.minuteKey: 30,
        });
        final service = ReminderSettingsService();
        var notified = 0;
        service.addListener(() => notified++);
        await settle();

        expect(
          service.settings,
          const ReminderSettings(daysBefore: 0, hour: 6, minute: 30),
        );
        expect(notified, 1);
      });

      test('invalid stored values fall back to the defaults', () async {
        SharedPreferences.setMockInitialValues({
          ReminderSettingsService.daysBeforeKey: 3,
          ReminderSettingsService.hourKey: 25,
          ReminderSettingsService.minuteKey: 15,
        });
        final service = ReminderSettingsService();
        await settle();

        expect(
          service.settings,
          const ReminderSettings(daysBefore: 1, hour: 19, minute: 15),
        );
      });

      test('values of the wrong type don\'t break loading', () async {
        SharedPreferences.setMockInitialValues({
          ReminderSettingsService.hourKey: 'seven',
        });
        final service = ReminderSettingsService();
        await settle();

        expect(service.settings, ReminderSettings.defaults);
      });
    });

    group('update', () {
      test('persists and notifies', () async {
        final service = ReminderSettingsService();
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        const next = ReminderSettings(daysBefore: 0, hour: 6, minute: 30);
        await service.update(next);

        expect(service.settings, next);
        expect(notified, 1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(ReminderSettingsService.daysBeforeKey), 0);
        expect(prefs.getInt(ReminderSettingsService.hourKey), 6);
        expect(prefs.getInt(ReminderSettingsService.minuteKey), 30);

        // A fresh service picks the saved values up.
        final reloaded = ReminderSettingsService();
        await settle();
        expect(reloaded.settings, next);
      });

      test('the same settings again don\'t notify', () async {
        final service = ReminderSettingsService();
        await settle();
        var notified = 0;
        service.addListener(() => notified++);

        await service.update(ReminderSettings.defaults);
        expect(notified, 0);
      });

      test('a change made before loading finishes wins', () async {
        SharedPreferences.setMockInitialValues({
          ReminderSettingsService.daysBeforeKey: 0,
          ReminderSettingsService.hourKey: 6,
          ReminderSettingsService.minuteKey: 30,
        });
        final service = ReminderSettingsService();
        const chosen = ReminderSettings(daysBefore: 1, hour: 21, minute: 15);
        final saved = service.update(chosen);
        await settle();
        await saved;

        expect(service.settings, chosen);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(ReminderSettingsService.hourKey), 21);
        expect(prefs.getInt(ReminderSettingsService.minuteKey), 15);
      });
    });
  });

  group('context.reminderSettings', () {
    testWidgets('falls back to the defaults without a provider', (
      tester,
    ) async {
      late ReminderSettings seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = context.reminderSettings;
            return const SizedBox();
          },
        ),
      );
      expect(seen, ReminderSettings.defaults);
    });

    testWidgets('follows the service and rebuilds on changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = ReminderSettingsService();
      late ReminderSettings seen;
      await tester.pumpWidget(
        ChangeNotifierProvider<ReminderSettingsService?>.value(
          value: service,
          child: Builder(
            builder: (context) {
              seen = context.reminderSettings;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, ReminderSettings.defaults);

      const next = ReminderSettings(daysBefore: 0, hour: 7, minute: 45);
      service.update(next);
      await tester.pump();
      expect(seen, next);
    });
  });
}
