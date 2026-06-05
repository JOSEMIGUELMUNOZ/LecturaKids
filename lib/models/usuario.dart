class Usuario {
  final String id;
  final String nombre;
  final int edad;
  final String avatar;
  final int estrellasTotal;
  final int cuentosLeidos;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.avatar,
    required this.estrellasTotal,
    required this.cuentosLeidos,
  });

  Usuario copyWith({
    String? id,
    String? nombre,
    int? edad,
    String? avatar,
    int? estrellasTotal,
    int? cuentosLeidos,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      avatar: avatar ?? this.avatar,
      estrellasTotal: estrellasTotal ?? this.estrellasTotal,
      cuentosLeidos: cuentosLeidos ?? this.cuentosLeidos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'edad': edad,
      'avatar': avatar,
      'estrellasTotal': estrellasTotal,
      'cuentosLeidos': cuentosLeidos,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      edad: json['edad'] as int,
      avatar: json['avatar'] as String,
      estrellasTotal: json['estrellasTotal'] as int? ?? 0,
      cuentosLeidos: json['cuentosLeidos'] as int? ?? 0,
    );
  }
}
