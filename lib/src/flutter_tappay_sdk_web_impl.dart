// lib/src/flutter_tappay_sdk_web_impl.dart
import 'dart:async';
import 'dart:js_util';
import 'dart:js';

class FlutterTappaySdkWebImpl {
  /// 初始化 TPDirect Web SDK
  Future<void> setupSDK({
    required int appId,
    required String appKey,
    required String serverType,
  }) async {
    final tpDirect = getProperty(context, 'TPDirect');
    if (tpDirect == null) {
      throw Exception('TPDirect is not available. Make sure you included the TapPay SDK script in index.html');
    }

    callMethod(tpDirect, 'setupSDK', [appId, appKey, serverType]);
  }

  /// 原先行為：呼叫 TPDirect.card.getPrime 並取回 Prime Token (只回傳 String prime)
  Future<String> getPrime() {
    final completer = Completer<String>();
    final tpDirect = getProperty(context, 'TPDirect');
    if (tpDirect == null) {
      completer.completeError(Exception('TPDirect is not available'));
      return completer.future;
    }

    final card = getProperty(tpDirect, 'card');

    callMethod(card, 'getPrime', [
      allowInterop((result) {
        final status = getProperty(result, 'status');
        if (status != 0) {
          final msg = getProperty(result, 'msg')?.toString() ?? 'Unknown error';
          completer.completeError(Exception('getPrime failed: $msg'));
          return;
        }

        final cardInfo = getProperty(result, 'card');
        final prime = getProperty(cardInfo, 'prime');
        completer.complete(prime.toString());
      })
    ]);

    return completer.future;
  }

  /// 新：回傳 prime + cardholder info（若 web SDK 回傳）
  /// 回傳 Map: { 'success': bool, 'prime': String, 'cardholder': { ... }, 'status': int?, 'message': String? }
  Future<Map<String, dynamic>> getPrimeWithCardholder() {
    final completer = Completer<Map<String, dynamic>>();
    final tpDirect = getProperty(context, 'TPDirect');
    if (tpDirect == null) {
      completer.completeError(Exception('TPDirect is not available'));
      return completer.future;
    }

    final card = getProperty(tpDirect, 'card');

    callMethod(card, 'getPrime', [
      allowInterop((result) {
        final status = getProperty(result, 'status');
        if (status != 0) {
          final msg = getProperty(result, 'msg')?.toString() ?? 'Unknown error';
          completer.complete({
            'success': false,
            'status': status,
            'message': msg,
            'prime': null,
            'cardholder': null,
          });
          return;
        }

        final cardInfo = getProperty(result, 'card');
        final prime = getProperty(cardInfo, 'prime')?.toString();
        // TPDirect web 返回的 card 物件如果含有 cardholder 資訊，嘗試讀出
        final cardholder = getProperty(cardInfo, 'cardholder');
        Map<String, dynamic>? cardholderMap;
        if (cardholder != null) {
          // 依 Web SDK 的欄位命名嘗試轉成 Map
          cardholderMap = <String, dynamic>{};
          final email = getProperty(cardholder, 'email');
          final phoneNumber = getProperty(cardholder, 'phone_number');
          final phoneNumberCountryCode = getProperty(cardholder, 'phone_number_country_code');
          final nameEn = getProperty(cardholder, 'name_en');
          final name = getProperty(cardholder, 'name');

          if (email != null) cardholderMap['email'] = email.toString();
          if (phoneNumber != null) cardholderMap['phone_number'] = phoneNumber.toString();
          if (phoneNumberCountryCode != null) cardholderMap['phone_number_country_code'] = phoneNumberCountryCode.toString();
          if (nameEn != null) cardholderMap['name_en'] = nameEn.toString();
          if (name != null) cardholderMap['name'] = name.toString();
        }

        completer.complete({
          'success': true,
          'status': 0,
          'message': null,
          'prime': prime,
          'cardholder': cardholderMap,
        });
      })
    ]);

    return completer.future;
  }

  /// 取得裝置 ID（若有使用 RBA）
  Future<String> getDeviceId() async {
    final tpDirect = getProperty(context, 'TPDirect');
    if (tpDirect == null) {
      throw Exception('TPDirect is not available');
    }
    final deviceId = callMethod(tpDirect, 'getDeviceId', []);
    return deviceId.toString();
  }
}
