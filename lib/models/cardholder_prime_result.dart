// lib/models/cardholder_prime_result.dart
class CardholderPrimeResult {
  /// TapPay returns a status integer; 0 or 1 usually means success depending on API.
  final int? status;

  /// message from TapPay (or SDK)
  final String? msg;

  /// The prime string (used by your server to Pay By Prime)
  final String? prime;

  /// card_info or card_info result returned by TapPay; keep as raw map
  final Map<String, dynamic>? cardInfo;

  CardholderPrimeResult({
    this.status,
    this.msg,
    this.prime,
    this.cardInfo,
  });

  /// Existing factory kept (json)
  factory CardholderPrimeResult.fromJson(Map<String, dynamic> json) {
    // TapPay sometimes returns 'msg' or 'message', and card info could be 'card_info'
    final int? statusVal = _toInt(json['status']);
    final String? msgVal = json['msg'] ?? json['message'] ?? json['statusMessage']?.toString();
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
      status: statusVal,
      msg: msgVal,
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
        'status': status,
        'msg': msg,
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
