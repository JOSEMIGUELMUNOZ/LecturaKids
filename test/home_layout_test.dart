import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/screens/home_screen.dart';
import 'package:lecturakids/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('inicio no desborda en pantalla baja', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: service,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Sigue leyendo'), findsOneWidget);
  });
}
