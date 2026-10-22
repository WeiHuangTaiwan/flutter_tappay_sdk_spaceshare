import 'dart:async';

/// Contains only the TapPay prime and the cardholder's English name.
/// Card number, expiry and CVC never cross this API.
final class TapPayWebPrimeResult {
  const TapPayWebPrimeResult({
    required this.prime,
    required this.cardholderName,
  });

  final String prime;
  final String cardholderName;
}

/// Lets a parent button request a prime from the mounted TapPay Fields view.
final class TapPayWebFieldsController {
  Future<TapPayWebPrimeResult> Function()? _requestPrime;

  bool get isAttached => _requestPrime != null;

  Future<TapPayWebPrimeResult> getPrime() {
    final request = _requestPrime;
    if (request == null) {
      throw StateError('TapPay Fields are not ready.');
    }
    return request();
  }

  void attach(Future<TapPayWebPrimeResult> Function() requestPrime) {
    _requestPrime = requestPrime;
  }

  void detach(Future<TapPayWebPrimeResult> Function() requestPrime) {
    if (_requestPrime == requestPrime) _requestPrime = null;
  }
}
