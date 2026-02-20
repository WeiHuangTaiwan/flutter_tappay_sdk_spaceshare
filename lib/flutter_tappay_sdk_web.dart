// lib/flutter_tappay_sdk_web.dart
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'flutter_tappay_sdk_platform_interface.dart';
import 'models/cardholder_prime_result.dart';
import 'models/tappay_cardholder.dart';
import 'src/flutter_tappay_sdk_web_impl.dart';

/// Web implementation of the FlutterTapPaySdk platform interface.
///
/// This registers itself as the instance for `FlutterTapPaySdkPlatform`.
class FlutterTapPaySdkWeb extends FlutterTapPaySdkPlatform {
  /// Register this class as the platform implementation.
  static void registerWith(Registrar registrar) {
    FlutterTapPaySdkPlatform.instance = FlutterTapPaySdkWeb();
  }

  final FlutterTappaySdkWebImpl _impl = FlutterTappaySdkWebImpl();

  @override
  Future<CardholderPrimeResult> getCardholderInfoPrime(TappayCardholder cardholder) async {
    // call the web impl which talks to TPDirect JS SDK
    try {
      final Map<String, dynamic>? result = await _impl.getPrimeWithCardholder(cardholder.toJson());

      if (result == null) {
        return CardholderPrimeResult(
          status: -1,
          msg: 'no response from web SDK',
          prime: null,
        );
      }

      // Map the result into our model
      return CardholderPrimeResult.fromJson(result);
    } catch (e, st) {
      // Defensive: any JS/interop error -> return result with error info
      return CardholderPrimeResult(
        status: -1,
        msg: 'exception: ${e.toString()}',
        prime: null,
      );
    }
  }

  // 如果你的 platform interface 還有其他 web-specific 方法，也可以在這裡實作。
}
