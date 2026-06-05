class CuentaTutor {
  final String nombre;
  final String email;
  final String password;

  const CuentaTutor({
    required this.nombre,
    required this.email,
    required this.password,
  });

  CuentaTutor copyWith({
    String? nombre,
    String? email,
    String? password,
  }) {
    return CuentaTutor(
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'password': password,
    };
  }

  factory CuentaTutor.fromJson(Map<String, dynamic> json) {
    return CuentaTutor(
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}
