import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('TPDirect')
external JSObject? get _tpDirect;

class FlutterTappaySdkWebImpl {
  JSObject get _sdk {
    final sdk = _tpDirect;
    if (sdk == null) {
      throw StateError(
        'TPDirect is not available. Add the TapPay web SDK script before using '
        'flutter_tappay_sdk_spaceshare on web.',
      );
    }
    return sdk;
  }

  Future<void> setupSDK({
    required int appId,
    required String appKey,
    required String serverType,
  }) async {
    _sdk.callMethod<JSAny?>(
      'setupSDK'.toJS,
      appId.toJS,
      appKey.toJS,
      serverType.toJS,
    );
  }

  Future<String?> sdkVersion() async {
    final version = _sdk.getProperty<JSAny?>('version'.toJS)?.dartify();
    return version?.toString();
  }

  Future<String> getDeviceId() async {
    final result = _sdk.callMethod<JSAny?>('getDeviceId'.toJS)?.dartify();
    return result?.toString() ?? '';
  }

  Future<Map<String, dynamic>> getTappayFieldsStatus() async {
    final card = _sdk.getProperty<JSObject>('card'.toJS);
    final result =
        card.callMethod<JSAny?>('getTappayFieldsStatus'.toJS)?.dartify();
    return _asStringMap(result);
  }

  Future<Map<String, dynamic>> getPrime() {
    final card = _sdk.getProperty<JSObject>('card'.toJS);
    return _callbackResult((callback) {
      card.callMethod<JSAny?>('getPrime'.toJS, callback);
    });
  }
  
  Future<Map<String, dynamic>> getPrimeByCardInfo({
    required String cardNumber,
    required String dueMonth,
    required String dueYear,
    required String cvv,
  }) {
    final card = _sdk.getProperty<JSObject>('card'.toJS);

    final cardInfo = <String, dynamic>{
      // TapPay Web SDK raw-card key names.
      // If TapPay returns invalid-parameter, verify these names against the
      // exact TPDirect web SDK version you load in FlutterFlow Web.
      'cardNumber': cardNumber,
      'dueMonth': dueMonth,
      'dueYear': dueYear,
      'ccv': cvv,

      // Also include common alternative names for compatibility.
      'cardnumber': cardNumber,
      'expirationMonth': dueMonth,
      'expirationYear': dueYear,
      'cvv': cvv,
    }.jsify() as JSObject;

    return _callbackResult((callback) {
      card.callMethod<JSAny?>(
        'getPrime'.toJS,
        cardInfo,
        callback,
      );
    });
  }

  Future<Map<String, dynamic>> getCardholderPrime() {
    final cardholder = _sdk.getProperty<JSObject>('cardholder'.toJS);
    return _errorFirstCallbackResult((callback) {
      cardholder.callMethod<JSAny?>('getPrime'.toJS, callback);
    });
  }

  Future<Map<String, dynamic>> _callbackResult(
    void Function(JSFunction callback) invoke,
  ) {
    final completer = Completer<Map<String, dynamic>>();

    final callback = ((JSAny? result) {
      if (!completer.isCompleted) {
        completer.complete(_asStringMap(result?.dartify()));
      }
    }).toJS;

    invoke(callback);
    return completer.future;
  }

  Future<Map<String, dynamic>> _errorFirstCallbackResult(
    void Function(JSFunction callback) invoke,
  ) {
    final completer = Completer<Map<String, dynamic>>();

    final callback = ((JSAny? error, JSAny? result) {
      if (completer.isCompleted) {
        return;
      }

      if (error != null) {
        final errorMap = _asStringMap(error.dartify());
        if (errorMap.isNotEmpty) {
          completer.complete({
            'success': false,
            ...errorMap,
          });
          return;
        }
      }

      completer.complete(_asStringMap(result?.dartify()));
    }).toJS;

    invoke(callback);
    return completer.future;
  }

  Map<String, dynamic> _asStringMap(Object? value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
