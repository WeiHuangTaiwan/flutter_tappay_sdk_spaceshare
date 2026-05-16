import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tappay_sdk/flutter_tappay_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tappay_sdk');
  final platform = MethodChannelFlutterTapPaySdk();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads native SDK version from method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      expect(methodCall.method, 'sdkVersion');
      return 'mock-sdk-version';
    });

    expect(await platform.tapPaySdkVersion, 'mock-sdk-version');
  });

  test('maps initTapPay result from method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      expect(methodCall.method, 'initPayment');
      expect(methodCall.arguments, {
        'appId': 123,
        'appKey': 'app-key',
        'isSandbox': true,
      });
      return {'success': true, 'message': null};
    });

    final result = await platform.initTapPay(
      appId: 123,
      appKey: 'app-key',
      isSandbox: true,
    );

    expect(result?.success, isTrue);
    expect(result?.message, isNull);
  });

  test('maps getCardPrime result from method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      expect(methodCall.method, 'getPrimeByCardInfo');
      return {
        'success': true,
        'status': null,
        'message': null,
        'prime': 'prime-test',
      };
    });

    final result = await platform.getCardPrime(
      cardNumber: '4242424242424242',
      dueMonth: '12',
      dueYear: '30',
      cvv: '123',
      isSandbox: true,
    );

    expect(result?.success, isTrue);
    expect(result?.prime, 'prime-test');
  });
}
