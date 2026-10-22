# flutter_tappay_sdk_spaceshare

flutter_tappay_sdk_spaceshare is a community Flutter wrapper for TapPay. It keeps one Dart API
for Flutter apps and routes the actual payment-token work to the platform that is
running the app:

- Android: TapPay Android SDK through `MethodChannel`
- iOS: TapPay iOS SDK through `MethodChannel`
- Web: TapPay JavaScript SDK through Flutter web plugin registration

This package is not an official TapPay SDK. It is published by SpaceShare Limited. for
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

When calling `getWebPrime()` directly, configure TapPay Fields in the page
first. The view below can mount and configure them for you.

### Flutter Web hosted fields view

`TapPayWebFieldsView` mounts the three TapPay-hosted card fields inside a
`HtmlElementView`, loads the pinned TapPay Web SDK, and reports whether the
fields and cardholder name are ready. The parent owns its button and calls the
controller only after a user confirms payment:

```dart
import 'package:flutter_tappay_sdk_spaceshare/tappay_web_fields.dart';

final fields = TapPayWebFieldsController();

TapPayWebFieldsView(
  controller: fields,
  appId: appId,
  appKey: appKey,
  isSandbox: true,
  localeCode: 'zh_Hant',
  onValidityChanged: (valid) => setState(() => canSubmit = valid),
);

// Inside the parent's confirm button handler:
final result = await fields.getPrime();
await yourServerCheckout(result.prime, result.cardholderName);
```

The result contains no raw card number, expiration date, or CVC. Send the
one-time prime to your trusted backend promptly; keep the TapPay partner key
and Pay by Prime call there. `TPDirect.card` is a singleton, so mount one active
fields view at a time. On Android and iOS the view is a non-card-entry
placeholder until a native hosted-field implementation is added.

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
  // Send result!.prime to your trusted backend promptly. Do not log it.
} else {
  print(result?.message);
}
```

## Platform Notes

Android Google Pay requires the host app's `MainActivity` to extend
`FlutterFragmentActivity`.

iOS Apple Pay requires the host app to enable the Apple Pay capability, add its
merchant ID to the app entitlements, and complete the Payment Processing
certificate setup in Apple Developer and TapPay Portal. TapPay Portal provides
the CSR that Apple signs. Call `initPayment` before `initApplePay`, then
`requestApplePay` to obtain a prime. Complete Pay by Prime on a trusted server
and call `applePayResult` with the server-confirmed outcome so the payment sheet
can show success or failure. See the [TapPay setup guide](https://docs.tappaysdk.com/apple-pay/en/portal.html).

Web card input should use TapPay Fields so the Flutter app does not handle raw
card data directly in browser code.

See [SpaceShare payment platform matrix](docs/payment-platform-matrix.md) for
the wrapper's current capabilities and the app integration work still required.

.share 
