// lib/models/cardholder_prime_result.dart
class CardholderPrimeResult {
  /// Whether the cardholder-prime call succeeded.
  final bool success;

  /// TapPay returns a status integer; 0 or 1 usually means success depending on API.
  final int? status;

  /// message from TapPay (or SDK)
  final String? message;

  /// The prime string (used by your server to Pay By Prime)
  final String? prime;

  /// card_info or card_info result returned by TapPay; keep as raw map
  final Map<String, dynamic>? cardInfo;

  CardholderPrimeResult({
    bool? success,
    this.status,
    String? message,
    String? msg,
    this.prime,
    this.cardInfo,
  })  : success = success ?? status == 0,
        message = message ?? msg;

  String? get msg => message;

  /// Existing factory kept (json)
  factory CardholderPrimeResult.fromJson(Map<String, dynamic> json) {
    // TapPay sometimes returns 'msg' or 'message', and card info could be 'card_info'
    final int? statusVal = _toInt(json['status']);
    final String? msgVal =
        json['msg'] ?? json['message'] ?? json['statusMessage']?.toString();
    final String? primeVal = json['prime']?.toString();

    Map<String, dynamic>? cardInfo;
    if (json.containsKey('card_info')) {
      final v = json['card_info'];
      if (v is Map) cardInfo = Map<String, dynamic>.from(v);
    } else if (json.containsKey('cardInfo')) {
      final v = json['cardInfo'];
      if (v is Map) cardInfo = Map<String, dynamic>.from(v);
    }

    return CardholderPrimeResult(
      success: json['success'] as bool? ?? statusVal == 0,
      status: statusVal,
      message: msgVal,
      prime: primeVal,
      cardInfo: cardInfo,
    );
  }

  /// New: fromMap alias for consistency with other models (fromMap/fromMapFromMap)
  factory CardholderPrimeResult.fromMap(Map<String, dynamic> map) {
    // just forward to fromJson for compatibility
    return CardholderPrimeResult.fromJson(map);
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'status': status,
        'message': message,
        'msg': message,
        'prime': prime,
        'card_info': cardInfo,
      };

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
