# flutter_tappay_sdk_spaceshare_example

This example demonstrates the plugin API paths that are currently wired in the
package implementation.

## What This Example Covers

- TapPay SDK initialization through `FlutterTapPaySdk.initTapPay`.
- Native card prime creation through `FlutterTapPaySdk.getCardPrime`.
- Android Google Pay through `initGooglePay` and `requestGooglePay`.

## Credentials

The app is intentionally non-runnable by default. Update
`example/lib/constants.dart` with real TapPay sandbox credentials before using
payment calls:

- `kTapPayAppId`
- `kTapPayAppKey`

The example refuses to initialize TapPay while these values are placeholders.

The sample card expiry uses a future two-digit year. Before running the example,
verify that the expiry date is still in the future for the TapPay sandbox card
you are using. Do not rely on a fixed sample year forever.

## Platform Notes

Android Google Pay requires the example `MainActivity` to extend
`FlutterFragmentActivity`, which this example already does.

The iOS method channel wires `initApplePay`, `requestApplePay`, and
`applePayResult` to `ApplePayHandler`. This example keeps Apple Pay disabled
because it has no merchant ID, payment processing certificate, or Apple Pay
capability. A host app must configure those before requesting a prime. After
the prime arrives, complete Pay by Prime on a trusted server and call
`applePayResult` with the server-confirmed outcome.

Web-specific APIs are not demonstrated here because this example does not
include an `example/web/` host page. A web app must load TapPay JS before using
`setupWebSDK`, `getWebPrime`, `getWebDeviceId`, or web prime flows.

## Validation

From the repository root:

```sh
flutter analyze
flutter test
cd example && flutter test
```
