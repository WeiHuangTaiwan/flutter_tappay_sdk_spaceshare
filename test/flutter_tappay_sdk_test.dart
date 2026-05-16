import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tappay_sdk/flutter_tappay_sdk_method_channel.dart';
import 'package:flutter_tappay_sdk/flutter_tappay_sdk_platform_interface.dart';

void main() {
  test('default platform implementation uses method channel', () {
    expect(
      FlutterTapPaySdkPlatform.instance,
      isA<MethodChannelFlutterTapPaySdk>(),
    );
  });
}
