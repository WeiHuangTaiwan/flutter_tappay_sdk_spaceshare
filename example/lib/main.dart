import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare.dart';

import 'constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _tapPaySdk = FlutterTapPaySdk();

  String _tapPaySdkVersion = 'Unknown';
  bool _isTapPayReady = false;
  String _statusMessage = _hasTapPayCredentials
      ? 'TapPay is not initialized yet.'
      : 'TapPay credentials are placeholders. Update constants.dart before running payment calls.';

  static bool get _hasTapPayCredentials {
    return kTapPayAppId > 0 &&
        kTapPayAppKey.trim().isNotEmpty &&
        kTapPayAppKey != kPlaceholderTapPayAppKey;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_hasTapPayCredentials) {
      unawaited(_initTapPay());
    }
  }

  Future<void> _initTapPay() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Web is not configured in this example. Add TapPay JS host setup before using web APIs.';
      });
      return;
    }

    String tapPaySdkVersion = 'Unknown';
    bool isTapPayReady = false;
    String statusMessage = 'TapPay initialization failed.';

    try {
      final initResult = await _tapPaySdk.initTapPay(
        appId: kTapPayAppId,
        appKey: kTapPayAppKey,
        isSandbox: true,
      );
      log(initResult?.toJson() ?? 'no initResult');
      isTapPayReady = initResult?.success == true;
      statusMessage = initResult?.message?.isNotEmpty == true
          ? initResult!.message!
          : isTapPayReady
              ? 'TapPay initialized in sandbox mode.'
              : 'TapPay initialization returned an unsuccessful result.';

      if (isTapPayReady) {
        tapPaySdkVersion =
            await _tapPaySdk.tapPaySdkVersion ?? 'Unknown TapPay SDK version';
      }
    } on PlatformException catch (error, stackTrace) {
      statusMessage = 'TapPay initialization threw a platform exception.';
      log(statusMessage, error: error, stackTrace: stackTrace);
    }

    if (!mounted) return;

    setState(() {
      _tapPaySdkVersion = tapPaySdkVersion;
      _isTapPayReady = isTapPayReady;
      _statusMessage = statusMessage;
    });
  }

  Future<void> _getCardPrime() async {
    try {
      final prime = await _tapPaySdk.getCardPrime(
        cardNumber: kDefaultTestingCardNumber,
        dueMonth: kDefaultTestingDueMonth,
        dueYear: kDefaultTestingDueYear,
        cvv: kDefaultTestingCvv,
        isSandbox: true,
      );
      log('prime: ${prime?.toJson()}');
    } on PlatformException catch (error, stackTrace) {
      log('getCardPrime failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _requestGooglePay() async {
    try {
      final isGooglePayReady = await _tapPaySdk.initGooglePay(
        merchantName: 'Flutter Cafe',
      );
      log('isGooglePayReady: ${isGooglePayReady?.toJson()}');

      if (isGooglePayReady?.success == true) {
        final payResult = await _tapPaySdk.requestGooglePay(price: 2);
        log('payResult: ${payResult?.toJson()}');
      }
    } on PlatformException catch (error, stackTrace) {
      log('Google Pay failed', error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TapPay SDK Example'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('TapPay SDK initial result: $_isTapPayReady'),
            Text('TapPay SDK version: $_tapPaySdkVersion'),
            Text(_statusMessage),
            const SizedBox(height: 12),
            ListTile(
              enabled: _isTapPayReady,
              title: const Text('Get Prime by Payment Card'),
              subtitle: const Text(
                'Requires real sandbox credentials and a future card expiry date.',
              ),
              onTap: _isTapPayReady ? _getCardPrime : null,
            ),
            if (_isAndroid)
              ListTile(
                enabled: _isTapPayReady,
                title: const Text('Start Google Pay'),
                subtitle: const Text(
                  'Android only. MainActivity must extend FlutterFragmentActivity.',
                ),
                onTap: _isTapPayReady ? _requestGooglePay : null,
              )
            else
              const ListTile(
                enabled: false,
                title: Text('Google Pay unavailable on this platform'),
                subtitle: Text('The plugin exposes Google Pay for Android.'),
              ),
            const ListTile(
              enabled: false,
              title: Text('Apple Pay unavailable in this example'),
              subtitle: Text(
                'The Dart API exists, but the current iOS method-channel implementation does not wire Apple Pay calls.',
              ),
            ),
            if (kIsWeb)
              const ListTile(
                enabled: false,
                title: Text('Web setup not included'),
                subtitle: Text(
                  'Add TapPay JS to the host page before using web-specific APIs.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
