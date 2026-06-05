class Cuento {
  final String id;
  final String titulo;
  final String nivel;
  final int edadMin;
  final int edadMax;
  final List<String> paginas;
  final bool completado;
  final int estrellasGanadas;
  final String descripcion;
  final String imagenPath;

  const Cuento({
    required this.id,
    required this.titulo,
    required this.nivel,
    required this.edadMin,
    required this.edadMax,
    required this.paginas,
    required this.completado,
    required this.estrellasGanadas,
    required this.descripcion,
    required this.imagenPath,
  });

  Cuento copyWith({
    String? id,
    String? titulo,
    String? nivel,
    int? edadMin,
    int? edadMax,
    List<String>? paginas,
    bool? completado,
    int? estrellasGanadas,
    String? descripcion,
    String? imagenPath,
  }) {
    return Cuento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      nivel: nivel ?? this.nivel,
      edadMin: edadMin ?? this.edadMin,
      edadMax: edadMax ?? this.edadMax,
      paginas: paginas ?? this.paginas,
      completado: completado ?? this.completado,
      estrellasGanadas: estrellasGanadas ?? this.estrellasGanadas,
      descripcion: descripcion ?? this.descripcion,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'nivel': nivel,
      'edadMin': edadMin,
      'edadMax': edadMax,
      'paginas': paginas,
      'completado': completado,
      'estrellasGanadas': estrellasGanadas,
      'descripcion': descripcion,
      'imagenPath': imagenPath,
    };
  }

  factory Cuento.fromJson(Map<String, dynamic> json) {
    return Cuento(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      nivel: json['nivel'] as String,
      edadMin: json['edadMin'] as int,
      edadMax: json['edadMax'] as int,
      paginas: List<String>.from(json['paginas'] as List<dynamic>),
      completado: json['completado'] as bool? ?? false,
      estrellasGanadas: json['estrellasGanadas'] as int? ?? 0,
      descripcion: json['descripcion'] as String,
      imagenPath: json['imagenPath'] as String? ?? '',
    );
  }
}
