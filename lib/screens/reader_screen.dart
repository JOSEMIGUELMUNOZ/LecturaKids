import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/cuento.dart';
import '../services/narration_service.dart';
import '../widgets/app_chrome.dart';

class ReaderScreen extends StatefulWidget {
  final Cuento cuento;
  final NarrationService? narrationService;

  const ReaderScreen({
    super.key,
    required this.cuento,
    this.narrationService,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pageController;
  late final NarrationService _narrationService;
  late final List<String> _paginas;
  int _paginaActual = 0;
  bool _narrando = false;
  int _indicePalabra = 0;
  Timer? _fallbackTimer;
  String? _narrationError;
  bool _yaFinalizado = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _paginas = widget.cuento.paginas;
    _narrationService = widget.narrationService ?? FlutterNarrationService();
    _narrationService
      ..setProgressHandler(_handleProgress)
      ..setCompletionHandler(_handleNarrationDone)
      ..setCancelHandler(_handleNarrationDone)
      ..setErrorHandler(_handleNarrationError);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _narrationService.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _iniciarNarracion() async {
    _fallbackTimer?.cancel();
    setState(() {
      _narrando = true;
      _indicePalabra = 0;
      _narrationError = null;
    });
    _startFallbackHighlight();
    try {
      await _narrationService.speak(_paginas[_paginaActual]);
    } catch (_) {
      _handleNarrationError(
        defaultTargetPlatform == TargetPlatform.linux
            ? 'La voz del dispositivo no está disponible en Linux.'
            : 'No se pudo iniciar la narración del dispositivo.',
      );
    }
  }

  Future<void> _detenerNarracion() async {
    _fallbackTimer?.cancel();
    await _narrationService.stop();
    if (!mounted) return;
    setState(() {
      _narrando = false;
    });
  }

  void _handleProgress(int startOffset, int endOffset, String word) {
    if (!mounted) return;
    final currentText = _paginas[_paginaActual];
    final prefix =
        currentText.substring(0, startOffset.clamp(0, currentText.length));
    final nextIndex =
        prefix.trim().isEmpty ? 0 : prefix.trim().split(RegExp(r'\s+')).length;
    setState(() {
      _indicePalabra = nextIndex + 1;
    });
  }

  void _handleNarrationDone() {
    _fallbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _narrando = false;
    });
  }

  void _handleNarrationError(String message) {
    _fallbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _narrando = false;
      _narrationError = message;
    });
  }

  void _startFallbackHighlight() {
    final totalPalabras = _palabrasActuales().length;
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 520), (timer) {
      if (!mounted || !_narrando) {
        timer.cancel();
        return;
      }
      if (_indicePalabra >= totalPalabras) {
        timer.cancel();
        return;
      }
      setState(() {
        _indicePalabra += 1;
      });
    });
  }

  List<String> _palabrasActuales() {
    return _paginas[_paginaActual].split(RegExp(r'\s+'));
  }

  Future<void> _finalizarLectura() async {
    if (_yaFinalizado) return;
    _yaFinalizado = true;
    await _detenerNarracion();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.activities,
      arguments: widget.cuento,
    );
  }

  void _irAAnterior() {
    if (_paginaActual == 0) return;
    _detenerNarracion();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _irASiguiente() {
    if (_paginaActual == _paginas.length - 1) {
      _finalizarLectura();
      return;
    }
    _detenerNarracion();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_paginaActual + 1) / _paginas.length;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          widget.cuento.titulo,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Texto',
                        onPressed: () {},
                        icon: const Text('Aa'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('${_paginaActual + 1} / ${_paginas.length}'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _paginas.length,
                    onPageChanged: (index) {
                      setState(() {
                        _paginaActual = index;
                        _indicePalabra = 0;
                      });
                    },
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: StoryCoverImage(
                                path: widget.cuento.imagenPath,
                                width: double.infinity,
                                height: 206,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _ReaderText(
                              text: _paginas[index],
                              highlightedWords:
                                  _narrando && index == _paginaActual
                                      ? _indicePalabra
                                      : 0,
                            ),
                            if (_narrationError != null) ...[
                              const SizedBox(height: 16),
                              _ErrorNotice(message: _narrationError!),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundControl(
                            icon: Icons.chevron_left_rounded,
                            label: 'Anterior',
                            onTap: _paginaActual == 0 ? null : _irAAnterior,
                          ),
                          SizedBox(
                            width: 74,
                            height: 74,
                            child: FloatingActionButton(
                              heroTag: 'reader-play-${widget.cuento.id}',
                              onPressed: _narrando
                                  ? _detenerNarracion
                                  : _iniciarNarracion,
                              child: Icon(
                                _narrando
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 42,
                              ),
                            ),
                          ),
                          _RoundControl(
                            icon: Icons.chevron_right_rounded,
                            label: _paginaActual == _paginas.length - 1
                                ? 'Terminar'
                                : 'Siguiente',
                            onTap: _irASiguiente,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _ReaderMode(
                                icon: Icons.volume_up_rounded,
                                label: 'Narración'),
                            _ReaderMode(
                                icon: Icons.touch_app_rounded,
                                label: 'Palabra'),
                            _ReaderMode(
                                icon: Icons.image_rounded,
                                label: 'Ilustraciones'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderText extends StatelessWidget {
  final String text;
  final int highlightedWords;

  const _ReaderText({
    required this.text,
    required this.highlightedWords,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: List.generate(words.length, (index) {
        final highlighted = index < highlightedWords;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFFFD85A).withValues(alpha: 0.82)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            words[index],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.35,
                  fontWeight: highlighted ? FontWeight.w900 : FontWeight.w500,
                ),
          ),
        );
      }),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(icon),
            ),
            const SizedBox(height: 5),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ReaderMode extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReaderMode({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
