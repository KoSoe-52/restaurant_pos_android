class WaiterUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String locale;
  final String role;

  const WaiterUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.locale,
    required this.role,
  });

  factory WaiterUser.fromJson(Map<String, dynamic> json) => WaiterUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        locale: json['locale'] ?? 'mm',
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'locale': locale,
        'role': role,
      };
}

class LoginResponse {
  final String token;
  final WaiterUser user;

  const LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      token: data['token'],
      user: WaiterUser.fromJson(data['user']),
    );
  }
}
