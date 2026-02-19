// lib/models/cardholder_prime_result.dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'tappay_cardholder.dart';

class CardholderPrimeResult {
  final bool success;
  final int? status;
  final String? message;
  final String? prime;
  final TapPayCardholder? cardholder;

  CardholderPrimeResult({
    required this.success,
    this.status,
    this.message,
    this.prime,
    this.cardholder,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'status': status,
      'message': message,
      'prime': prime,
      'cardholder': cardholder?.toMap(),
    }..removeWhere((_, v) => v == null);
  }

  factory CardholderPrimeResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return CardholderPrimeResult(success: false);
    }

    return CardholderPrimeResult(
      success: map['success'] == null ? false : (map['success'] as bool),
      status: map['status'] as int?,
      message: map['message'] as String?,
      prime: map['prime'] as String?,
      cardholder: TapPayCardholder.fromMap(map['cardholder'] as Map?),
    );
  }

  String toJson() => json.encode(toMap());

  factory CardholderPrimeResult.fromJson(String source) =>
      CardholderPrimeResult.fromMap(json.decode(source) as Map<dynamic, dynamic>);

  @override
  String toString() {
    return 'CardholderPrimeResult(success: $success, status: $status, message: $message, prime: $prime, cardholder: $cardholder)';
  }
}
