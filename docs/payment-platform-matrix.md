# SpaceShare payment platform matrix

This describes the current code state, not production merchant approval. A
payment entry should be shown only after its runtime availability check and
merchant configuration both succeed. The server determines the final charge
result; a client-side prime only starts that process.

`FlutterTapPaySdk.paymentCapabilities` reports SDK support for the current
platform. After TapPay initialization, call `checkPaymentCapabilities` with the
configured merchant details to receive `showApplePay` and `showGooglePay`.
Those booleans reflect native initialization results; the app must also gate
buttons on its merchant approval and available server checkout method. Web
card Fields belong to the SpaceShare custom widget, outside this SDK.

| Entry | Web | iOS app | Android app |
| --- | --- | --- | --- |
| New credit card | `TapPayWebFieldsView` can return a prime; SpaceShare's `SpaceShareTapPayCardForm` is not yet mounted in a payment page or wired to its `onPrime` callback. | Native card prime API exists. End-to-end payment needs device testing. | Native card prime API exists. End-to-end payment needs device testing. |
| Apple Pay | Separate Web integration and merchant/domain setup are required; this wrapper has no Web Apple Pay API. | Method-channel bridge can return a prime. Merchant ID, Apple Pay capability, Payment Processing certificate, TapPay Portal setup, server payment, and real-device testing remain. | No native Apple Pay implementation. |
| Google Pay | Separate Web integration and merchant/domain setup are required; this wrapper has no Web Google Pay API. | No native Google Pay implementation in this wrapper; browser support is a separate Web question. | Method-channel bridge can return a prime. Merchant configuration, server payment, and real-device testing remain. |
| Saved card | The app uses its own backend card-token flow. | Same. | Same. |

## SpaceShare checkout boundary

The current `processSpaceBookingCheckoutV2` action sends
`paymentMethod: saved_card` to `executeSpaceBookingCheckoutV2`. The deployed
checkout function accepts only `saved_card`. New-card entry first calls
`tapPaySetupCard`, then charges through the saved-card path. The existing
`tapPaySetupCardSafely` action obtains a prime through a native card API and
therefore cannot complete Web new-card entry. Wiring a Web `onPrime` callback
requires a trusted setup or checkout action that accepts that prime and then
confirms the server result; simply displaying the widget is insufficient.

Keep TapPay partner credentials, Pay by Prime, and Pay by Card Token on the
trusted backend. Never log a prime or include it in diagnostic `toString()`
output. Make retries use the server's checkout identity and state query so a
timeout cannot cause an accidental second charge.

The Android plugin accepts the host as an `Activity` and registers Activity
result and permission-result listeners through Flutter's `ActivityPluginBinding`.
The generated SpaceShare `MainActivity` currently extends `FlutterActivity`;
the SDK code does not establish a `FlutterFragmentActivity` requirement.

## Source references

- [TapPay Apple Pay Portal setup](https://docs.tappaysdk.com/apple-pay/en/portal.html)
- [TapPay payment reference](https://docs.tappaysdk.com/apple-pay/en/reference.html)
- [Google Pay API FAQ](https://developers.google.com/pay/api/faq)
