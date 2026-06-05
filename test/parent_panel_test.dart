import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/screens/parent_panel_screen.dart';
import 'package:lecturakids/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('desbloquea panel de padres con PIN correcto', (tester) async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: service,
        child: const MaterialApp(home: ParentPanelScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Estadísticas'), findsOneWidget);
  });
}
