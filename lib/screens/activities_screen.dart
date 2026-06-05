import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/actividad.dart';
import '../models/cuento.dart';
import '../services/data_service.dart';
import '../widgets/star_widget.dart';

class ActivitiesScreen extends StatefulWidget {
  final Cuento cuento;

  const ActivitiesScreen({super.key, required this.cuento});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late final List<Actividad> _actividades;
  late final AnimationController _controller;
  int _indiceActual = 0;
  String? _respuestaSeleccionada;
  bool? _correcta;
  int _estrellas = 0;
  bool _mostrandoResultado = false;
  bool _resultadoGuardado = false;
  final List<bool?> _resultados = [];
  final List<String?> _selecciones = [];

  @override
  void initState() {
    super.initState();
    _actividades = context.read<DataService>().obtenerActividadesDeCuento(
          widget.cuento.id,
          titulo: widget.cuento.titulo,
        );
    _resultados.addAll(List<bool?>.filled(_actividades.length, null));
    _selecciones.addAll(List<String?>.filled(_actividades.length, null));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _evaluarRespuesta(String option) {
    if (_resultados[_indiceActual] != null) return;
    final correcta = option == _actividades[_indiceActual].respuestaCorrecta;
    setState(() {
      _respuestaSeleccionada = option;
      _correcta = correcta;
      _resultados[_indiceActual] = correcta;
      _selecciones[_indiceActual] = option;
      if (correcta) {
        _estrellas += 1;
      }
    });
    context.read<DataService>().registrarRespuesta(
          correcta: correcta,
          cuentoId: widget.cuento.id,
        );
  }

  void _siguientePregunta() {
    if (_indiceActual < _actividades.length - 1) {
      setState(() {
        _indiceActual += 1;
        _respuestaSeleccionada = null;
        _correcta = null;
      });
    } else {
      _mostrarResultadoFinal();
    }
  }

  Future<void> _mostrarResultadoFinal() async {
    final totalCorrectas = _resultados.where((item) => item == true).length;
    setState(() {
      _mostrandoResultado = true;
      _estrellas = totalCorrectas;
    });
    if (_resultadoGuardado) return;
    _resultadoGuardado = true;
    await context.read<DataService>().marcarCuentoCompletado(
          cuentoId: widget.cuento.id,
          estrellasGanadas: totalCorrectas,
        );
  }

  void _reiniciarQuiz() {
    setState(() {
      _indiceActual = 0;
      _respuestaSeleccionada = null;
      _correcta = null;
      _estrellas = 0;
      _mostrandoResultado = false;
      _resultadoGuardado = false;
      for (var index = 0; index < _resultados.length; index += 1) {
        _resultados[index] = null;
        _selecciones[index] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actividad = _actividades[_indiceActual];
    final totalCorrectas = _resultados.where((item) => item == true).length;
    final porcentaje = (_resultados.where((item) => item != null).isEmpty)
        ? 0.0
        : ((totalCorrectas / _actividades.length) * 100).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        actions: [
          IconButton(
            tooltip: 'Biblioteca',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.library,
              (route) => false,
            ),
            icon: const Icon(Icons.local_library_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _mostrandoResultado
                      ? _ResultadoFinal(
                          estrellas: _estrellas,
                          correctas: totalCorrectas,
                          total: _actividades.length,
                          porcentaje: porcentaje,
                          actividades: _actividades,
                          resultados: _resultados,
                          selecciones: _selecciones,
                          onReintentar: _reiniciarQuiz,
                          onVolver: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.library,
                            (route) => false,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cuento.titulo,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pregunta ${_indiceActual + 1} de ${_actividades.length}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: (_indiceActual +
                                        (_resultados[_indiceActual] == null
                                            ? 0
                                            : 1)) /
                                    _actividades.length,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Text(
                                  actividad.pregunta,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ...actividad.opciones.map((opcion) {
                                final already =
                                    _resultados[_indiceActual] != null;
                                final isCorrect =
                                    opcion == actividad.respuestaCorrecta;
                                final selected =
                                    _respuestaSeleccionada == opcion;
                                Color? bgColor;
                                if (already && isCorrect) {
                                  bgColor =
                                      Colors.green.withValues(alpha: 0.18);
                                } else if (selected && !isCorrect) {
                                  bgColor = Colors.red.withValues(alpha: 0.18);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        backgroundColor: bgColor,
                                        side: BorderSide(
                                          color: already && isCorrect
                                              ? Colors.green
                                              : selected && !isCorrect
                                                  ? Colors.red
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      onPressed: already
                                          ? null
                                          : () => _evaluarRespuesta(opcion),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(opcion)),
                                          if (already && isCorrect)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.green,
                                            )
                                          else if (selected && !isCorrect)
                                            const Icon(
                                              Icons.close_rounded,
                                              color: Colors.red,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (_correcta != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: (_correcta == true
                                            ? Colors.green
                                            : Colors.red)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    actividad.explicacion,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _siguientePregunta,
                                    icon:
                                        const Icon(Icons.navigate_next_rounded),
                                    label: Text(
                                      _indiceActual == _actividades.length - 1
                                          ? 'Ver resultado'
                                          : 'Siguiente',
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: List.generate(
                                  _actividades.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: StarWidget(
                                      active: _resultados[index] == true,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (_mostrandoResultado)
              Positioned.fill(
                child: IgnorePointer(
                  child: _CelebrationOverlay(controller: _controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoFinal extends StatelessWidget {
  final int estrellas;
  final int correctas;
  final int total;
  final double porcentaje;
  final List<Actividad> actividades;
  final List<bool?> resultados;
  final List<String?> selecciones;
  final VoidCallback onReintentar;
  final VoidCallback onVolver;

  const _ResultadoFinal({
    required this.estrellas,
    required this.correctas,
    required this.total,
    required this.porcentaje,
    required this.actividades,
    required this.resultados,
    required this.selecciones,
    required this.onReintentar,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Icon(
          Icons.celebration_rounded,
          color: Theme.of(context).colorScheme.secondary,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          '¡Felicidades!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Has terminado la actividad con $estrellas de $total estrellas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _ResultCard(
          label: 'Respuestas correctas',
          value: '$correctas de $total',
        ),
        const SizedBox(height: 10),
        _ResultCard(
          label: 'Acierto total',
          value: '${porcentaje.toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 18),
        ...List.generate(actividades.length, (index) {
          final actividad = actividades[index];
          final correcta = resultados[index] == true;
          final seleccion = selecciones[index] ?? 'Sin responder';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewCard(
              numero: index + 1,
              pregunta: actividad.pregunta,
              seleccion: seleccion,
              respuestaCorrecta: actividad.respuestaCorrecta,
              correcta: correcta,
            ),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Intentar otra vez'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onVolver,
            icon: const Icon(Icons.library_books_rounded),
            label: const Text('Volver a la biblioteca'),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int numero;
  final String pregunta;
  final String seleccion;
  final String respuestaCorrecta;
  final bool correcta;

  const _ReviewCard({
    required this.numero,
    required this.pregunta,
    required this.seleccion,
    required this.respuestaCorrecta,
    required this.correcta,
  });

  @override
  Widget build(BuildContext context) {
    final color = correcta ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correcta ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pregunta $numero',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pregunta, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Tu respuesta: $seleccion'),
          if (!correcta) Text('Correcta: $respuestaCorrecta'),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;

  const _ResultCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  final AnimationController controller;

  const _CelebrationOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final stars = List.generate(12, (index) => index);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: stars.map((index) {
            final baseX = (index * 61) % 360 / 360.0;
            final y = ((controller.value + index * 0.13) % 1.0) *
                MediaQuery.of(context).size.height;
            return Positioned(
              left: MediaQuery.of(context).size.width * baseX,
              top: y,
              child: Opacity(
                opacity: 0.55,
                child: Icon(
                  Icons.star_rounded,
                  color: index.isEven
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  size: 22 + (index % 3) * 4,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
