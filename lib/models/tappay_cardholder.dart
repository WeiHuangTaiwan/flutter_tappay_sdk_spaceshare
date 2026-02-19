// lib/models/tappay_cardholder.dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class TapPayCardholder {
  final String? email;
  final String? phoneNumber; // E.164, max 16
  final String? phoneNumberCountryCode; // String(3), default '886'
  final String? nameEn; // String(45)
  final String? name; // local name (optional)

  TapPayCardholder({
    this.email,
    this.phoneNumber,
    this.phoneNumberCountryCode,
    this.nameEn,
    this.name,
  });

  TapPayCardholder copyWith({
    String? email,
    String? phoneNumber,
    String? phoneNumberCountryCode,
    String? nameEn,
    String? name,
  }) {
    return TapPayCardholder(
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberCountryCode: phoneNumberCountryCode ?? this.phoneNumberCountryCode,
      nameEn: nameEn ?? this.nameEn,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone_number': phoneNumber,
      'phone_number_country_code': phoneNumberCountryCode,
      'name_en': nameEn,
      'name': name,
    }..removeWhere((_, v) => v == null);
  }

  factory TapPayCardholder.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return TapPayCardholder();
    return TapPayCardholder(
      email: map['email'] as String?,
      phoneNumber: map['phone_number'] as String?,
      phoneNumberCountryCode: map['phone_number_country_code'] as String?,
      nameEn: map['name_en'] as String?,
      name: map['name'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TapPayCardholder.fromJson(String source) =>
      TapPayCardholder.fromMap(json.decode(source) as Map<dynamic, dynamic>);

  @override
  String toString() {
    return 'TapPayCardholder(email: $email, phoneNumber: $phoneNumber, phoneNumberCountryCode: $phoneNumberCountryCode, nameEn: $nameEn, name: $name)';
  }
}
