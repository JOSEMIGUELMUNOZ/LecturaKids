class Logro {
  final String nombre;
  final String descripcion;
  final String imagenPath;
  final bool desbloqueado;

  const Logro({
    required this.nombre,
    required this.descripcion,
    required this.imagenPath,
    required this.desbloqueado,
  });

  Logro copyWith({
    String? nombre,
    String? descripcion,
    String? imagenPath,
    bool? desbloqueado,
  }) {
    return Logro(
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenPath: imagenPath ?? this.imagenPath,
      desbloqueado: desbloqueado ?? this.desbloqueado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagenPath': imagenPath,
      'desbloqueado': desbloqueado,
    };
  }

  factory Logro.fromJson(Map<String, dynamic> json) {
    return Logro(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      imagenPath: json['imagenPath'] as String,
      desbloqueado: json['desbloqueado'] as bool? ?? false,
    );
  }
}
