import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login muestra registro, padre y niño', (tester) async {
    await tester.pumpWidget(const LecturaKidsBootstrap());
    await tester.pumpAndSettle();

    expect(find.text('Registrarme'), findsOneWidget);
    expect(find.text('Soy padre, madre o tutor'), findsOneWidget);
    expect(find.text('Soy niño o niña'), findsOneWidget);
  });

  testWidgets('registro local entra a seleccion de perfil', (tester) async {
    await tester.pumpWidget(const LecturaKidsBootstrap());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del tutor'),
      'María',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'maria@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña'),
      'secreto1',
    );
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu perfil'), findsOneWidget);
  });

  testWidgets('entrada niño abre seleccion de perfil', (tester) async {
    await tester.pumpWidget(const LecturaKidsBootstrap());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Soy niño o niña'));
    await tester.tap(find.text('Soy niño o niña'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu perfil'), findsOneWidget);
  });
}
