import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:flutter_tappay_sdk_spaceshare/flutter_tappay_sdk_spaceshare.dart';
import 'package:web/web.dart' as web;

export 'tappay_web_fields_model.dart';
import 'tappay_web_fields_model.dart';

@JS('TPDirect')
external JSObject? get _tpDirect;

const _sdkUrl = 'https://js.tappaysdk.com/sdk/tpdirect/v5.25.0';
const _sdkIntegrity =
    'sha256-WwF2exxNABEFOnxgGlHUdXHAM49O/UbVK0xDAZhrxbM=';

/// Mounts TapPay-hosted card number, expiry and CVC iframes in Flutter Web.
/// Only one instance should be active at a time: TPDirect.card is a singleton.
class TapPayWebFieldsView extends StatefulWidget {
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
  State<TapPayWebFieldsView> createState() => _TapPayWebFieldsViewState();
}

class _TapPayWebFieldsViewState extends State<TapPayWebFieldsView> {
  web.HTMLDivElement? _host;
  web.HTMLDivElement? _number;
  web.HTMLDivElement? _expiry;
  web.HTMLDivElement? _ccv;
  web.HTMLDivElement? _numberFrame;
  web.HTMLDivElement? _expiryFrame;
  web.HTMLDivElement? _ccvFrame;
  web.HTMLDivElement? _numberError;
  web.HTMLDivElement? _expiryError;
  web.HTMLDivElement? _ccvError;
  web.HTMLInputElement? _name;
  JSFunction? _updateCallback;
  bool _ready = false;
  bool _cardValid = false;
  bool _reportedValid = false;
  int _mountSerial = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.attach(_getPrime);
  }

  @override
  void didUpdateWidget(covariant TapPayWebFieldsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detach(_getPrime);
      widget.controller.attach(_getPrime);
    }
    if (oldWidget.localeCode != widget.localeCode ||
        oldWidget.appId != widget.appId ||
        oldWidget.appKey != widget.appKey ||
        oldWidget.isSandbox != widget.isSandbox) {
      _ready = false;
      _cardValid = false;
      _emitValidity();
    }
  }

  @override
  void dispose() {
    _mountSerial++;
    widget.controller.detach(_getPrime);
    super.dispose();
  }

  Future<TapPayWebPrimeResult> _getPrime() async {
    final cardholderName = _name?.value.trim() ?? '';
    if (!_ready || !_cardValid || cardholderName.isEmpty) {
      throw StateError('TapPay Fields are incomplete.');
    }
    final prime = await FlutterTapPaySdk.getWebPrime();
    if (prime.isEmpty) throw StateError('TapPay returned an empty prime.');
    return TapPayWebPrimeResult(
      prime: prime,
      cardholderName: cardholderName,
    );
  }

  void _emitValidity() {
    final valid = _ready && _cardValid && (_name?.value.trim().isNotEmpty ?? false);
    if (valid == _reportedValid) return;
    _reportedValid = valid;
    widget.onValidityChanged?.call(valid);
  }

  void _onElementCreated(Object element) {
    final host = element as web.HTMLDivElement;
    _host = host;
    _ready = false;
    _cardValid = false;
    _emitValidity();
    host.className = 'ss-tappay-fields';
    host.style.width = '100%';
    host.style.height = '100%';
    host.style.overflow = 'auto';

    final style = web.HTMLStyleElement()..textContent = _fieldCss;
    host.appendChild(style);
    final labels = _labels(widget.localeCode);

    final numberRow = _field(labels.number, labels.numberError);
    _number = numberRow.field;
    _numberFrame = numberRow.frame;
    _numberError = numberRow.error;
    host.appendChild(numberRow.wrapper);

    final nameWrapper = web.HTMLDivElement()..className = 'ss-tp-field';
    final nameLabel = web.HTMLDivElement()
      ..className = 'ss-tp-label'
      ..textContent = labels.name;
    _name = web.HTMLInputElement()
      ..className = 'ss-tp-name'
      ..placeholder = labels.namePlaceholder
      ..maxLength = 45
      ..autocapitalize = 'words'
      ..spellcheck = false;
    _name!.setAttribute('autocomplete', 'cc-name');
    _name!.addEventListener(
      'input',
      ((web.Event _) => _emitValidity()).toJS,
    );
    final nameFrame = web.HTMLDivElement()..className = 'ss-tp-frame';
    nameFrame.appendChild(_name!);
    nameWrapper.appendChild(nameLabel);
    nameWrapper.appendChild(nameFrame);
    final nameHint = web.HTMLDivElement()
      ..className = 'ss-tp-hint'
      ..textContent = labels.nameHint;
    nameWrapper.appendChild(nameHint);
    host.appendChild(nameWrapper);

    final grid = web.HTMLDivElement()..className = 'ss-tp-grid';
    final expiryRow = _field(labels.expiry, labels.expiryError);
    _expiry = expiryRow.field;
    _expiryFrame = expiryRow.frame;
    _expiryError = expiryRow.error;
    grid.appendChild(expiryRow.wrapper);
    final ccvRow = _field(labels.ccv, labels.ccvError);
    _ccv = ccvRow.field;
    _ccvFrame = ccvRow.frame;
    _ccvError = ccvRow.error;
    grid.appendChild(ccvRow.wrapper);
    host.appendChild(grid);

    final serial = ++_mountSerial;
    unawaited(_initialize(serial));
  }

  Future<void> _initialize(int serial) async {
    try {
      final host = _host;
      if (host == null) return;
      for (var attempt = 0; attempt < 150 && !host.isConnected; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      if (!mounted || serial != _mountSerial || !host.isConnected) {
        throw StateError('TapPay Fields could not be attached to the page.');
      }
      await _ensureSdkScript();
      if (!mounted || serial != _mountSerial) return;
      await FlutterTapPaySdk.setupWebSDK(
        appId: widget.appId,
        appKey: widget.appKey,
        serverType: widget.isSandbox ? 'sandbox' : 'production',
      );
      final card = _tpDirect!.getProperty<JSObject>('card'.toJS);
      final config = <String, Object?>{
        'fields': <String, Object?>{
          'number': <String, Object?>{
            'element': _number,
            'placeholder': '0000 0000 0000 0000',
          },
          'expirationDate': <String, Object?>{
            'element': _expiry,
            'placeholder': 'MM / YY',
          },
          'ccv': <String, Object?>{
            'element': _ccv,
            'placeholder': _labels(widget.localeCode).ccv,
          },
        },
        'styles': <String, Object?>{
          'input': <String, String>{
            'color': '#17191d',
            'font-family': '-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif',
            'font-size': '15px',
          },
          ':focus': <String, String>{'color': '#17191d'},
          '.invalid': <String, String>{'color': '#b42318'},
        },
        'isMaskCreditCardNumber': true,
        'maskCreditCardNumberRange': <String, int>{
          'beginIndex': 6,
          'endIndex': 11,
        },
      }.jsify();
      card.callMethod<JSAny?>('setup'.toJS, config);
      _updateCallback = ((JSAny? update) {
        if (!mounted || serial != _mountSerial) return;
        final data = update?.dartify();
        if (data is! Map) return;
        final status = data['status'];
        if (status is Map) {
          _setError(_numberFrame, _numberError, status['number'] == 2);
          _setError(_expiryFrame, _expiryError, status['expiry'] == 2);
          _setError(_ccvFrame, _ccvError, status['ccv'] == 2);
        }
        _cardValid = data['canGetPrime'] == true;
        _emitValidity();
      }).toJS;
      card.callMethod<JSAny?>('onUpdate'.toJS, _updateCallback!);
      _ready = true;
      _emitValidity();
    } catch (error) {
      if (mounted && serial == _mountSerial) {
        _ready = false;
        _cardValid = false;
        _emitValidity();
        widget.onLoadError?.call(error.runtimeType.toString());
      }
    }
  }

  void _setError(
    web.HTMLDivElement? frame,
    web.HTMLDivElement? error,
    bool invalid,
  ) {
    frame?.classList.toggle('ss-tp-invalid', invalid);
    if (error != null) error.style.display = invalid ? 'block' : 'none';
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
        key: ValueKey('tappay-${widget.localeCode}-${widget.appId}-${widget.isSandbox}'),
        tagName: 'div',
        onElementCreated: _onElementCreated,
      );
}

