import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tappay_sdk_spaceshare_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example starts with placeholder credential notice',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('TapPay credentials are placeholders'),
      ),
      findsOneWidget,
    );
  });
}
