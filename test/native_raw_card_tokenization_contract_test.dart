import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native raw-card flows use the direct token API', () {
    final iosSource =
        File('ios/Classes/FlutterTapPaySdkPlugin.swift').readAsStringSync();
    final androidSource = File(
      'android/src/main/kotlin/kent/chien/flutter_tappay_sdk_spaceshare/'
      'FlutterTapPaySdkPlugin.kt',
    ).readAsStringSync();

    expect(
      iosSource,
      contains('.createToken(withGeoLocation: "UNKNOWN")'),
      reason: 'Raw iOS card data must not be sent through TPDForm.getPrime().',
    );
    expect(
      RegExp(
        r'TPDCard\.setWithCardNumber\([\s\S]*?\.getPrime\(\)',
      ).hasMatch(iosSource),
      isFalse,
      reason: 'TapPay rejects raw-card getPrime calls with status 88011.',
    );

    expect(
      androidSource,
      contains('tpdCard.createToken("UNKNOWN")'),
      reason: 'Android raw card data must continue using createToken().',
    );
    expect(
      androidSource,
      isNot(contains('tpdCard.getPrime()')),
      reason:
          'The Android raw-card flow must not switch to TPDForm.getPrime().',
    );
  });
}
