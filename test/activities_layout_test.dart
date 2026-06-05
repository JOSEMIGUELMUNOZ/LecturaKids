import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/screens/activities_screen.dart';
import 'package:lecturakids/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('actividades no desborda en pantalla chica', (tester) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();
    final cuento = service.cuentos.firstWhere(
      (item) => item.id == 'hansel-gretel',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: service,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ActivitiesScreen(cuento: cuento),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Actividades'), findsOneWidget);
  });
}
