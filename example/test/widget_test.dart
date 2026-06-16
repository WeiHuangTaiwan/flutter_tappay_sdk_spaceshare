import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tappay_sdk_spaceshare_example/main.dart';

void main() {
  testWidgets('shows placeholder credential state before initialization',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('TapPay SDK initial result: false'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('TapPay credentials are placeholders'),
      ),
      findsOneWidget,
    );
    expect(find.text('Get Prime by Payment Card'), findsOneWidget);
    expect(find.text('Apple Pay unavailable in this example'), findsOneWidget);
  });
}
