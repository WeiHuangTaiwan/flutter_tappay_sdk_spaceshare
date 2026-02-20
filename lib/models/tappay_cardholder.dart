// lib/models/tappay_cardholder.dart
/// Model that maps to the TapPay Web cardholder object.
/// The fields are optional because TapPay accepts different subsets.
/// Adjust fields depending on what you collect in UI.
class TappayCardholder {
  final String? name;
  final String? email;
  final String? phone;
  final String? zipCode;
  final String? address;
  final String? nationalId;

  TappayCardholder({
    this.name,
    this.email,
    this.phone,
    this.zipCode,
    this.address,
    this.nationalId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (zipCode != null) map['zipCode'] = zipCode;
    if (address != null) map['address'] = address;
    if (nationalId != null) map['nationalId'] = nationalId;
    return map;
  }

  factory TappayCardholder.fromJson(Map<String, dynamic> json) {
    return TappayCardholder(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      zipCode: json['zipCode'] as String?,
      address: json['address'] as String?,
      nationalId: json['nationalId'] as String?,
    );
  }
}
