// lib/models/tappay_cardholder.dart
/// Cardholder data that can be forwarded with TapPay prime requests.
///
/// The web SDK collects sensitive cardholder fields through TapPay-hosted
/// fields. This model is mainly for native direct-card flows and for passing
/// non-sensitive backend cardholder metadata alongside a generated prime.
class TapPayCardholder {
  final String? name;
  final String? nameEn;
  final String? email;
  final String? phoneNumber;
  final String? phoneNumberCountryCode;
  final String? zipCode;
  final String? address;
  final String? nationalId;

  TapPayCardholder({
    this.name,
    this.nameEn,
    this.email,
    this.phoneNumber,
    this.phoneNumberCountryCode,
    this.zipCode,
    this.address,
    this.nationalId,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};
    if (name != null) map['name'] = name;
    if (nameEn != null) map['name_en'] = nameEn;
    if (email != null) map['email'] = email;
    if (phoneNumber != null) map['phone_number'] = phoneNumber;
    if (phoneNumberCountryCode != null) {
      map['phone_number_country_code'] = phoneNumberCountryCode;
    }
    if (zipCode != null) map['zip_code'] = zipCode;
    if (address != null) map['address'] = address;
    if (nationalId != null) map['national_id'] = nationalId;
    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  factory TapPayCardholder.fromMap(Map<String, dynamic> json) {
    return TapPayCardholder(
      name: json['name'] as String?,
      nameEn: json['name_en'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phone'] as String?,
      phoneNumberCountryCode: json['phone_number_country_code'] as String?,
      zipCode: json['zip_code'] as String? ?? json['zipCode'] as String?,
      address: json['address'] as String?,
      nationalId:
          json['national_id'] as String? ?? json['nationalId'] as String?,
    );
  }
}

/// Backward-compatible alias for the pre-0.3.1 class name.
@Deprecated('Use TapPayCardholder instead.')
typedef TappayCardholder = TapPayCardholder;
