class Actividad {
  final String pregunta;
  final List<String> opciones;
  final String respuestaCorrecta;
  final String explicacion;

  const Actividad({
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.explicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'pregunta': pregunta,
      'opciones': opciones,
      'respuestaCorrecta': respuestaCorrecta,
      'explicacion': explicacion,
    };
  }

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      pregunta: json['pregunta'] as String,
      opciones: List<String>.from(json['opciones'] as List<dynamic>),
      respuestaCorrecta: json['respuestaCorrecta'] as String,
      explicacion: json['explicacion'] as String,
    );
  }
}
