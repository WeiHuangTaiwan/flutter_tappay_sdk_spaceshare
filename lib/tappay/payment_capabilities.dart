import 'package:flutter/foundation.dart';

/// SDK support is distinct from wallet availability on a particular device.
enum TapPayRuntimePlatform { web, ios, android, unsupported }

class TapPayPaymentCapabilities {
  const TapPayPaymentCapabilities({
    required this.platform,
    this.applePayAvailable = false,
    this.googlePayAvailable = false,
  });

  factory TapPayPaymentCapabilities.current() =>
      TapPayPaymentCapabilities.forPlatform(
        isWeb: kIsWeb,
        targetPlatform: defaultTargetPlatform,
      );

  factory TapPayPaymentCapabilities.forPlatform({
    required bool isWeb,
    required TargetPlatform targetPlatform,
    bool applePayAvailable = false,
    bool googlePayAvailable = false,
  }) {
    final platform = isWeb
        ? TapPayRuntimePlatform.web
        : switch (targetPlatform) {
            TargetPlatform.iOS => TapPayRuntimePlatform.ios,
            TargetPlatform.android => TapPayRuntimePlatform.android,
            _ => TapPayRuntimePlatform.unsupported,
          };
    return TapPayPaymentCapabilities(
      platform: platform,
      applePayAvailable:
          platform == TapPayRuntimePlatform.ios && applePayAvailable,
      googlePayAvailable:
          platform == TapPayRuntimePlatform.android && googlePayAvailable,
    );
  }

  final TapPayRuntimePlatform platform;

  /// True on Web where the hosted TapPay Fields widget can collect a card.
  bool get hostedCardFieldsSupported => platform == TapPayRuntimePlatform.web;

  /// True on iOS/Android where the native card-prime API exists.
  bool get nativeCardPrimeSupported =>
      platform == TapPayRuntimePlatform.ios ||
      platform == TapPayRuntimePlatform.android;

  bool get applePaySupported => platform == TapPayRuntimePlatform.ios;
  bool get googlePaySupported => platform == TapPayRuntimePlatform.android;

  /// Set only after `initApplePay` has reported success on this device.
  final bool applePayAvailable;

  /// Set only after `initGooglePay` has reported success on this device.
  final bool googlePayAvailable;

  bool get showApplePay => applePaySupported && applePayAvailable;
  bool get showGooglePay => googlePaySupported && googlePayAvailable;
}
