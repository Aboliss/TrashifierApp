import 'package:flutter/services.dart';

/// What failed when saving, opening, sharing or scanning.
enum TransferError {
  /// The file is bigger than any schedule could be.
  tooLarge,

  /// No file picker or QR scanner on this device (e.g. no Play services).
  unavailable,

  /// Reading or writing the file failed.
  failed,
}

class TransferException implements Exception {
  final TransferError error;
  final String? detail;

  const TransferException(this.error, [this.detail]);

  @override
  String toString() => 'TransferException(${error.name}: $detail)';
}

/// A schedule link or file the app was opened with.
class IncomingSchedule {
  /// True for a `trashifier://import` link, false for file contents.
  final bool isLink;
  final String value;

  /// Set when the file couldn't be read; [value] is empty then.
  final TransferError? error;

  const IncomingSchedule({
    required this.isLink,
    required this.value,
    this.error,
  });
}

/// Android's file picker, share sheet and QR scanner (TransferChannel.kt).
class TransferService {
  static const MethodChannel _channel = MethodChannel(
    'com.trashifier_app/transfer',
  );

  /// Lets the user pick where to save [content]; false if they cancelled.
  static Future<bool> saveFile(String name, String content) async {
    final saved = await _call<bool>('saveFile', {
      'name': name,
      'content': content,
    });
    return saved ?? false;
  }

  /// Lets the user pick a file and returns its text; null if they cancelled.
  static Future<String?> openFile() => _call<String>('openFile');

  /// Opens the share sheet with [content] as the file [name].
  static Future<void> shareFile(
    String name,
    String content, {
    required String title,
  }) => _call<void>('shareFile', {
    'name': name,
    'content': content,
    'title': title,
  });

  /// Scans a QR code and returns its text; null if the user cancelled.
  static Future<String?> scanQr() => _call<String>('scanQr');

  /// The link or file the app was started with, once. Set the handler with
  /// [listen] first so nothing that arrives in between is lost.
  static Future<IncomingSchedule?> initialIncoming() async {
    final raw = await _call<Map<Object?, Object?>>('initialIncoming');
    return raw == null ? null : _incoming(raw);
  }

  /// Calls [onIncoming] for links and files that reach the running app.
  static void listen(void Function(IncomingSchedule) onIncoming) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'incoming' && call.arguments is Map) {
        onIncoming(_incoming(call.arguments as Map<Object?, Object?>));
      }
    });
  }

  static void stopListening() => _channel.setMethodCallHandler(null);

  static IncomingSchedule _incoming(Map<Object?, Object?> raw) {
    final kind = raw['kind'];
    final value = raw['value'] is String ? raw['value'] as String : '';
    if (kind == 'error') {
      return IncomingSchedule(
        isLink: false,
        value: '',
        error: value == 'too_large'
            ? TransferError.tooLarge
            : TransferError.failed,
      );
    }
    return IncomingSchedule(isLink: kind == 'link', value: value);
  }

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw TransferException(switch (e.code) {
        'too_large' => TransferError.tooLarge,
        'unavailable' => TransferError.unavailable,
        _ => TransferError.failed,
      }, e.message);
    } on MissingPluginException catch (e) {
      // Not on Android (e.g. widget tests).
      throw TransferException(TransferError.unavailable, e.message);
    }
  }
}
