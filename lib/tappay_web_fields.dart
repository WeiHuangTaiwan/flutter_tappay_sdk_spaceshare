/// TapPay-hosted card fields for Flutter Web. The public API remains available
/// on native targets so a FlutterFlow project can compile for every platform.
library;

export 'src/tappay_web_fields_stub.dart'
    if (dart.library.js_interop) 'src/tappay_web_fields_web.dart';