Future<void>? _scriptLoading;

Future<void> _ensureSdkScript() => _scriptLoading ??= _loadScript();

Future<void> _loadScript() async {
  if (_tpDirect != null) return;
  if (web.document.querySelector('script[src="$_sdkUrl"]') == null) {
    final script = web.HTMLScriptElement()
      ..src = _sdkUrl
      ..integrity = _sdkIntegrity
      ..crossOrigin = 'anonymous';
    web.document.head!.appendChild(script);
  }
  for (var attempt = 0; attempt < 100; attempt++) {
    if (_tpDirect != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  _scriptLoading = null;
  throw StateError('TapPay Web SDK did not load.');
}

({
  web.HTMLDivElement wrapper,
  web.HTMLDivElement frame,
  web.HTMLDivElement field,
  web.HTMLDivElement error,
}) _field(String label, String errorText) {
  final wrapper = web.HTMLDivElement()..className = 'ss-tp-field';
  final title = web.HTMLDivElement()
    ..className = 'ss-tp-label'
    ..textContent = label;
  final frame = web.HTMLDivElement()..className = 'ss-tp-frame';
  final field = web.HTMLDivElement()..className = 'ss-tp-host';
  final error = web.HTMLDivElement()
    ..className = 'ss-tp-error'
    ..textContent = errorText;
  error.style.display = 'none';
  frame.appendChild(field);
  wrapper.appendChild(title);
  wrapper.appendChild(frame);
  wrapper.appendChild(error);
  return (wrapper: wrapper, frame: frame, field: field, error: error);
}

typedef _Labels = ({
  String number,
  String numberError,
  String name,
  String namePlaceholder,
  String nameHint,
  String expiry,
  String expiryError,
  String ccv,
  String ccvError,
});

_Labels _labels(String locale) => switch (locale.replaceAll('-', '_')) {
      'zh_Hant' => (
          number: '卡號',
          numberError: '請確認卡號是否正確。',
          name: '持卡人英文姓名',
          namePlaceholder: '與卡片上的姓名相同',
          nameHint: '請填寫與卡片相同的英文姓名。',
          expiry: '有效期限',
          expiryError: '請確認有效期限是否正確。',
          ccv: '安全碼',
          ccvError: '請確認安全碼是否正確。',
        ),
      'zh_Hans' => (
          number: '卡号',
          numberError: '请确认卡号是否正确。',
          name: '持卡人英文姓名',
          namePlaceholder: '与卡片上的姓名相同',
          nameHint: '请填写与卡片相同的英文姓名。',
          expiry: '有效期',
          expiryError: '请确认有效期是否正确。',
          ccv: '安全码',
          ccvError: '请确认安全码是否正确。',
        ),
      'ja' => (
          number: 'カード番号',
          numberError: 'カード番号をご確認ください。',
          name: 'カード名義（英字）',
          namePlaceholder: 'カード記載の英字氏名',
          nameHint: 'カードに記載された英字氏名を入力してください。',
          expiry: '有効期限',
          expiryError: '有効期限をご確認ください。',
          ccv: 'セキュリティコード',
          ccvError: 'セキュリティコードをご確認ください。',
        ),
      'ko' => (
          number: '카드 번호',
          numberError: '카드 번호를 확인해 주세요.',
          name: '카드 소유자 영문 이름',
          namePlaceholder: '카드에 표기된 영문 이름',
          nameHint: '카드에 표기된 영문 이름을 입력해 주세요.',
          expiry: '유효기간',
          expiryError: '유효기간을 확인해 주세요.',
          ccv: '보안 코드',
          ccvError: '보안 코드를 확인해 주세요.',
        ),
      _ => (
          number: 'Card number',
          numberError: 'Check your card number.',
          name: 'Cardholder name in English',
          namePlaceholder: 'Name as shown on your card',
          nameHint: 'Enter the English name shown on your card.',
          expiry: 'Expiration date',
          expiryError: 'Check the expiration date.',
          ccv: 'Security code',
          ccvError: 'Check the security code.',
        ),
    };

const _fieldCss = '''
.ss-tappay-fields { box-sizing:border-box; color:#17191d; font-family:-apple-system,BlinkMacSystemFont,"Noto Sans TC","Segoe UI",sans-serif; }
.ss-tappay-fields * { box-sizing:border-box; }
.ss-tappay-fields .ss-tp-field { margin-bottom:18px; min-width:0; }
.ss-tappay-fields .ss-tp-label { margin-bottom:8px; color:#344054; font-size:13px; font-weight:650; }
.ss-tappay-fields .ss-tp-frame { display:flex; align-items:center; min-height:50px; overflow:hidden; border:1px solid #dce1e7; border-radius:12px; background:#f7f8fa; }
.ss-tappay-fields .ss-tp-frame:focus-within, .ss-tappay-fields .ss-tp-frame:has(.tappay-field-focus) { border-color:#235cda; background:white; box-shadow:0 0 0 3px rgba(35,92,218,.12); }
.ss-tappay-fields .ss-tp-frame.ss-tp-invalid { border-color:#b42318; }
.ss-tappay-fields .ss-tp-host { width:100%; height:48px; padding:0 14px; }
.ss-tappay-fields .ss-tp-host iframe { display:block; width:100%; height:100%; border:0; }
.ss-tappay-fields .ss-tp-name { width:100%; height:48px; padding:0 14px; border:0; outline:0; background:transparent; color:#17191d; font-size:15px; }
.ss-tappay-fields .ss-tp-name::placeholder { color:#98a2b3; }
.ss-tappay-fields .ss-tp-hint { margin-top:6px; color:#667085; font-size:12px; line-height:1.45; }
.ss-tappay-fields .ss-tp-error { margin-top:6px; color:#b42318; font-size:12px; line-height:1.45; }
.ss-tappay-fields .ss-tp-grid { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:14px; }
@media(max-width:480px) { .ss-tappay-fields .ss-tp-grid { gap:10px; } }
''';
