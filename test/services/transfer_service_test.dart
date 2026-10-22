import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/services/transfer_service.dart';

const MethodChannel channel = MethodChannel('com.trashifier_app/transfer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransferService', () {
    late List<MethodCall> calls;

    TestDefaultBinaryMessenger messenger() =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    void mockChannel(Object? Function(MethodCall call) handler) {
      messenger().setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });
    }

    Matcher throwsTransferError(TransferError error) => throwsA(
      isA<TransferException>().having((e) => e.error, 'error', error),
    );

    /// Sends a call from "Android" to the Dart side, as the platform would.
    Future<void> sendFromPlatform(String method, Object? arguments) {
      final completer = Completer<void>();
      messenger().handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) => completer.complete(),
      );
      return completer.future;
    }

    setUp(() {
      calls = [];
    });

    tearDown(() {
      messenger().setMockMethodCallHandler(channel, null);
      TransferService.stopListening();
    });

    group('saveFile', () {
      test('should pass name and content and return true when saved', () async {
        mockChannel((_) => true);

        final saved = await TransferService.saveFile(
          'trashifier.json',
          '{"app":"trashifier"}',
        );

        expect(saved, isTrue);
        expect(calls, hasLength(1));
        expect(calls.single.method, equals('saveFile'));
        expect(
          calls.single.arguments,
          equals({
            'name': 'trashifier.json',
            'content': '{"app":"trashifier"}',
          }),
        );
      });

      test('should return false when the user cancels', () async {
        mockChannel((_) => false);

        expect(await TransferService.saveFile('a.json', 'x'), isFalse);
      });

      test('should return false when the platform returns null', () async {
        mockChannel((_) => null);

        expect(await TransferService.saveFile('a.json', 'x'), isFalse);
      });
    });

    group('openFile', () {
      test('should return the file text', () async {
        mockChannel((_) => '{"app":"trashifier"}');

        expect(
          await TransferService.openFile(),
          equals('{"app":"trashifier"}'),
        );
        expect(calls.single.method, equals('openFile'));
        expect(calls.single.arguments, isNull);
      });

      test('should return null when the user cancels', () async {
        mockChannel((_) => null);

        expect(await TransferService.openFile(), isNull);
      });
    });

    group('shareFile', () {
      test('should pass name, content and title', () async {
        mockChannel((_) => null);

        await TransferService.shareFile('s.json', 'body', title: 'Share');

        expect(calls.single.method, equals('shareFile'));
        expect(
          calls.single.arguments,
          equals({'name': 's.json', 'content': 'body', 'title': 'Share'}),
        );
      });
    });

    group('scanQr', () {
      test('should return the scanned text or null', () async {
        mockChannel((_) => 'trashifier://import?v=1&d=AAEA');
        expect(
          await TransferService.scanQr(),
          equals('trashifier://import?v=1&d=AAEA'),
        );

        mockChannel((_) => null);
        expect(await TransferService.scanQr(), isNull);
        expect(calls.map((c) => c.method), everyElement('scanQr'));
      });
    });

    group('errors', () {
      final methods = <String, Future<Object?> Function()>{
        'saveFile': () => TransferService.saveFile('a.json', 'x'),
        'openFile': TransferService.openFile,
        'shareFile': () => TransferService.shareFile('a', 'b', title: 'c'),
        'scanQr': TransferService.scanQr,
        'initialIncoming': TransferService.initialIncoming,
      };

      for (final entry in methods.entries) {
        group(entry.key, () {
          test('should map too_large to tooLarge', () async {
            mockChannel(
              (_) => throw PlatformException(code: 'too_large', message: 'big'),
            );

            await expectLater(
              entry.value(),
              throwsA(
                isA<TransferException>()
                    .having((e) => e.error, 'error', TransferError.tooLarge)
                    .having((e) => e.detail, 'detail', 'big'),
              ),
            );
          });

          test('should map unavailable to unavailable', () async {
            mockChannel((_) => throw PlatformException(code: 'unavailable'));

            await expectLater(
              entry.value(),
              throwsTransferError(TransferError.unavailable),
            );
          });

          test('should map other codes to failed', () async {
            for (final code in ['io', 'failed', '', 'TOO_LARGE']) {
              mockChannel((_) => throw PlatformException(code: code));

              await expectLater(
                entry.value(),
                throwsTransferError(TransferError.failed),
                reason: 'code: $code',
              );
            }
          });

          test('should map a missing plugin to unavailable', () async {
            // No mock handler registered.
            await expectLater(
              entry.value(),
              throwsTransferError(TransferError.unavailable),
            );
          });
        });
      }

      test('should describe itself with error and detail', () {
        expect(
          const TransferException(TransferError.failed, 'disk').toString(),
          equals('TransferException(failed: disk)'),
        );
      });
    });

    group('initialIncoming', () {
      test('should return null when nothing arrived', () async {
        mockChannel((_) => null);

        expect(await TransferService.initialIncoming(), isNull);
        expect(calls.single.method, equals('initialIncoming'));
      });

      test('should parse a link', () async {
        mockChannel(
          (_) => {'kind': 'link', 'value': 'trashifier://import?v=1&d=AAEA'},
        );

        final incoming = await TransferService.initialIncoming();

        expect(incoming, isNotNull);
        expect(incoming!.isLink, isTrue);
        expect(incoming.value, equals('trashifier://import?v=1&d=AAEA'));
        expect(incoming.error, isNull);
      });

      test('should parse a file', () async {
        mockChannel((_) => {'kind': 'file', 'value': '{"app":"trashifier"}'});

        final incoming = await TransferService.initialIncoming();

        expect(incoming!.isLink, isFalse);
        expect(incoming.value, equals('{"app":"trashifier"}'));
        expect(incoming.error, isNull);
      });

      test('should map a too_large error', () async {
        mockChannel((_) => {'kind': 'error', 'value': 'too_large'});

        final incoming = await TransferService.initialIncoming();

        expect(incoming!.error, equals(TransferError.tooLarge));
        expect(incoming.isLink, isFalse);
        expect(incoming.value, isEmpty);
      });

      test('should map other errors to failed', () async {
        for (final value in ['io', 'unavailable', null, 42]) {
          mockChannel((_) => {'kind': 'error', 'value': value});

          final incoming = await TransferService.initialIncoming();

          expect(incoming!.error, TransferError.failed, reason: '$value');
          expect(incoming.value, isEmpty);
        }
      });

      test('should treat a non-string value as empty', () async {
        mockChannel((_) => {'kind': 'file', 'value': 42});

        final incoming = await TransferService.initialIncoming();

        expect(incoming!.value, isEmpty);
        expect(incoming.error, isNull);
      });
    });

    group('listen', () {
      test('should pass incoming links and files to the handler', () async {
        final received = <IncomingSchedule>[];
        TransferService.listen(received.add);

        await sendFromPlatform('incoming', {
          'kind': 'link',
          'value': 'trashifier://import?v=1&d=AAEA',
        });
        await sendFromPlatform('incoming', {
          'kind': 'file',
          'value': '{"app":"trashifier"}',
        });
        await sendFromPlatform('incoming', {
          'kind': 'error',
          'value': 'too_large',
        });

        expect(received, hasLength(3));
        expect(received[0].isLink, isTrue);
        expect(received[0].value, equals('trashifier://import?v=1&d=AAEA'));
        expect(received[1].isLink, isFalse);
        expect(received[1].value, equals('{"app":"trashifier"}'));
        expect(received[2].error, equals(TransferError.tooLarge));
      });

      test('should ignore other methods and non-map arguments', () async {
        final received = <IncomingSchedule>[];
        TransferService.listen(received.add);

        await sendFromPlatform('somethingElse', {'kind': 'link', 'value': 'x'});
        await sendFromPlatform('incoming', 'trashifier://import?v=1&d=AAEA');
        await sendFromPlatform('incoming', null);

        expect(received, isEmpty);
      });

      test('should stop delivering after stopListening', () async {
        final received = <IncomingSchedule>[];
        TransferService.listen(received.add);
        TransferService.stopListening();

        await sendFromPlatform('incoming', {'kind': 'link', 'value': 'x'});

        expect(received, isEmpty);
      });

      test('should replace an earlier handler', () async {
        final first = <IncomingSchedule>[];
        final second = <IncomingSchedule>[];
        TransferService.listen(first.add);
        TransferService.listen(second.add);

        await sendFromPlatform('incoming', {'kind': 'link', 'value': 'x'});

        expect(first, isEmpty);
        expect(second, hasLength(1));
      });
    });
  });
}
