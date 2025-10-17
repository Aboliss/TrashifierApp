import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.trashifier_app/widget',
  );

  static Future<void> updateWidget() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // Ignore widget update errors - they're not critical
    }
  }
}
