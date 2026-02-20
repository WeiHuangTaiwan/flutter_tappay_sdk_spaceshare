// lib/src/flutter_tappay_sdk_web_impl.dart
// JS interop implementation for TPDirect (TapPay) on Web.
//
// This file uses dart:js_util to call the global TPDirect object and
// returns a Dart Map (decoded from JS object).
//
// NOTE: The host web page must have included the official TapPay JS SDK
// (e.g., <script src="https://js.tappaysdk.com/tpdirect/v5.21.0"></script> or current version).
// Also TPDirect.setupSDK(...) should already have been called by user code
// (or you can expose a Dart wrapper for that if desired).

import 'dart:async';
import 'dart:html' show window;
import 'dart:js_util' as js_util;

class FlutterTappaySdkWebImpl {
  /// Call TPDirect.card.getPrime (with cardholder info).
  /// [cardholder] is a Dart Map mapped to the expected JS structure by TapPay.
  ///
  /// Returns a Dart Map with the returned JS object (status/msg/prime/card_info etc).
  Future<Map<String, dynamic>?> getPrimeWithCardholder(Map<String, dynamic> cardholder) async {
    final dynamic tpDirect = js_util.getProperty(window, 'TPDirect');
    if (tpDirect == null) {
      throw StateError('TPDirect is not available on window. Make sure TapPay JS SDK is loaded.');
    }

    final dynamic cardObj = js_util.getProperty(tpDirect, 'card');
    if (cardObj == null) {
      throw StateError('TPDirect.card is not available.');
    }

    // Convert Dart map into JS-compatible object
    final dynamic jsCardholder = js_util.jsify(cardholder);

    // The JS API is TPDirect.card.getPrime(cardholder, callback)
    // but newer SDKs expose getPrime returning a Promise. We try to call getPrime
    // and treat the return value as a Promise if possible.
    try {
      final dynamic promiseOrResult = js_util.callMethod(cardObj, 'getPrime', [jsCardholder]);
      // Convert Promise -> Future
      final dynamic result = await js_util.promiseToFuture(promiseOrResult);
      // Convert JS object into Dart object
      final dartified = js_util.dartify(result);
      if (dartified is Map) {
        return Map<String, dynamic>.from(dartified);
      } else {
        // Unexpected shape, return as map with single value
        return {'result': dartified};
      }
    } catch (e) {
      rethrow;
    }
  }
}
