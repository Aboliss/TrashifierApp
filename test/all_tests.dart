import 'package:flutter_test/flutter_test.dart';

import 'helpers/date_format_helper_test.dart' as date_format_helper_tests;
import 'helpers/notification_helper_test.dart' as notification_helper_tests;
import 'helpers/pickup_copy_helper_test.dart' as pickup_copy_helper_tests;
import 'helpers/pickup_dates_helper_test.dart' as pickup_dates_helper_tests;
import 'helpers/season_helper_test.dart' as season_helper_tests;
import 'helpers/trash_type_helper_test.dart' as trash_type_helper_tests;
import 'models/reminder_settings_test.dart' as reminder_settings_tests;
import 'models/trash_date_test.dart' as trash_date_tests;
import 'models/trash_type_test.dart' as trash_type_tests;
import 'pages/calendar_tab_test.dart' as calendar_tab_tests;
import 'pages/home_page_season_test.dart' as home_page_season_tests;
import 'pages/settings_page_test.dart' as settings_page_tests;
import 'pages/splash_screen_test.dart' as splash_screen_tests;
import 'services/notifications_service_test.dart'
    as notifications_service_tests;
import 'services/reminder_settings_service_test.dart'
    as reminder_settings_service_tests;
import 'services/season_service_test.dart' as season_service_tests;
import 'services/storage_service_test.dart' as storage_service_tests;
import 'services/theme_service_test.dart' as theme_service_tests;
import 'widget_test.dart' as widget_tests;
import 'widgets/calendar_dialog_test.dart' as calendar_dialog_tests;
import 'widgets/day_pickups_sheet_test.dart' as day_pickups_sheet_tests;
import 'widgets/season_decor_test.dart' as season_decor_tests;
import 'widgets/swipe_reveal_row_test.dart' as swipe_reveal_row_tests;

void main() {
  group('Trashifier App Tests', () {
    group('Models', () {
      trash_date_tests.main();
      trash_type_tests.main();
      reminder_settings_tests.main();
    });

    group('Helpers', () {
      date_format_helper_tests.main();
      trash_type_helper_tests.main();
      pickup_copy_helper_tests.main();
      notification_helper_tests.main();
      pickup_dates_helper_tests.main();
      season_helper_tests.main();
    });

    group('Services', () {
      storage_service_tests.main();
      notifications_service_tests.main();
      theme_service_tests.main();
      season_service_tests.main();
      reminder_settings_service_tests.main();
    });

    group('Widgets', () {
      widget_tests.main();
      day_pickups_sheet_tests.main();
      calendar_dialog_tests.main();
      calendar_tab_tests.main();
      season_decor_tests.main();
      splash_screen_tests.main();
      home_page_season_tests.main();
      settings_page_tests.main();
      swipe_reveal_row_tests.main();
    });
  });
}
