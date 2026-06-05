import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecturakids/models/cuento.dart';
import 'package:lecturakids/services/data_service.dart';
import 'package:lecturakids/services/open_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('filtra cuentos por nivel y edad', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    final faciles = service.obtenerCuentosFiltrados(nivel: 'Fácil');
    final edad3a5 = service.obtenerCuentosFiltrados(grupoEdad: '3-5');

    expect(faciles.length, greaterThanOrEqualTo(4));
    expect(edad3a5.length, greaterThanOrEqualTo(2));
  });

  test('coleccion ampliada tiene cuestionarios especificos variados', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    expect(service.cuentos.length, greaterThanOrEqualTo(24));
    expect(
      service.cuentos.map((cuento) => cuento.imagenPath).toSet().length,
      service.cuentos.length,
    );

    for (final cuento in service.cuentos) {
      final actividades = service.obtenerActividadesDeCuento(
        cuento.id,
        titulo: cuento.titulo,
      );
      expect(actividades, hasLength(4));
      expect(
        actividades.every((actividad) => actividad.opciones.length == 4),
        isTrue,
        reason: cuento.id,
      );
      expect(
        actividades.first.pregunta.contains('personaje principal'),
        isFalse,
        reason: 'No debe caer en quiz generico para ${cuento.id}',
      );
    }
  });

  test('guarda y restaura progreso local', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    service.alternarModoOscuro(true);
    service.actualizarTiempoMaximoDiario(60);
    await service.marcarCuentoCompletado(
      cuentoId: 'caperucita-roja',
      estrellasGanadas: 3,
    );
    await service.guardarProgreso();

    final restored = DataService(cargarBibliotecaExterna: false);
    await restored.init();

    expect(restored.modoOscuro, isTrue);
    expect(restored.tiempoMaximoDiario, 60);
    expect(
      restored.cuentos
          .where((cuento) => cuento.id == 'caperucita-roja')
          .first
          .completado,
      isTrue,
    );
  });

  test('no duplica estrellas al releer cuento completado', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    await service.marcarCuentoCompletado(
      cuentoId: 'patito-feo',
      estrellasGanadas: 2,
    );
    final primerasEstrellas = service.usuarioActivo.estrellasTotal;

    await service.marcarCuentoCompletado(
      cuentoId: 'patito-feo',
      estrellasGanadas: 2,
    );

    expect(service.usuarioActivo.estrellasTotal, primerasEstrellas);
  });

  test('actualiza estrellas al mejorar resultado de cuento', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    await service.marcarCuentoCompletado(
      cuentoId: 'gato-botas',
      estrellasGanadas: 1,
    );
    final conUna = service.usuarioActivo.estrellasTotal;

    await service.marcarCuentoCompletado(
      cuentoId: 'gato-botas',
      estrellasGanadas: 4,
    );

    expect(service.usuarioActivo.estrellasTotal, conUna + 3);
  });

  test('favoritos se alternan y persisten', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    expect(service.esFavorito('leon-raton'), isFalse);
    service.alternarFavorito('leon-raton');
    expect(service.esFavorito('leon-raton'), isTrue);

    final restored = DataService(cargarBibliotecaExterna: false);
    await restored.init();
    expect(restored.esFavorito('leon-raton'), isTrue);

    restored.alternarFavorito('leon-raton');
    expect(restored.esFavorito('leon-raton'), isFalse);
  });

  test('actualiza PIN de padres y restaura valor', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    expect(service.verificarPinPadres('1234'), isTrue);
    service.actualizarPinPadres('2468');
    expect(service.verificarPinPadres('2468'), isTrue);
    expect(service.verificarPinPadres('1234'), isFalse);

    final restored = DataService(cargarBibliotecaExterna: false);
    await restored.init();
    expect(restored.verificarPinPadres('2468'), isTrue);
  });

  test('registro local crea cuenta, persiste y permite login', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    final registerError = service.registrarTutor(
      nombre: 'María',
      email: 'maria@example.com',
      password: 'secreto1',
      confirmPassword: 'secreto1',
    );

    expect(registerError, isNull);
    expect(service.cuentaTutor?.email, 'maria@example.com');
    expect(service.sesionTutorActiva, isTrue);

    service.cerrarSesionTutor();
    expect(service.sesionTutorActiva, isFalse);
    expect(
      service.iniciarSesionTutor(
        email: 'maria@example.com',
        password: 'mala',
      ),
      'Correo o contraseña incorrectos.',
    );
    expect(
      service.iniciarSesionTutor(
        email: 'maria@example.com',
        password: 'secreto1',
      ),
      isNull,
    );

    final restored = DataService(cargarBibliotecaExterna: false);
    await restored.init();
    expect(restored.cuentaTutor?.nombre, 'María');
  });

  test('resuelve titulo de cuento para panel de padres', () async {
    final service = DataService(cargarBibliotecaExterna: false);
    await service.init();

    expect(service.obtenerTituloCuento('leon-raton'), 'El León y el Ratón');
    expect(service.obtenerTituloCuento('desconocido'), 'desconocido');
  });

  test('sincroniza libros externos en espanol y genera quiz ligado al libro',
      () async {
    final service = DataService(
      openLibraryService: _FakeOpenLibraryService(),
      cargarBibliotecaExterna: false,
    );
    await service.init();

    await service.sincronizarBibliotecaExterna(force: true);

    final cuento = service.cuentos.firstWhere(
      (item) => item.id == 'ol-test-book',
    );
    expect(cuento.titulo, 'La luna de papel');

    final actividades = service.obtenerActividadesDeCuento(cuento.id);
    expect(actividades, hasLength(4));
    expect(actividades[0].pregunta, contains('La luna de papel'));
    expect(actividades[0].respuestaCorrecta, 'Ana Torres');
    expect(actividades[1].respuestaCorrecta, 'Curiosidad y comprensión');
    expect(actividades[2].pregunta, contains('La luna de papel'));
    expect(
      actividades.map((item) => item.pregunta).join(' '),
      isNot(contains('¿Qué título exploraste?')),
    );
  });
}

class _FakeOpenLibraryService extends OpenLibraryService {
  @override
  Future<List<Cuento>> obtenerLibrosInfantiles({int limit = 12}) async {
    return const [
      Cuento(
        id: 'ol-test-book',
        titulo: 'La luna de papel',
        nivel: 'Fácil',
        edadMin: 3,
        edadMax: 6,
        paginas: [
          'La luna de papel brillaba sobre el jardín y acompañaba a una niña curiosa.',
          'La niña observó la portada, habló de sus personajes y recordó la enseñanza.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: Open Library · Autor: Ana Torres · Año: 1984 · Tema: Curiosidad y comprensión',
        imagenPath: 'https://covers.openlibrary.org/b/id/1-M.jpg',
      ),
    ];
  }
}
