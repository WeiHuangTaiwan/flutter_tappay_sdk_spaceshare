# flutter_tappay_sdk_spaceshare

flutter_tappay_sdk_spaceshare is a community Flutter wrapper for TapPay. It keeps one Dart API
for Flutter apps and routes the actual payment-token work to the platform that is
running the app:

- Android: TapPay Android SDK through `MethodChannel`
- iOS: TapPay iOS SDK through `MethodChannel`
- Web: TapPay JavaScript SDK through Flutter web plugin registration

This package is not an official TapPay SDK. It is published by SpaceShare for
teams that need a practical cross-platform starting point while TapPay's official
examples remain platform-specific.

## Features

- Direct Pay card prime on Android and iOS
- TapPay Fields prime on Web
- Cardholder prime bridge for Web
- Apple Pay bridge for iOS
- Google Pay bridge for Android

## Install

```yaml
dependencies:
  flutter_tappay_sdk_spaceshare:
    git:
      url: https://github.com/WeiHuangTaiwan/flutter_tappay_sdk_spaceshare.git
```

## Web Setup

Add TapPay's web SDK before Flutter starts, usually in `web/index.html`.

```html
<script src="https://js.tappaysdk.com/sdk/tpdirect/v5.24.0"></script>
```

TapPay Fields must still be configured in the page with TapPay-hosted DOM
elements before calling `getWebPrime()` or `getCardPrime()` on web.

## Basic Usage

```dart
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare.dart';

final tappay = FlutterTapPaySdk();

await tappay.initTapPay(
  appId: 12345,
  appKey: 'app_key',
  isSandbox: true,
);

final result = await tappay.getCardPrime(
  cardNumber: '4242424242424242',
  dueMonth: '12',
  dueYear: '30',
  cvv: '123',
  isSandbox: true,
);

if (result?.success == true) {
  print(result?.prime);
} else {
  print(result?.message);
}
```

## Platform Notes

Android Google Pay requires the host app's `MainActivity` to extend
`FlutterFragmentActivity`.

iOS Apple Pay requires the host app to enable the Apple Pay capability and add
the merchant ID in Xcode.

Web card input should use TapPay Fields so the Flutter app does not handle raw
card data directly in browser code.
