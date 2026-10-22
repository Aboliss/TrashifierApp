import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Runs before every test file (see flutter_test docs).
///
/// The app loads intl's date symbols for all languages in main() before
/// anything formats a date; tests need the same, even for English.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
