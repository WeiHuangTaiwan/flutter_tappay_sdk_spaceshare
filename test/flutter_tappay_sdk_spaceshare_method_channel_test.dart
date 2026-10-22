import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare_method_channel.dart';
import 'package:flutter_tappay_sdk_spaceshare/tappay/cart_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tappay_sdk_spaceshare');
  final platform = MethodChannelFlutterTapPaySdk();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
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

  test('passes an Apple Pay prime and server result through the iOS channel',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      calls.add(methodCall.method);
      final arguments = Map<String, dynamic>.from(methodCall.arguments as Map);
      switch (methodCall.method) {
        case 'initApplePay':
          expect(arguments['merchantId'], 'merchant.example.test');
          expect(arguments['merchantName'], 'SpaceShare');
          return {'success': true, 'message': null};
        case 'requestApplePay':
          expect(arguments['cartItems'], [
            {'name': 'Booking', 'price': 100.0},
          ]);
          expect(arguments['currencyCode'], 'TWD');
          expect(arguments['countryCode'], 'TW');
          return {
            'success': true,
            'status': null,
            'message': 'Apple Pay prime generated.',
            'prime': 'fake-prime',
          };
        case 'applePayResult':
          expect(arguments['result'], isTrue);
          return {'success': true, 'message': null};
        default:
          fail('Unexpected native method ${methodCall.method}');
      }
    });

    final initialized = await platform.initApplePay(
      merchantId: 'merchant.example.test',
      merchantName: 'SpaceShare',
    );
    final prime = await platform.requestApplePay(
      cartItems: [CartItem(name: 'Booking', price: 100)],
      currencyCode: 'TWD',
      countryCode: 'TW',
    );
    final completed = await platform.applePayResult(result: true);

    expect(initialized?.success, isTrue);
    expect(prime?.success, isTrue);
    expect(prime?.prime, 'fake-prime');
    expect(completed?.success, isTrue);
    expect(calls, ['initApplePay', 'requestApplePay', 'applePayResult']);
  });
}
