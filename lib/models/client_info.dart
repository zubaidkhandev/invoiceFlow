class ClientInfo {
  final String name;
  final String email;
  final String address;

  const ClientInfo({
    required this.name,
    this.email = '',
    this.address = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'address': address,
      };

  factory ClientInfo.fromJson(Map<String, dynamic> json) => ClientInfo(
        name: json['name'] as String,
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}
