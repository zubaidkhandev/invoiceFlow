import 'package:uuid/uuid.dart';

class Client {
  final String id;
  final String name;
  final String email;
  final String address;

  const Client({
    required this.id,
    required this.name,
    this.email = '',
    this.address = '',
  });

  factory Client.newClient({
    required String name,
    String email = '',
    String address = '',
  }) {
    return Client(
      id: const Uuid().v4(),
      name: name,
      email: email,
      address: address,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}
