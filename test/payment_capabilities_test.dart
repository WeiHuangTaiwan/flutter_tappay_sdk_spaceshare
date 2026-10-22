import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare_method_channel.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tappay_sdk_spaceshare');
  final originalPlatform = FlutterTapPaySdkPlatform.instance;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    FlutterTapPaySdkPlatform.instance = originalPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reports SDK support without treating it as wallet availability', () {
    final web = TapPayPaymentCapabilities.forPlatform(
      isWeb: true,
      targetPlatform: TargetPlatform.android,
    );
    expect(web.platform, TapPayRuntimePlatform.web);
    expect(web.hostedCardFieldsSupported, isTrue);
    expect(web.nativeCardPrimeSupported, isFalse);
    expect(web.showApplePay, isFalse);
    expect(web.showGooglePay, isFalse);

    final ios = TapPayPaymentCapabilities.forPlatform(
      isWeb: false,
      targetPlatform: TargetPlatform.iOS,
      googlePayAvailable: true,
    );
    expect(ios.nativeCardPrimeSupported, isTrue);
    expect(ios.applePaySupported, isTrue);
    expect(ios.googlePaySupported, isFalse);
    expect(ios.showGooglePay, isFalse);
  });

  test('shows Apple Pay only after the native availability check succeeds',
      () async {
    FlutterTapPaySdkPlatform.instance = MethodChannelFlutterTapPaySdk();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initApplePay');
      return {'success': true, 'message': null};
    });

    final result = await FlutterTapPaySdk().checkPaymentCapabilities(
      appleMerchantId: 'merchant.example.test',
      appleMerchantName: 'SpaceShare',
      googleMerchantName: 'SpaceShare',
    );
    expect(result.showApplePay, isTrue);
    expect(result.showGooglePay, isFalse);
  });

  test('keeps Google Pay hidden when the native availability check fails',
      () async {
    FlutterTapPaySdkPlatform.instance = MethodChannelFlutterTapPaySdk();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initGooglePay');
      return {'success': false, 'message': 'Unavailable'};
    });

    final result = await FlutterTapPaySdk().checkPaymentCapabilities(
      googleMerchantName: 'SpaceShare',
    );
    expect(result.googlePaySupported, isTrue);
    expect(result.showGooglePay, isFalse);
  });
}
