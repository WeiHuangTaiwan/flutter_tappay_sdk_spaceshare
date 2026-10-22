import 'package:flutter/material.dart';

export 'tappay_web_fields_model.dart';
import 'tappay_web_fields_model.dart';

/// Native placeholder. Native card entry will be supplied by the TapPay
/// Android/iOS path in a later version; no raw card inputs are created here.
class TapPayWebFieldsView extends StatelessWidget {
  const TapPayWebFieldsView({
    super.key,
    required this.controller,
    required this.appId,
    required this.appKey,
    required this.isSandbox,
    required this.localeCode,
    this.onValidityChanged,
    this.onLoadError,
  });

  final TapPayWebFieldsController controller;
  final int appId;
  final String appKey;
  final bool isSandbox;
  final String localeCode;
  final ValueChanged<bool>? onValidityChanged;
  final ValueChanged<String>? onLoadError;

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('TapPay Web Fields are available on Web only.'),
      );
}
