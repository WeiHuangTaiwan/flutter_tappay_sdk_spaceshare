// lib/flutter_tappay_sdk_web.dart
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'flutter_tappay_sdk_platform_interface.dart';
import 'flutter_tappay_sdk_method_channel.dart';
import 'src/flutter_tappay_sdk_web_impl.dart';

import 'models/cardholder_prime_result.dart';
import 'models/tappay_cardholder.dart';

/// A web implementation of the FlutterTapPay SDK.
class FlutterTapPaySdkWeb extends MethodChannelFlutterTapPaySdk {
  /// 註冊點，Flutter Web 會調用
  static void registerWith(Registrar registrar) {
    FlutterTapPaySdkPlatform.instance = FlutterTapPaySdkWeb();
  }

  @override
  Future<void> setupSDK({
    required int appId,
    required String appKey,
    required String serverType,
  }) {
    return FlutterTappaySdkWebImpl().setupSDK(
      appId: appId,
      appKey: appKey,
      serverType: serverType,
    );
  }

  @override
  Future<String> getPrime() async {
    final prime = await FlutterTappaySdkWebImpl().getPrime();
    if (prime == null || prime.isEmpty) {
      throw Exception('getPrime failed: Received null or empty prime');
    }
    return prime;
  }

  @override
  Future<String> getDeviceId() {
    return FlutterTappaySdkWebImpl().getDeviceId();
  }

  /// 這個方法就是你要的：呼叫 web impl 的 getPrimeWithCardholder()
  /// 並把回傳 map 轉成 CardholderPrimeResult
  @override
  Future<CardholderPrimeResult?> getCardholderInfoPrime() async {
    final map = await FlutterTappaySdkWebImpl().getPrimeWithCardholder();
    if (map == null) return CardholderPrimeResult(success: false);

    return CardholderPrimeResult.fromMap(map);
  }
}
