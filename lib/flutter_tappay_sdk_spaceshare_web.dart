import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'flutter_tappay_sdk_spaceshare_platform_interface.dart';
import 'models/cardholder_prime_result.dart';
import 'models/tappay_init_result.dart';
import 'models/tappay_prime.dart';
import 'models/tappay_sdk_common_result.dart';
import 'src/flutter_tappay_sdk_spaceshare_web_impl.dart';
import 'tappay/auth_methods.dart';
import 'tappay/card_type.dart';
import 'tappay/cart_item.dart';

/// Web implementation of the FlutterTapPaySdk platform interface.
class FlutterTapPaySdkWeb extends FlutterTapPaySdkPlatform {
  static void registerWith(Registrar registrar) {
    FlutterTapPaySdkPlatform.instance = FlutterTapPaySdkWeb();
  }

  final FlutterTappaySdkWebImpl _impl = FlutterTappaySdkWebImpl();

  @override
  Future<String?> get tapPaySdkVersion async {
    try {
      return await _impl.sdkVersion();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TapPayInitResult?> initTapPay({
    required int appId,
    required String appKey,
    bool isSandbox = false,
  }) async {
    try {
      await setupSDK(
        appId: appId,
        appKey: appKey,
        serverType: isSandbox ? 'sandbox' : 'production',
      );
      return TapPayInitResult(success: true);
    } catch (e) {
      return TapPayInitResult(success: false, message: e.toString());
    }
  }

  @override
  Future<bool> isCardValid({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String cvv,
  }) async {
    final status = await _guard(_impl.getTappayFieldsStatus);
    return status?['canGetPrime'] == true;
  }

@override
Future<TapPayPrime?> getCardPrime({
  required String cardNumber,
  required String dueMonth,
  required String dueYear,
  required String cvv,
  bool isSandbox = false,
  Map<String, dynamic>? cardholder,
}) async {
  try {
    final hasRawCardInfo = cardNumber.trim().isNotEmpty &&
        dueMonth.trim().isNotEmpty &&
        dueYear.trim().isNotEmpty &&
        cvv.trim().isNotEmpty;

    final result = hasRawCardInfo
        ? await _impl.getPrimeByCardInfo(
            cardNumber: cardNumber.trim(),
            dueMonth: dueMonth.trim(),
            dueYear: dueYear.trim(),
            cvv: cvv.trim(),
          )
        : await _impl.getPrime();

    return _tapPayPrimeFromWebResult(result);
  } catch (e) {
    return TapPayPrime(success: false, message: e.toString());
  }
}

  @override
  Future<TapPaySdkCommonResult?> initGooglePay({
    required String merchantName,
    List<TapPayCardAuthMethod>? allowedAuthMethods,
    List<TapPayCardType>? allowedCardTypes,
    bool? isPhoneNumberRequired = false,
    bool? isEmailRequired = false,
    bool? isBillingAddressRequired = false,
  }) async {
    return TapPaySdkCommonResult(
      success: false,
      message: 'Google Pay on web uses the TapPay JS button flow.',
    );
  }

  @override
  Future<TapPayPrime?> requestGooglePay({
    required double price,
    required String currencyCode,
  }) async {
    return TapPayPrime(
      success: false,
      message: 'Google Pay on web uses the TapPay JS button flow.',
    );
  }

  @override
  Future<TapPaySdkCommonResult?> initApplePay({
    required String merchantId,
    required String merchantName,
    List<TapPayCardType>? allowedCardTypes,
    bool? isConsumerNameRequired = false,
    bool? isPhoneNumberRequired = false,
    bool? isEmailRequired = false,
    bool? isBillingAddressRequired = false,
  }) async {
    return TapPaySdkCommonResult(
      success: false,
      message: 'Apple Pay on web uses TapPay Payment Request API.',
    );
  }

  @override
  Future<TapPayPrime?> requestApplePay({
    required List<CartItem> cartItems,
    required String currencyCode,
    required String countryCode,
  }) async {
    return TapPayPrime(
      success: false,
      message: 'Apple Pay on web uses TapPay Payment Request API.',
    );
  }

  @override
  Future<TapPaySdkCommonResult?> applePayResult({required bool result}) async {
    return TapPaySdkCommonResult(
      success: false,
      message: 'applePayResult is only available on native iOS.',
    );
  }

  @override
  Future<void> setupSDK({
    required int appId,
    required String appKey,
    required String serverType,
  }) {
    return _impl.setupSDK(
      appId: appId,
      appKey: appKey,
      serverType: serverType,
    );
  }

  @override
  Future<String> getDeviceId() => _impl.getDeviceId();

  @override
  Future<String> getPrime() async {
    final result = await _impl.getPrime();
    final prime = _extractPrime(result);
    if (prime == null || prime.isEmpty) {
      final message = result['msg'] ?? result['message'] ?? 'unknown error';
      throw StateError('TapPay web getPrime failed: $message');
    }
    return prime;
  }

  @override
  Future<CardholderPrimeResult?> getCardholderInfoPrime() async {
    try {
      final result = await _impl.getCardholderPrime();
      return CardholderPrimeResult.fromMap(_normaliseCardholderResult(result));
    } catch (e) {
      return CardholderPrimeResult(success: false, message: e.toString());
    }
  }

  Future<T?> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (_) {
      return null;
    }
  }

  TapPayPrime _tapPayPrimeFromWebResult(Map<String, dynamic> result) {
    final status = _toInt(result['status']);
    final prime = _extractPrime(result);
    return TapPayPrime(
      success: status == 0 && prime != null && prime.isNotEmpty,
      status: status,
      message: (result['msg'] ?? result['message'])?.toString(),
      prime: prime,
    );
  }

  Map<String, dynamic> _normaliseCardholderResult(Map<String, dynamic> result) {
    final status = _toInt(result['status']);
    return {
      ...result,
      'success': result['success'] as bool? ?? status == 0,
      'status': status,
      'message': result['msg'] ?? result['message'],
      'prime': result['prime'],
    };
  }

  String? _extractPrime(Map<String, dynamic> result) {
    final topLevelPrime = result['prime'];
    if (topLevelPrime != null) {
      return topLevelPrime.toString();
    }

    final card = result['card'];
    if (card is Map) {
      final cardPrime = card['prime'];
      if (cardPrime != null) {
        return cardPrime.toString();
      }
    }

    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
