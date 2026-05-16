// lib/flutter_tappay_sdk_spaceshare_platform_interface.dart
import 'package:flutter_tappay_sdk_spaceshare/tappay/card_type.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_tappay_sdk_spaceshare_method_channel.dart';
import 'models/tappay_init_result.dart';
import 'models/tappay_prime.dart';
import 'models/tappay_sdk_common_result.dart';
import 'tappay/auth_methods.dart';
import 'tappay/cart_item.dart';

import 'models/cardholder_prime_result.dart';

/// The interface that implementations of flutter_tappay_sdk_spaceshare must implement.
abstract class FlutterTapPaySdkPlatform extends PlatformInterface {
  FlutterTapPaySdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterTapPaySdkPlatform _instance = MethodChannelFlutterTapPaySdk();

  static FlutterTapPaySdkPlatform get instance => _instance;

  static set instance(FlutterTapPaySdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// To get the native SDK version
  Future<String?> get tapPaySdkVersion;

  /// Initialize TapPay payment SDK
  Future<TapPayInitResult?> initTapPay({
    required int appId,
    required String appKey,
    bool isSandbox = false,
  });

  /// Verify card information
  Future<bool> isCardValid({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String cvv,
  });

  /// Get card's prime
  Future<TapPayPrime?> getCardPrime({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String cvv,

    /// 新增 sandbox 標記：true 用測試環境，false 用正式環境
    bool isSandbox = false,

    /// 可選的持卡人資訊（若要隨 prime 一併送出）
    Map<String, dynamic>? cardholder,
  });

  /// Initialize Google Pay
  Future<TapPaySdkCommonResult?> initGooglePay({
    required String merchantName,
    List<TapPayCardAuthMethod>? allowedAuthMethods,
    List<TapPayCardType>? allowedCardTypes,
    bool? isPhoneNumberRequired = false,
    bool? isEmailRequired = false,
    bool? isBillingAddressRequired = false,
  });

  /// Request Google Pay
  Future<TapPayPrime?> requestGooglePay({
    required double price,
    required String currencyCode,
  });

  /// Initialize Apple Pay
  Future<TapPaySdkCommonResult?> initApplePay({
    required String merchantId,
    required String merchantName,
    List<TapPayCardType>? allowedCardTypes,
    bool? isConsumerNameRequired = false,
    bool? isPhoneNumberRequired = false,
    bool? isEmailRequired = false,
    bool? isBillingAddressRequired = false,
  });

  /// Request Apple Pay
  Future<TapPayPrime?> requestApplePay({
    required List<CartItem> cartItems,
    required String currencyCode,
    required String countryCode,
  });

  /// Report Apple Pay result
  Future<TapPaySdkCommonResult?> applePayResult({required bool result});

  /// (Web Only) Setup TapPay SDK in browser
  Future<void> setupSDK({
    required int appId,
    required String appKey,
    required String serverType,
  }) {
    throw UnimplementedError('setupSDK() has not been implemented.');
  }

  /// (Web Only) Get TapPay device ID from browser
  Future<String> getDeviceId() {
    throw UnimplementedError('getDeviceId() has not been implemented.');
  }

  /// (Web Only) Call TPDirect.card.getPrime() - extended to optionally return cardholder info
  /// Implementations should provide:
  /// - existing getPrime() behavior (return prime String)
  /// - an additional method to return cardholder info if available (see getCardholderInfoPrime)
  Future<String> getPrime() {
    throw UnimplementedError('getPrime() has not been implemented.');
  }

  /// New: obtain prime together with cardholder info (if available) from SDK (Web/native)
  Future<CardholderPrimeResult?> getCardholderInfoPrime() {
    throw UnimplementedError(
      'getCardholderInfoPrime() has not been implemented.',
    );
  }
}
