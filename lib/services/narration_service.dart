import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef NarrationProgressHandler = void Function(
  int startOffset,
  int endOffset,
  String word,
);

abstract class NarrationService {
  void setProgressHandler(NarrationProgressHandler? handler);
  void setCompletionHandler(VoidCallback? handler);
  void setCancelHandler(VoidCallback? handler);
  void setErrorHandler(ValueChanged<String>? handler);
  Future<void> configure();
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
}

class FlutterNarrationService implements NarrationService {
  final FlutterTts _tts;
  bool _configured = false;

  FlutterNarrationService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  void setProgressHandler(NarrationProgressHandler? handler) {
    _tts.setProgressHandler((text, start, end, word) {
      handler?.call(start, end, word);
    });
  }

  @override
  void setCompletionHandler(VoidCallback? handler) {
    _tts.setCompletionHandler(() => handler?.call());
  }

  @override
  void setCancelHandler(VoidCallback? handler) {
    _tts.setCancelHandler(() => handler?.call());
  }

  @override
  void setErrorHandler(ValueChanged<String>? handler) {
    _tts.setErrorHandler((message) => handler?.call(message));
  }

  @override
  Future<void> configure() async {
    if (_configured) return;
    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.04);
    await _tts.setVolume(1);
    await _tts.awaitSpeakCompletion(false);
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    await configure();
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }
}
