import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/models/cuento.dart';
import 'package:lecturakids/screens/reader_screen.dart';
import 'package:lecturakids/services/data_service.dart';
import 'package:lecturakids/services/narration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('boton narracion llama servicio TTS y cambia a stop',
      (tester) async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();
    final narration = _FakeNarrationService();
    const cuento = Cuento(
      id: 'demo',
      titulo: 'La estrella curiosa',
      nivel: 'Fácil',
      edadMin: 3,
      edadMax: 5,
      paginas: ['Había una vez una estrella curiosa.'],
      completado: false,
      estrellasGanadas: 0,
      descripcion: 'Demo',
      imagenPath: 'assets/images/cover_leon_raton.png',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: service,
        child: MaterialApp(
          home: ReaderScreen(
            cuento: cuento,
            narrationService: narration,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(narration.spokenText, cuento.paginas.first);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });
}

class _FakeNarrationService implements NarrationService {
  String? spokenText;
  NarrationProgressHandler? progressHandler;
  VoidCallback? completionHandler;
  VoidCallback? cancelHandler;
  ValueChanged<String>? errorHandler;

  @override
  Future<void> configure() async {}

  @override
  Future<void> pause() async {}

  @override
  void setCancelHandler(VoidCallback? handler) {
    cancelHandler = handler;
  }

  @override
  void setCompletionHandler(VoidCallback? handler) {
    completionHandler = handler;
  }

  @override
  void setErrorHandler(ValueChanged<String>? handler) {
    errorHandler = handler;
  }

  @override
  void setProgressHandler(NarrationProgressHandler? handler) {
    progressHandler = handler;
  }

  @override
  Future<void> speak(String text) async {
    spokenText = text;
    progressHandler?.call(0, 5, 'Había');
  }

  @override
  Future<void> stop() async {}
}
