class SenderInfo {
  final String businessName;
  final String email;
  final String address;
  final String phone;
  final String registrationNumber;
  final String? logoData; // Base64 encoded image string

  const SenderInfo({
    this.businessName = '',
    this.email = '',
    this.address = '',
    this.phone = '',
    this.registrationNumber = '',
    this.logoData,
  });

  SenderInfo copyWith({
    String? businessName,
    String? email,
    String? address,
    String? phone,
    String? registrationNumber,
    String? logoData,
  }) {
    return SenderInfo(
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      logoData: logoData ?? this.logoData,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'email': email,
        'address': address,
        'phone': phone,
        'registrationNumber': registrationNumber,
        'logoData': logoData,
      };

  factory SenderInfo.fromJson(Map<String, dynamic> json) => SenderInfo(
        businessName: json['businessName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        registrationNumber: json['registrationNumber'] as String? ?? '',
        logoData: json['logoData'] as String?,
      );

  bool get isEmpty =>
      businessName.isEmpty &&
      email.isEmpty &&
      address.isEmpty &&
      phone.isEmpty &&
      registrationNumber.isEmpty &&
      logoData == null;
}
