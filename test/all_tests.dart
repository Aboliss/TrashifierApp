import 'package:flutter_test/flutter_test.dart';

import 'helpers/calendar_helper_test.dart' as calendar_helper_tests;
import 'helpers/date_format_helper_test.dart' as date_format_helper_tests;
import 'helpers/notification_helper_test.dart' as notification_helper_tests;
import 'helpers/trash_type_helper_test.dart' as trash_type_helper_tests;
import 'models/trash_date_test.dart' as trash_date_tests;
import 'models/trash_type_test.dart' as trash_type_tests;
import 'services/notifications_service_test.dart'
    as notifications_service_tests;
import 'services/storage_service_test.dart' as storage_service_tests;
import 'services/theme_service_test.dart' as theme_service_tests;
import 'widget_test.dart' as widget_tests;

void main() {
  group('Trashifier App Tests', () {
    group('Models', () {
      trash_date_tests.main();
      trash_type_tests.main();
    });

    group('Helpers', () {
      date_format_helper_tests.main();
      trash_type_helper_tests.main();
      calendar_helper_tests.main();
      notification_helper_tests.main();
    });

    group('Services', () {
      storage_service_tests.main();
      notifications_service_tests.main();
      theme_service_tests.main();
    });

    group('Widgets', () {
      widget_tests.main();
    });
  });
}
