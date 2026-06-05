import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/actividad.dart';
import '../models/cuenta_tutor.dart';
import '../models/cuento.dart';
import '../models/logro.dart';
import '../models/usuario.dart';
import 'open_library_service.dart';

class DataService extends ChangeNotifier {
  static const String _prefsKey = 'lecturakids_state_v1';

  final OpenLibraryService _openLibraryService;
  final bool _cargarBibliotecaExterna;

  DataService({
    OpenLibraryService? openLibraryService,
    bool cargarBibliotecaExterna = true,
  })  : _openLibraryService = openLibraryService ?? OpenLibraryService(),
        _cargarBibliotecaExterna = cargarBibliotecaExterna;

  bool _isReady = false;
  bool _modoOscuro = false;
  bool _sincronizandoBiblioteca = false;
  bool _sesionTutorActiva = false;
  CuentaTutor? _cuentaTutor;
  String _pinPadres = '1234';
  int _tiempoMaximoDiario = 45;
  int _totalRespuestas = 0;
  int _respuestasCorrectas = 0;
  String? _bibliotecaError;

  Usuario _usuarioActivo = const Usuario(
    id: 'guest',
    nombre: 'Invitado',
    edad: 6,
    avatar: '🦊',
    estrellasTotal: 0,
    cuentosLeidos: 0,
  );

  List<Usuario> _usuarios = [];

  List<Cuento> _cuentos = [];
  final Map<String, List<Actividad>> _actividades = {};
  final Map<String, DateTime> _fechasCompletado = {};
  final Map<String, int> _estrellasPorCuento = {};
  final Set<String> _favoritos = {};
  final Map<String, double> _tiempoLecturaSemanal = {
    'Lun': 18,
    'Mar': 25,
    'Mié': 14,
    'Jue': 32,
    'Vie': 28,
    'Sáb': 41,
    'Dom': 22,
  };

  final List<Logro> _logrosBase = const [
    Logro(
      nombre: 'Primer cuento',
      descripcion: 'Se desbloquea al leer tu primer cuento.',
      imagenPath: 'assets/images/logro_primer_cuento.png',
      desbloqueado: false,
    ),
    Logro(
      nombre: 'Cinco estrellas',
      descripcion: 'Consigue 5 estrellas en total.',
      imagenPath: 'assets/images/logro_cinco_estrellas.png',
      desbloqueado: false,
    ),
    Logro(
      nombre: 'Explorador',
      descripcion: 'Completa 3 cuentos distintos.',
      imagenPath: 'assets/images/logro_explorador.png',
      desbloqueado: false,
    ),
    Logro(
      nombre: 'Gran lector',
      descripcion: 'Completa toda la colección disponible.',
      imagenPath: 'assets/images/logro_gran_lector.png',
      desbloqueado: false,
    ),
  ];

  bool get isReady => _isReady;
  bool get modoOscuro => _modoOscuro;
  bool get sincronizandoBiblioteca => _sincronizandoBiblioteca;
  bool get sesionTutorActiva => _sesionTutorActiva;
  CuentaTutor? get cuentaTutor => _cuentaTutor;
  String get pinPadres => _pinPadres;
  int get tiempoMaximoDiario => _tiempoMaximoDiario;
  int get totalRespuestas => _totalRespuestas;
  int get respuestasCorrectas => _respuestasCorrectas;
  String? get bibliotecaError => _bibliotecaError;
  Usuario get usuarioActivo => _usuarioActivo;
  List<Usuario> get usuarios => List.unmodifiable(_usuarios);
  List<Cuento> get cuentos => List.unmodifiable(_cuentos);
  Set<String> get favoritos => Set.unmodifiable(_favoritos);
  Map<String, double> get tiempoLecturaSemanal =>
      Map<String, double>.unmodifiable(_tiempoLecturaSemanal);

  Future<void> init() async {
    try {
      _cargarDatosIniciales();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _modoOscuro = decoded['modoOscuro'] as bool? ?? false;
        _sesionTutorActiva = decoded['sesionTutorActiva'] as bool? ?? false;
        _pinPadres = decoded['pinPadres'] as String? ?? '1234';
        _tiempoMaximoDiario = decoded['tiempoMaximoDiario'] as int? ?? 45;
        _totalRespuestas = decoded['totalRespuestas'] as int? ?? 0;
        _respuestasCorrectas = decoded['respuestasCorrectas'] as int? ?? 0;

        final usuarioJson = decoded['usuarioActivo'] as Map<String, dynamic>?;
        if (usuarioJson != null) {
          _usuarioActivo = Usuario.fromJson(usuarioJson);
        }

        final cuentaTutorJson = decoded['cuentaTutor'] as Map<String, dynamic>?;
        if (cuentaTutorJson != null) {
          _cuentaTutor = CuentaTutor.fromJson(cuentaTutorJson);
        }

        final usuariosJson = decoded['usuarios'] as List<dynamic>?;
        if (usuariosJson != null) {
          _usuarios = usuariosJson
              .map((dynamic item) =>
                  Usuario.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          _usuarios = [];
        }

        final cuentosBase = List<Cuento>.from(_cuentos);
        final cuentosJson = decoded['cuentos'] as List<dynamic>?;
        if (cuentosJson != null) {
          final cuentosRestaurados = cuentosJson
              .map(
                (dynamic item) => Cuento.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          final restauradosPorId = {
            for (final cuento in cuentosRestaurados) cuento.id: cuento,
          };
          _cuentos = cuentosBase.map((cuento) {
            final restaurado = restauradosPorId[cuento.id];
            if (restaurado == null) return cuento;
            return cuento.copyWith(
              completado: restaurado.completado,
              estrellasGanadas: restaurado.estrellasGanadas,
            );
          }).toList();
        }

        final completadosJson =
            decoded['fechasCompletado'] as Map<String, dynamic>?;
        if (completadosJson != null) {
          _fechasCompletado
            ..clear()
            ..addEntries(
              completadosJson.entries.map(
                (entry) =>
                    MapEntry(entry.key, DateTime.parse(entry.value as String)),
              ),
            );
        }

        final estrellasJson =
            decoded['estrellasPorCuento'] as Map<String, dynamic>?;
        if (estrellasJson != null) {
          _estrellasPorCuento
            ..clear()
            ..addEntries(
              estrellasJson.entries.map(
                (entry) => MapEntry(entry.key, entry.value as int),
              ),
            );
        }

        final favoritosJson = decoded['favoritos'] as List<dynamic>?;
        if (favoritosJson != null) {
          _favoritos
            ..clear()
            ..addAll(favoritosJson.whereType<String>());
        }
      } else {
        await _guardarProgresoInterno();
      }
    } catch (_) {
      _reiniciarEstadoSeguro();
      await _guardarProgresoInterno();
    }

    _aplicarEstadoCuentos();
    _sincronizarUsuarioActivo();
    _isReady = true;
    notifyListeners();
    if (_cargarBibliotecaExterna) {
      sincronizarBibliotecaExterna();
    }
  }

  void _reiniciarEstadoSeguro() {
    _modoOscuro = false;
    _sincronizandoBiblioteca = false;
    _sesionTutorActiva = false;
    _cuentaTutor = null;
    _pinPadres = '1234';
    _tiempoMaximoDiario = 45;
    _totalRespuestas = 0;
    _respuestasCorrectas = 0;
    _bibliotecaError = null;
    _usuarioActivo = const Usuario(
      id: 'guest',
      nombre: 'Invitado',
      edad: 6,
      avatar: '🦊',
      estrellasTotal: 0,
      cuentosLeidos: 0,
    );
    _usuarios = [];
    _cuentos = [];
    _actividades.clear();
    _fechasCompletado.clear();
    _estrellasPorCuento.clear();
    _favoritos.clear();
  }

  void _cargarDatosIniciales() {
    _cuentos = [
      const Cuento(
        id: 'leon-raton',
        titulo: 'El León y el Ratón',
        nivel: 'Fácil',
        edadMin: 3,
        edadMax: 5,
        paginas: [
          'Un poderoso león dormía bajo el sol cuando un pequeño ratón pasó corriendo por su lomo.',
          'El león despertó y atrapó al ratón, pero el ratoncito pidió ayuda con mucha amabilidad.',
          'Días después, el ratón rompió la red que atrapó al león. El león entendió que todos pueden ayudar.',
        ],
        completado: true,
        estrellasGanadas: 3,
        descripcion: 'Una historia sobre amabilidad y gratitud.',
        imagenPath: 'assets/images/cover_leon_raton.png',
      ),
      const Cuento(
        id: 'tortuga-liebre',
        titulo: 'La Tortuga y la Liebre',
        nivel: 'Fácil',
        edadMin: 4,
        edadMax: 7,
        paginas: [
          'La liebre se burlaba de la tortuga porque corría despacio.',
          'La tortuga siguió caminando con paciencia mientras la liebre se quedó dormida.',
          'Al final, la tortuga ganó la carrera porque nunca se rindió.',
        ],
        completado: true,
        estrellasGanadas: 2,
        descripcion: 'La constancia vale más que la prisa.',
        imagenPath: 'assets/images/cover_tortuga_liebre.png',
      ),
      const Cuento(
        id: 'caperucita-roja',
        titulo: 'Caperucita Roja',
        nivel: 'Medio',
        edadMin: 5,
        edadMax: 8,
        paginas: [
          'Caperucita llevó una cesta de comida a su abuelita por el bosque.',
          'En el camino conoció al lobo, que intentó distraerla con palabras amables.',
          'Gracias a la ayuda del leñador, Caperucita y su abuelita estuvieron a salvo.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Un cuento clásico sobre cuidado y precaución.',
        imagenPath: 'assets/images/cover_caperucita_roja.png',
      ),
      const Cuento(
        id: 'tres-cerditos',
        titulo: 'Los Tres Cerditos',
        nivel: 'Medio',
        edadMin: 5,
        edadMax: 8,
        paginas: [
          'Tres cerditos construyeron sus casas con materiales diferentes.',
          'El lobo sopló con fuerza, pero solo la casa de ladrillos resistió.',
          'La historia enseña que trabajar con paciencia trae mejores resultados.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una lección sobre esfuerzo y buena planificación.',
        imagenPath: 'assets/images/cover_ricitos_osos.png',
      ),
      const Cuento(
        id: 'patito-feo',
        titulo: 'El Patito Feo',
        nivel: 'Avanzado',
        edadMin: 7,
        edadMax: 12,
        paginas: [
          'Un patito diferente fue rechazado por los demás animales.',
          'Después de mucho tiempo, descubrió que en realidad era un hermoso cisne.',
          'Comprendió que ser distinto también puede ser algo valioso y especial.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una historia sobre identidad y aceptación.',
        imagenPath: 'assets/images/cover_patito_feo.png',
      ),
      const Cuento(
        id: 'cigarra-hormiga',
        titulo: 'La Cigarra y la Hormiga',
        nivel: 'Avanzado',
        edadMin: 8,
        edadMax: 12,
        paginas: [
          'La cigarra cantaba todo el verano mientras la hormiga trabajaba sin parar.',
          'Cuando llegó el frío, la hormiga tenía comida y la cigarra aprendió una gran lección.',
          'La historia enseña que prepararse a tiempo ayuda mucho en el futuro.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una fábula sobre responsabilidad y previsión.',
        imagenPath: 'assets/images/cover_gallinita_roja.png',
      ),
      const Cuento(
        id: 'ricitos-tres-osos',
        titulo: 'Ricitos de Oro',
        nivel: 'Fácil',
        edadMin: 4,
        edadMax: 7,
        paginas: [
          'Ricitos encontró una casita en el bosque y entró con mucha curiosidad.',
          'Probó tres platos de sopa, tres sillas y tres camas hasta elegir los más pequeños.',
          'Cuando llegaron los osos, Ricitos entendió que debía respetar las cosas ajenas.',
          'Pidió disculpas y volvió a casa recordando tocar la puerta antes de entrar.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una historia sobre respeto, límites y curiosidad.',
        imagenPath: 'assets/images/cover_tres_cerditos.png',
      ),
      const Cuento(
        id: 'gallina-roja',
        titulo: 'La Gallinita Roja',
        nivel: 'Fácil',
        edadMin: 3,
        edadMax: 6,
        paginas: [
          'La gallinita encontró granos de trigo y pidió ayuda para sembrarlos.',
          'Sus amigos no quisieron ayudar, así que ella trabajó con paciencia cada día.',
          'Cuando el pan estuvo listo, todos querían comerlo.',
          'La gallinita compartió una lección: quien ayuda también disfruta el resultado.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una fábula sobre colaboración y responsabilidad.',
        imagenPath: 'assets/images/cover_cigarra_hormiga.png',
      ),
      const Cuento(
        id: 'pinocho',
        titulo: 'Pinocho',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 9,
        paginas: [
          'Gepeto construyó un muñeco de madera y soñó con verlo crecer como un niño.',
          'Pinocho aprendió que las mentiras traen problemas y alejan a quienes nos cuidan.',
          'Con valentía ayudó a Gepeto cuando más lo necesitaba.',
          'Al elegir la verdad y el cariño, Pinocho encontró su mejor versión.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Un cuento sobre honestidad, familia y decisiones.',
        imagenPath: 'assets/images/cover_pinocho.png',
      ),
      const Cuento(
        id: 'gato-botas',
        titulo: 'El Gato con Botas',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 10,
        paginas: [
          'Un joven recibió como herencia un gato muy astuto y unas botas elegantes.',
          'El gato usó ingenio y buenas palabras para abrir oportunidades a su dueño.',
          'Con planes cuidadosos venció al ogro y protegió a su amigo.',
          'El joven aprendió que la inteligencia puede cambiar un camino difícil.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una aventura sobre ingenio, amistad y estrategia.',
        imagenPath: 'assets/images/cover_gato_botas.png',
      ),
      const Cuento(
        id: 'aladino-lampara',
        titulo: 'Aladino y la Lámpara',
        nivel: 'Medio',
        edadMin: 7,
        edadMax: 10,
        paginas: [
          'Aladino encontró una lámpara antigua en una cueva llena de secretos.',
          'Un genio apareció y ofreció ayuda, pero Aladino tuvo que pensar con cuidado.',
          'El poder de la lámpara no resolvía todo si faltaba honestidad.',
          'Aladino eligió proteger a su familia y usar sus deseos con responsabilidad.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una aventura sobre deseos, prudencia y generosidad.',
        imagenPath: 'assets/images/cover_aladino_lampara.png',
      ),
      const Cuento(
        id: 'flautista-hamelin',
        titulo: 'El Flautista de Hamelin',
        nivel: 'Medio',
        edadMin: 7,
        edadMax: 10,
        paginas: [
          'Un pueblo pidió ayuda a un flautista para resolver un gran problema.',
          'La música del flautista guió a los animales fuera de la ciudad.',
          'Cuando el alcalde rompió su promesa, todos aprendieron una lección seria.',
          'Cumplir lo acordado mantiene la confianza entre las personas.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Una historia sobre promesas y consecuencias.',
        imagenPath: 'assets/images/cover_flautista_hamelin.png',
      ),
      const Cuento(
        id: 'hansel-gretel',
        titulo: 'Hansel y Gretel',
        nivel: 'Avanzado',
        edadMin: 7,
        edadMax: 11,
        paginas: [
          'Hansel y Gretel se perdieron en el bosque y buscaron señales para volver.',
          'Encontraron una casa dulce, pero pronto descubrieron que no todo era seguro.',
          'Con cooperación y calma lograron escapar del peligro.',
          'Los hermanos volvieron a casa más unidos y atentos a los riesgos.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Una aventura sobre valentía, cuidado y trabajo en equipo.',
        imagenPath: 'assets/images/cover_hansel_gretel.png',
      ),
      const Cuento(
        id: 'soldadito-plomo',
        titulo: 'El Soldadito de Plomo',
        nivel: 'Avanzado',
        edadMin: 8,
        edadMax: 12,
        paginas: [
          'Un soldadito de plomo miraba el mundo con una sola pierna y mucho valor.',
          'Cayó por la ventana y viajó por la calle, el agua y un pez enorme.',
          'A pesar de los cambios, mantuvo firme su corazón.',
          'Su historia recuerda que la valentía también puede ser silenciosa.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion: 'Un cuento sensible sobre perseverancia y coraje.',
        imagenPath: 'assets/images/cover_soldadito_plomo.png',
      ),
      const Cuento(
        id: 'princesa-guisante',
        titulo: 'La Princesa y el Guisante',
        nivel: 'Fácil',
        edadMin: 4,
        edadMax: 7,
        paginas: [
          'Una joven llegó al castillo durante una noche de lluvia.',
          'La reina colocó un pequeño guisante bajo muchos colchones.',
          'Al notar la molestia, la joven demostró una sensibilidad especial.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Hans Christian Andersen · Tema: Sensibilidad y observación',
        imagenPath: 'assets/images/cover_princesa_guisante.png',
      ),
      const Cuento(
        id: 'sastrecillo-valiente',
        titulo: 'El Sastrecillo Valiente',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 9,
        paginas: [
          'Un sastrecillo salió al mundo con una frase que lo hacía parecer muy fuerte.',
          'Con inteligencia enfrentó pruebas difíciles sin perder la calma.',
          'La historia muestra que la astucia también puede ser valentía.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Hermanos Grimm · Tema: Ingenio y valentía',
        imagenPath: 'assets/images/cover_sastrecillo_valiente.png',
      ),
      const Cuento(
        id: 'raton-campo-ciudad',
        titulo: 'El Ratón de Campo y el Ratón de Ciudad',
        nivel: 'Fácil',
        edadMin: 4,
        edadMax: 7,
        paginas: [
          'Un ratón de campo visitó a su primo en la ciudad.',
          'La comida era abundante, pero los peligros aparecían a cada momento.',
          'El ratón comprendió que la tranquilidad también tiene mucho valor.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Esopo · Tema: Tranquilidad y decisiones',
        imagenPath: 'assets/images/cover_raton_campo_ciudad.png',
      ),
      const Cuento(
        id: 'zorro-cuervo',
        titulo: 'El Zorro y el Cuervo',
        nivel: 'Fácil',
        edadMin: 5,
        edadMax: 8,
        paginas: [
          'Un cuervo sostenía un queso mientras un zorro lo observaba.',
          'El zorro usó halagos para conseguir que el cuervo cantara.',
          'El cuento enseña a desconfiar de palabras bonitas que buscan engañar.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Esopo · Tema: Prudencia ante halagos',
        imagenPath: 'assets/images/cover_zorro_cuervo.png',
      ),
      const Cuento(
        id: 'bella-bestia',
        titulo: 'La Bella y la Bestia',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 10,
        paginas: [
          'Bella llegó a un castillo donde vivía una bestia solitaria.',
          'Con paciencia descubrió bondad detrás de una apariencia temible.',
          'La historia recuerda mirar con atención antes de juzgar.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Gabrielle-Suzanne Barbot · Tema: Empatía y apariencia',
        imagenPath: 'assets/images/cover_bella_bestia.png',
      ),
      const Cuento(
        id: 'sirenita',
        titulo: 'La Sirenita',
        nivel: 'Avanzado',
        edadMin: 8,
        edadMax: 12,
        paginas: [
          'Una sirenita soñaba con conocer el mundo que veía sobre el mar.',
          'Su deseo la llevó a tomar decisiones difíciles.',
          'La historia habla de anhelos, consecuencias y crecimiento personal.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Hans Christian Andersen · Tema: Deseos y consecuencias',
        imagenPath: 'assets/images/cover_sirenita.png',
      ),
      const Cuento(
        id: 'nabo-gigante',
        titulo: 'El Nabo Gigante',
        nivel: 'Fácil',
        edadMin: 3,
        edadMax: 6,
        paginas: [
          'Un abuelo sembró un nabo que creció más de lo esperado.',
          'Toda la familia ayudó a tirar hasta sacarlo de la tierra.',
          'El cuento muestra que juntos se logran tareas enormes.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Cuento tradicional · Tema: Cooperación',
        imagenPath: 'assets/images/cover_nabos_gigante.png',
      ),
      const Cuento(
        id: 'musicos-bremen',
        titulo: 'Los Músicos de Bremen',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 10,
        paginas: [
          'Cuatro animales decidieron viajar a Bremen para tocar música.',
          'En el camino descubrieron que sus voces juntas podían asustar ladrones.',
          'La amistad les dio un nuevo hogar y una nueva oportunidad.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Hermanos Grimm · Tema: Amistad y colaboración',
        imagenPath: 'assets/images/cover_musicos_bremen.png',
      ),
      const Cuento(
        id: 'pedro-lobo',
        titulo: 'Pedro y el Lobo',
        nivel: 'Medio',
        edadMin: 6,
        edadMax: 9,
        paginas: [
          'Pedro gritó que venía el lobo aunque no era verdad.',
          'Cuando el peligro fue real, nadie creyó sus palabras.',
          'La historia enseña que mentir puede romper la confianza.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Cuento tradicional · Tema: Honestidad y confianza',
        imagenPath: 'assets/images/cover_pedro_lobo.png',
      ),
      const Cuento(
        id: 'cisnes-salvajes',
        titulo: 'Los Cisnes Salvajes',
        nivel: 'Avanzado',
        edadMin: 8,
        edadMax: 12,
        paginas: [
          'Elisa buscó salvar a sus hermanos transformados en cisnes.',
          'Con paciencia tejió camisas de ortigas pese al cansancio.',
          'Su amor y perseverancia rompieron el hechizo.',
        ],
        completado: false,
        estrellasGanadas: 0,
        descripcion:
            'Fuente: colección local · Autor: Hans Christian Andersen · Tema: Perseverancia y familia',
        imagenPath: 'assets/images/cover_cisnes_salvajes.png',
      ),
    ];

    if (_fechasCompletado.isEmpty) {
      final ahora = DateTime.now();
      _fechasCompletado.addAll({
        'leon-raton': ahora.subtract(const Duration(days: 1)),
        'tortuga-liebre': ahora.subtract(const Duration(days: 2)),
      });
    }

    if (_estrellasPorCuento.isEmpty) {
      _estrellasPorCuento.addAll({
        'leon-raton': 3,
        'tortuga-liebre': 2,
      });
    }

    _actividades
      ..clear()
      ..addAll({
        'leon-raton': const [
          Actividad(
            pregunta: '¿Quién ayudó al león cuando quedó atrapado?',
            opciones: ['El ratón', 'La tortuga', 'El lobo', 'La hormiga'],
            respuestaCorrecta: 'El ratón',
            explicacion: 'El ratón rompió la red y liberó al león.',
          ),
          Actividad(
            pregunta: '¿Qué aprendió el león?',
            opciones: [
              'Que solo los grandes ayudan',
              'Que todos pueden ser útiles',
              'Que el bosque da miedo',
              'Que dormir siempre es mejor',
            ],
            respuestaCorrecta: 'Que todos pueden ser útiles',
            explicacion:
                'La historia muestra que incluso los pequeños pueden ayudar.',
          ),
          Actividad(
            pregunta: '¿Cómo trató el ratón al león?',
            opciones: ['Con enojo', 'Con amabilidad', 'Con miedo', 'Con prisa'],
            respuestaCorrecta: 'Con amabilidad',
            explicacion: 'El ratón pidió ayuda con mucho respeto.',
          ),
          Actividad(
            pregunta: '¿Qué significa "gratitud" en esta historia?',
            opciones: [
              'Agradecer una ayuda',
              'Correr rápido',
              'Guardar comida',
              'Dormir al sol',
            ],
            respuestaCorrecta: 'Agradecer una ayuda',
            explicacion: 'El león agradece que el ratón lo haya liberado.',
          ),
        ],
        'tortuga-liebre': const [
          Actividad(
            pregunta: '¿Quién ganó la carrera?',
            opciones: ['La liebre', 'La tortuga', 'Nadie', 'El león'],
            respuestaCorrecta: 'La tortuga',
            explicacion: 'La tortuga ganó porque fue constante.',
          ),
          Actividad(
            pregunta: '¿Qué hizo la liebre?',
            opciones: [
              'Siguió caminando',
              'Se durmió',
              'Construyó una casa',
              'Pidió ayuda',
            ],
            respuestaCorrecta: 'Se durmió',
            explicacion: 'La liebre confió demasiado en su velocidad.',
          ),
          Actividad(
            pregunta: '¿Qué enseña el cuento?',
            opciones: ['La paciencia', 'La magia', 'La oscuridad', 'El ruido'],
            respuestaCorrecta: 'La paciencia',
            explicacion: 'La constancia y la paciencia ayudan a lograr metas.',
          ),
          Actividad(
            pregunta: '¿Por qué perdió la liebre?',
            opciones: [
              'Porque subestimó a la tortuga',
              'Porque no sabía correr',
              'Porque llovió mucho',
              'Porque no hubo meta',
            ],
            respuestaCorrecta: 'Porque subestimó a la tortuga',
            explicacion:
                'La liebre se confió y dejó de esforzarse antes de terminar.',
          ),
        ],
        'caperucita-roja': const [
          Actividad(
            pregunta: '¿A quién iba a visitar Caperucita?',
            opciones: ['A su abuelita', 'A la liebre', 'A un rey', 'A Gepeto'],
            respuestaCorrecta: 'A su abuelita',
            explicacion: 'Llevaba una cesta de comida a su abuelita.',
          ),
          Actividad(
            pregunta: '¿Qué intentó hacer el lobo?',
            opciones: [
              'Distraerla en el camino',
              'Construir una casa',
              'Sembrar trigo',
              'Tocar la flauta',
            ],
            respuestaCorrecta: 'Distraerla en el camino',
            explicacion: 'El lobo quiso apartarla de su objetivo.',
          ),
          Actividad(
            pregunta: '¿Qué valor trabaja este cuento?',
            opciones: ['Precaución', 'Orgullo', 'Pereza', 'Mentira'],
            respuestaCorrecta: 'Precaución',
            explicacion: 'La historia enseña a ser cuidadosos con extraños.',
          ),
          Actividad(
            pregunta: '¿Quién ayudó al final?',
            opciones: ['El leñador', 'El gato', 'La gallinita', 'El genio'],
            respuestaCorrecta: 'El leñador',
            explicacion: 'El leñador ayudó a que todas estuvieran a salvo.',
          ),
        ],
        'tres-cerditos': const [
          Actividad(
            pregunta: '¿Qué casa resistió al lobo?',
            opciones: [
              'La de ladrillos',
              'La de paja',
              'La de madera',
              'La de hojas',
            ],
            respuestaCorrecta: 'La de ladrillos',
            explicacion: 'La casa de ladrillos fue la más fuerte.',
          ),
          Actividad(
            pregunta: '¿Qué hacía el lobo para derribar las casas?',
            opciones: ['Soplaba', 'Cantaba', 'Leía', 'Sembraba trigo'],
            respuestaCorrecta: 'Soplaba',
            explicacion: 'El lobo sopló con fuerza contra las casas.',
          ),
          Actividad(
            pregunta: '¿Cuál fue la mejor decisión?',
            opciones: [
              'Construir con paciencia',
              'Trabajar rápido sin pensar',
              'Dormirse en la carrera',
              'Entrar sin permiso',
            ],
            respuestaCorrecta: 'Construir con paciencia',
            explicacion: 'El esfuerzo cuidadoso protegió a los cerditos.',
          ),
          Actividad(
            pregunta: '¿Qué palabra describe al cerdito de ladrillos?',
            opciones: ['Previsor', 'Distraído', 'Mentiroso', 'Desordenado'],
            respuestaCorrecta: 'Previsor',
            explicacion: 'Pensó en el futuro y eligió un material resistente.',
          ),
        ],
        'patito-feo': const [
          Actividad(
            pregunta: '¿Qué descubrió el patito al crecer?',
            opciones: [
              'Que era un cisne',
              'Que era un gato',
              'Que era una liebre',
              'Que era un flautista',
            ],
            respuestaCorrecta: 'Que era un cisne',
            explicacion: 'Descubrió su verdadera identidad como cisne.',
          ),
          Actividad(
            pregunta: '¿Cómo se sintió al principio?',
            opciones: ['Rechazado', 'Orgulloso', 'Dormido', 'Invisible'],
            respuestaCorrecta: 'Rechazado',
            explicacion: 'Los demás animales lo trataban como diferente.',
          ),
          Actividad(
            pregunta: '¿Qué enseña el cuento?',
            opciones: [
              'Aceptar las diferencias',
              'Burlarse de otros',
              'No cambiar nunca',
              'Prometer sin cumplir',
            ],
            respuestaCorrecta: 'Aceptar las diferencias',
            explicacion: 'Ser distinto puede ser valioso y merece respeto.',
          ),
          Actividad(
            pregunta: '¿Qué significa "identidad"?',
            opciones: [
              'Quién eres',
              'Una carrera',
              'Una casa',
              'Un plato de sopa',
            ],
            respuestaCorrecta: 'Quién eres',
            explicacion: 'La identidad habla de lo que somos.',
          ),
        ],
        'cigarra-hormiga': const [
          Actividad(
            pregunta: '¿Qué hacía la hormiga durante el verano?',
            opciones: ['Trabajaba', 'Dormía', 'Cantaba todo el día', 'Viajaba'],
            respuestaCorrecta: 'Trabajaba',
            explicacion: 'La hormiga preparaba comida para el frío.',
          ),
          Actividad(
            pregunta: '¿Qué problema tuvo la cigarra cuando llegó el frío?',
            opciones: [
              'No tenía comida',
              'No sabía cantar',
              'No encontraba una lámpara',
              'No podía correr',
            ],
            respuestaCorrecta: 'No tenía comida',
            explicacion: 'No se preparó durante el verano.',
          ),
          Actividad(
            pregunta: '¿Cuál es la enseñanza principal?',
            opciones: [
              'Prepararse a tiempo',
              'Evitar la música',
              'No tener amigos',
              'Entrar sin permiso',
            ],
            respuestaCorrecta: 'Prepararse a tiempo',
            explicacion: 'Planear ayuda cuando llegan momentos difíciles.',
          ),
          Actividad(
            pregunta: '¿Qué palabra describe a la hormiga?',
            opciones: ['Responsable', 'Engañosa', 'Impaciente', 'Miedosa'],
            respuestaCorrecta: 'Responsable',
            explicacion: 'La hormiga trabajó pensando en el futuro.',
          ),
        ],
        'ricitos-tres-osos': const [
          Actividad(
            pregunta: '¿Dónde entró Ricitos?',
            opciones: [
              'En una casita del bosque',
              'En una cueva',
              'En una escuela',
              'En un barco',
            ],
            respuestaCorrecta: 'En una casita del bosque',
            explicacion: 'La casa pertenecía a los tres osos.',
          ),
          Actividad(
            pregunta: '¿Qué aprendió Ricitos?',
            opciones: [
              'Respetar lo ajeno',
              'Correr más rápido',
              'Mentir mejor',
              'Pedir deseos',
            ],
            respuestaCorrecta: 'Respetar lo ajeno',
            explicacion: 'Entró y usó cosas sin permiso.',
          ),
          Actividad(
            pregunta: '¿Cuántos tamaños comparó Ricitos?',
            opciones: ['Tres', 'Uno', 'Cinco', 'Siete'],
            respuestaCorrecta: 'Tres',
            explicacion: 'Había tres sopas, sillas y camas.',
          ),
          Actividad(
            pregunta: '¿Qué acción habría sido correcta antes de entrar?',
            opciones: [
              'Tocar la puerta',
              'Esconderse',
              'Romper una silla',
              'Gritar'
            ],
            respuestaCorrecta: 'Tocar la puerta',
            explicacion: 'Pedir permiso es una forma de respeto.',
          ),
        ],
        'gallina-roja': const [
          Actividad(
            pregunta: '¿Qué encontró la gallinita?',
            opciones: [
              'Granos de trigo',
              'Una lámpara',
              'Una red',
              'Un zapato'
            ],
            respuestaCorrecta: 'Granos de trigo',
            explicacion: 'Con esos granos comenzó el trabajo del pan.',
          ),
          Actividad(
            pregunta: '¿Qué hicieron sus amigos cuando pidió ayuda?',
            opciones: [
              'No ayudaron',
              'Sembraron juntos',
              'Le compraron pan',
              'Cantaron'
            ],
            respuestaCorrecta: 'No ayudaron',
            explicacion: 'La gallinita trabajó sola casi todo el tiempo.',
          ),
          Actividad(
            pregunta: '¿Qué valor aparece en el cuento?',
            opciones: ['Colaboración', 'Vanidad', 'Trampa', 'Silencio'],
            respuestaCorrecta: 'Colaboración',
            explicacion: 'El cuento invita a ayudar antes de recibir.',
          ),
          Actividad(
            pregunta: '¿Por qué el pan era especial?',
            opciones: [
              'Porque fue fruto del esfuerzo',
              'Porque era mágico',
              'Porque lo hizo un ogro',
              'Porque apareció solo',
            ],
            respuestaCorrecta: 'Porque fue fruto del esfuerzo',
            explicacion: 'El trabajo constante produjo el resultado.',
          ),
        ],
        'pinocho': const [
          Actividad(
            pregunta: '¿Quién construyó a Pinocho?',
            opciones: ['Gepeto', 'Aladino', 'El alcalde', 'La abuelita'],
            respuestaCorrecta: 'Gepeto',
            explicacion: 'Gepeto creó el muñeco de madera.',
          ),
          Actividad(
            pregunta: '¿Qué problema traían las mentiras?',
            opciones: [
              'Alejaban a quienes lo cuidaban',
              'Hacían correr más rápido',
              'Construían casas',
              'Preparaban comida',
            ],
            respuestaCorrecta: 'Alejaban a quienes lo cuidaban',
            explicacion: 'Mentir rompía la confianza.',
          ),
          Actividad(
            pregunta: '¿Qué decisión mejoró a Pinocho?',
            opciones: [
              'Elegir la verdad',
              'Dormirse',
              'Burlarse',
              'No escuchar',
            ],
            respuestaCorrecta: 'Elegir la verdad',
            explicacion: 'La honestidad lo acercó a su mejor versión.',
          ),
          Actividad(
            pregunta: '¿Qué tema central tiene el cuento?',
            opciones: ['Honestidad', 'Orgullo', 'Pereza', 'Riqueza fácil'],
            respuestaCorrecta: 'Honestidad',
            explicacion: 'La historia muestra por qué decir la verdad importa.',
          ),
        ],
        'gato-botas': const [
          Actividad(
            pregunta: '¿Qué recibió el joven como herencia?',
            opciones: [
              'Un gato astuto',
              'Una lámpara',
              'Una casa dulce',
              'Un barco'
            ],
            respuestaCorrecta: 'Un gato astuto',
            explicacion: 'El gato con botas se volvió su gran aliado.',
          ),
          Actividad(
            pregunta: '¿Qué cualidad usó el gato?',
            opciones: ['Ingenio', 'Fuerza sin pensar', 'Pereza', 'Miedo'],
            respuestaCorrecta: 'Ingenio',
            explicacion: 'El gato resolvió problemas con inteligencia.',
          ),
          Actividad(
            pregunta: '¿A quién venció el gato?',
            opciones: [
              'Al ogro',
              'Al leñador',
              'A la gallinita',
              'A la tortuga'
            ],
            respuestaCorrecta: 'Al ogro',
            explicacion: 'Su plan permitió vencer al ogro.',
          ),
          Actividad(
            pregunta: '¿Qué enseña esta aventura?',
            opciones: [
              'Pensar antes de actuar',
              'Prometer y no cumplir',
              'Entrar sin permiso',
              'Rendirse pronto',
            ],
            respuestaCorrecta: 'Pensar antes de actuar',
            explicacion: 'La estrategia del gato cambió la situación.',
          ),
        ],
        'aladino-lampara': const [
          Actividad(
            pregunta: '¿Qué encontró Aladino?',
            opciones: [
              'Una lámpara antigua',
              'Una red',
              'Una silla',
              'Un trigo'
            ],
            respuestaCorrecta: 'Una lámpara antigua',
            explicacion: 'La lámpara escondía al genio.',
          ),
          Actividad(
            pregunta: '¿Quién apareció desde la lámpara?',
            opciones: ['Un genio', 'Un lobo', 'Una hormiga', 'Un osito'],
            respuestaCorrecta: 'Un genio',
            explicacion: 'El genio ofrecía ayuda y deseos.',
          ),
          Actividad(
            pregunta: '¿Cómo debía usar Aladino sus deseos?',
            opciones: [
              'Con responsabilidad',
              'Sin pensar',
              'Para engañar',
              'Para dormir',
            ],
            respuestaCorrecta: 'Con responsabilidad',
            explicacion: 'El poder necesita prudencia y honestidad.',
          ),
          Actividad(
            pregunta: '¿Qué protegió Aladino?',
            opciones: [
              'A su familia',
              'Una carrera',
              'Una casa de paja',
              'Un pan'
            ],
            respuestaCorrecta: 'A su familia',
            explicacion: 'Eligió cuidar a quienes quería.',
          ),
        ],
        'flautista-hamelin': const [
          Actividad(
            pregunta: '¿Qué instrumento tocaba el flautista?',
            opciones: ['Flauta', 'Tambor', 'Piano', 'Campana'],
            respuestaCorrecta: 'Flauta',
            explicacion: 'Su música guiaba a los animales.',
          ),
          Actividad(
            pregunta: '¿Qué problema resolvió al inicio?',
            opciones: [
              'Sacó a los animales del pueblo',
              'Construyó una casa',
              'Hizo pan',
              'Encontró a Gepeto',
            ],
            respuestaCorrecta: 'Sacó a los animales del pueblo',
            explicacion: 'La música ayudó al pueblo.',
          ),
          Actividad(
            pregunta: '¿Qué hizo mal el alcalde?',
            opciones: [
              'Rompió su promesa',
              'Sembró trigo',
              'Leyó un cuento',
              'Ayudó demasiado',
            ],
            respuestaCorrecta: 'Rompió su promesa',
            explicacion: 'No cumplió lo acordado con el flautista.',
          ),
          Actividad(
            pregunta: '¿Qué idea deja el cuento?',
            opciones: [
              'Cumplir acuerdos',
              'Burlarse',
              'No trabajar',
              'Usar cosas ajenas',
            ],
            respuestaCorrecta: 'Cumplir acuerdos',
            explicacion: 'Las promesas mantienen la confianza.',
          ),
        ],
        'hansel-gretel': const [
          Actividad(
            pregunta: '¿Dónde se perdieron Hansel y Gretel?',
            opciones: [
              'En el bosque',
              'En el mar',
              'En una ciudad',
              'En una carrera'
            ],
            respuestaCorrecta: 'En el bosque',
            explicacion: 'Buscaron señales para poder volver.',
          ),
          Actividad(
            pregunta: '¿Qué encontraron en el camino?',
            opciones: [
              'Una casa dulce',
              'Una lámpara',
              'Un molino',
              'Una escuela'
            ],
            respuestaCorrecta: 'Una casa dulce',
            explicacion: 'Parecía atractiva, pero escondía peligro.',
          ),
          Actividad(
            pregunta: '¿Cómo lograron escapar?',
            opciones: [
              'Cooperando con calma',
              'Durmiendo',
              'Mintiendo todo el tiempo',
              'Olvidando el problema',
            ],
            respuestaCorrecta: 'Cooperando con calma',
            explicacion: 'Trabajaron juntos para salir del peligro.',
          ),
          Actividad(
            pregunta: '¿Qué emoción muestra el final?',
            opciones: ['Unión', 'Envidia', 'Pereza', 'Burla'],
            respuestaCorrecta: 'Unión',
            explicacion: 'Los hermanos vuelven más unidos.',
          ),
        ],
        'soldadito-plomo': const [
          Actividad(
            pregunta: '¿De qué material era el soldadito?',
            opciones: ['Plomo', 'Madera', 'Trigo', 'Papel'],
            respuestaCorrecta: 'Plomo',
            explicacion: 'Era un soldadito de plomo.',
          ),
          Actividad(
            pregunta: '¿Qué tenía de especial su cuerpo?',
            opciones: [
              'Una sola pierna',
              'Alas',
              'Botas mágicas',
              'Una corona'
            ],
            respuestaCorrecta: 'Una sola pierna',
            explicacion: 'Aun así miraba el mundo con valor.',
          ),
          Actividad(
            pregunta: '¿Qué cualidad mantuvo durante su viaje?',
            opciones: ['Valentía', 'Vanidad', 'Impaciencia', 'Mentira'],
            respuestaCorrecta: 'Valentía',
            explicacion: 'Siguió firme a pesar de lo difícil.',
          ),
          Actividad(
            pregunta: '¿Qué significa "perseverancia"?',
            opciones: [
              'Seguir adelante',
              'Rendirse rápido',
              'Olvidar todo',
              'Prometer sin cumplir',
            ],
            respuestaCorrecta: 'Seguir adelante',
            explicacion: 'El soldadito no se rindió durante su viaje.',
          ),
        ],
      });
  }

  void _aplicarEstadoCuentos() {
    const imagenesPorCuento = {
      'leon-raton': 'assets/images/cover_leon_raton.png',
      'tortuga-liebre': 'assets/images/cover_tortuga_liebre.png',
      'caperucita-roja': 'assets/images/cover_caperucita_roja.png',
      'tres-cerditos': 'assets/images/cover_tres_cerditos.png',
      'patito-feo': 'assets/images/cover_patito_feo.png',
      'cigarra-hormiga': 'assets/images/cover_cigarra_hormiga.png',
      'ricitos-tres-osos': 'assets/images/cover_ricitos_osos.png',
      'gallina-roja': 'assets/images/cover_gallinita_roja.png',
      'pinocho': 'assets/images/cover_pinocho.png',
      'gato-botas': 'assets/images/cover_gato_botas.png',
      'aladino-lampara': 'assets/images/cover_aladino_lampara.png',
      'flautista-hamelin': 'assets/images/cover_flautista_hamelin.png',
      'hansel-gretel': 'assets/images/cover_hansel_gretel.png',
      'soldadito-plomo': 'assets/images/cover_soldadito_plomo.png',
    };
    final actualizado = <Cuento>[];
    for (final cuento in _cuentos) {
      final completado = _fechasCompletado.containsKey(cuento.id);
      actualizado.add(
        cuento.copyWith(
          completado: completado,
          estrellasGanadas:
              _estrellasPorCuento[cuento.id] ?? cuento.estrellasGanadas,
          imagenPath: cuento.imagenPath.isEmpty
              ? imagenesPorCuento[cuento.id]
              : cuento.imagenPath,
        ),
      );
    }
    _cuentos = actualizado;
    _usuarioActivo = _usuarioActivo.copyWith(
      cuentosLeidos: _fechasCompletado.length,
      estrellasTotal: _estrellasPorCuento.values.fold<int>(
        0,
        (total, estrellas) => total + estrellas,
      ),
    );
  }

  void _sincronizarUsuarioActivo() {
    final index = _usuarios.indexWhere((u) => u.id == _usuarioActivo.id);
    if (index == -1) return;
    _usuarios[index] = _usuarioActivo;
  }

  String obtenerTituloCuento(String cuentoId) {
    for (final cuento in _cuentos) {
      if (cuento.id == cuentoId) return cuento.titulo;
    }
    return cuentoId;
  }

  bool esFavorito(String cuentoId) => _favoritos.contains(cuentoId);

  void alternarFavorito(String cuentoId) {
    if (_favoritos.contains(cuentoId)) {
      _favoritos.remove(cuentoId);
    } else {
      _favoritos.add(cuentoId);
    }
    _guardarProgreso();
    notifyListeners();
  }

  Future<void> sincronizarBibliotecaExterna({bool force = false}) async {
    if (_sincronizandoBiblioteca) return;
    if (!force && _cuentos.any((cuento) => cuento.id.startsWith('ol-'))) {
      return;
    }
    _sincronizandoBiblioteca = true;
    _bibliotecaError = null;
    notifyListeners();

    try {
      final externos = await _openLibraryService.obtenerLibrosInfantiles();
      final idsExistentes = _cuentos.map((cuento) => cuento.id).toSet();
      final nuevos = externos
          .where((cuento) => !idsExistentes.contains(cuento.id))
          .toList(growable: false);
      if (nuevos.isNotEmpty) {
        _cuentos = [..._cuentos, ...nuevos];
        await _guardarProgreso();
      }
    } catch (_) {
      _bibliotecaError =
          'No se pudo actualizar Open Library. Mostrando biblioteca local.';
    } finally {
      _sincronizandoBiblioteca = false;
      _aplicarEstadoCuentos();
      notifyListeners();
    }
  }

  List<Cuento> obtenerCuentosFiltrados({String? nivel, String? grupoEdad}) {
    return _cuentos.where((cuento) {
      final coincideNivel =
          nivel == null || nivel == 'Todos' || cuento.nivel == nivel;
      final coincideEdad = grupoEdad == null ||
          grupoEdad == 'Todas' ||
          (grupoEdad == '3-5' && cuento.edadMin <= 5 && cuento.edadMax >= 3) ||
          (grupoEdad == '6-8' && cuento.edadMin <= 8 && cuento.edadMax >= 6) ||
          (grupoEdad == '9-12' && cuento.edadMin <= 12 && cuento.edadMax >= 9);
      return coincideNivel && coincideEdad;
    }).toList();
  }

  List<Actividad> obtenerActividadesDeCuento(
    String cuentoId, {
    String titulo = '',
  }) {
    final predefinidas = _actividades[cuentoId];
    if (predefinidas != null && predefinidas.isNotEmpty) {
      return predefinidas;
    }

    Cuento? cuento;
    for (final item in _cuentos) {
      if (item.id == cuentoId) {
        cuento = item;
        break;
      }
    }
    return _generarActividadesAutomaticas(cuento, titulo);
  }

  List<Actividad> _generarActividadesAutomaticas(
    Cuento? cuento,
    String titulo,
  ) {
    final tituloFinal = cuento?.titulo ?? titulo;
    final paginas = cuento?.paginas ?? const <String>[];
    final texto = paginas.join(' ');
    final palabrasClave = _palabrasClave(texto);
    final palabra = palabrasClave.isEmpty ? tituloFinal : palabrasClave.first;
    final segunda = palabrasClave.length > 1 ? palabrasClave[1] : palabra;
    final descripcion = cuento?.descripcion ?? texto;
    final autor = _valorFicha(descripcion, 'Autor') ?? 'No indicado';
    final anio = _valorFicha(descripcion, 'Año');
    final tema =
        _valorFicha(descripcion, 'Tema') ?? _temaDesdeDescripcion(descripcion);
    final preguntaAnio = anio == null
        ? Actividad(
            pregunta: '¿Qué dato sí aparece en la ficha de "$tituloFinal"?',
            opciones: _opciones([
              'Autor: $autor',
              'Precio de venta',
              'Contraseña del lector',
              'Número de teléfono',
            ]),
            respuestaCorrecta: 'Autor: $autor',
            explicacion:
                'La actividad usa datos reales disponibles en la ficha del libro.',
          )
        : Actividad(
            pregunta: '¿Qué año aparece en la ficha de "$tituloFinal"?',
            opciones: _opciones([anio, '1840', '1999', '2026']),
            respuestaCorrecta: anio,
            explicacion:
                'El año se toma de la metadata disponible para este libro.',
          );
    return [
      Actividad(
        pregunta: '¿Quién figura como autor o autora de "$tituloFinal"?',
        opciones: _opciones([
          autor,
          'Gabriela Mistral',
          'Hans Christian Andersen',
          'Anónimo escolar',
        ]),
        respuestaCorrecta: autor,
        explicacion:
            'La respuesta sale de la ficha del libro, no de una plantilla genérica.',
      ),
      Actividad(
        pregunta: '¿Qué tema identifica mejor a "$tituloFinal"?',
        opciones: _opciones([
          tema,
          'Recetas de cocina',
          'Tráfico de ciudad',
          'Manual de herramientas',
        ]),
        respuestaCorrecta: tema,
        explicacion:
            'El tema se calcula desde la ficha y el texto disponible del libro.',
      ),
      Actividad(
        pregunta: '¿Qué palabra clave aparece en la lectura de "$tituloFinal"?',
        opciones: _opciones([palabra, 'cohete', 'zapato', 'montaña']),
        respuestaCorrecta: palabra,
        explicacion:
            'La palabra clave se extrae del texto creado para este libro.',
      ),
      preguntaAnio,
      Actividad(
        pregunta: '¿Qué detalle conecta "$segunda" con "$tituloFinal"?',
        opciones: _opciones([
          'Aparece en la ficha o lectura del libro',
          'Es una palabra elegida al azar',
          'Es una instrucción técnica',
          'Es un mensaje de depuración',
        ]),
        respuestaCorrecta: 'Aparece en la ficha o lectura del libro',
        explicacion:
            'Cada pregunta automática usa título, autor, tema o palabras del libro.',
      ),
    ].take(4).toList(growable: false);
  }

  List<String> _opciones(List<String> values) {
    final unique = <String>[];
    for (final value in values) {
      if (value.trim().isEmpty || unique.contains(value)) continue;
      unique.add(value);
    }
    while (unique.length < 4) {
      unique.add('Otra opción ${unique.length + 1}');
    }
    final result = unique.take(4).toList(growable: false);
    final shift =
        result.first.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
            result.length;
    return [...result.skip(shift), ...result.take(shift)];
  }

  String? _valorFicha(String text, String key) {
    final pattern = RegExp('$key: ([^·]+)');
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  List<String> _palabrasClave(String text) {
    const stop = {
      'para',
      'como',
      'este',
      'esta',
      'desde',
      'sobre',
      'cuento',
      'historia',
      'lectura',
      'despues',
      'antes',
      'cada',
      'todo',
      'todos',
      'todas',
    };
    final counts = <String, int>{};
    for (final raw in text.toLowerCase().split(RegExp(r'[^a-záéíóúñü]+'))) {
      final word = raw.trim();
      if (word.length < 5 || stop.contains(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        return countCompare == 0 ? a.key.compareTo(b.key) : countCompare;
      });
    return sorted.take(4).map((entry) => entry.key).toList();
  }

  String _temaDesdeDescripcion(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('responsabilidad') || lower.contains('prepar')) {
      return 'Responsabilidad';
    }
    if (lower.contains('amistad') || lower.contains('familia')) {
      return 'Cuidado y amistad';
    }
    if (lower.contains('valent') || lower.contains('peligro')) {
      return 'Valentía';
    }
    if (lower.contains('honest') || lower.contains('verdad')) {
      return 'Honestidad';
    }
    return 'Comprensión lectora';
  }

  List<Logro> obtenerLogros() {
    final cuentosLeidos = _fechasCompletado.length;
    final estrellasTotales = _usuarioActivo.estrellasTotal;
    return [
      _logrosBase[0].copyWith(desbloqueado: cuentosLeidos >= 1),
      _logrosBase[1].copyWith(desbloqueado: estrellasTotales >= 5),
      _logrosBase[2].copyWith(desbloqueado: cuentosLeidos >= 3),
      _logrosBase[3].copyWith(desbloqueado: cuentosLeidos >= _cuentos.length),
    ];
  }

  List<MapEntry<String, DateTime>> obtenerCuentosCompletadosConFecha() {
    final entries = _fechasCompletado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int get cuentosLeidosEstaSemana {
    final hoy = DateTime.now();
    return _fechasCompletado.values.where((fecha) {
      final diferencia = hoy.difference(fecha).inDays;
      return diferencia >= 0 && diferencia <= 7;
    }).length;
  }

  double get porcentajeRespuestasCorrectas {
    if (_totalRespuestas == 0) return 0;
    return (_respuestasCorrectas / _totalRespuestas) * 100;
  }

  String? registrarTutor({
    required String nombre,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final nombreLimpio = nombre.trim();
    final emailNormalizado = email.trim().toLowerCase();
    if (nombreLimpio.length < 2) {
      return 'Escribe el nombre del tutor.';
    }
    if (!_emailValido(emailNormalizado)) {
      return 'Escribe un correo válido.';
    }
    if (_cuentaTutor != null && _cuentaTutor!.email == emailNormalizado) {
      return 'Ese correo ya está registrado.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden.';
    }
    _cuentaTutor = CuentaTutor(
      nombre: nombreLimpio,
      email: emailNormalizado,
      password: password,
    );
    _sesionTutorActiva = true;
    _guardarProgreso();
    notifyListeners();
    return null;
  }

  String? iniciarSesionTutor({
    required String email,
    required String password,
  }) {
    final emailNormalizado = email.trim().toLowerCase();
    if (_cuentaTutor == null) {
      return 'Primero regístrate.';
    }
    if (_cuentaTutor!.email != emailNormalizado ||
        _cuentaTutor!.password != password) {
      return 'Correo o contraseña incorrectos.';
    }
    _sesionTutorActiva = true;
    _guardarProgreso();
    notifyListeners();
    return null;
  }

  void cerrarSesionTutor() {
    _sesionTutorActiva = false;
    _guardarProgreso();
    notifyListeners();
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void seleccionarUsuario(Usuario usuario) {
    _usuarioActivo = usuario;
    _aplicarEstadoCuentos();
    _sincronizarUsuarioActivo();
    notifyListeners();
  }

  void crearUsuario({
    required String nombre,
    required int edad,
    required String avatar,
  }) {
    final nuevo = Usuario(
      id: 'perfil_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      edad: edad,
      avatar: avatar,
      estrellasTotal: 0,
      cuentosLeidos: 0,
    );
    _usuarios.add(nuevo);
    if (_usuarioActivo.id == 'guest' || _usuarios.length == 1) {
      _usuarioActivo = nuevo;
    }
    _aplicarEstadoCuentos();
    _sincronizarUsuarioActivo();
    _guardarProgreso();
    notifyListeners();
  }

  void eliminarUsuario(String id) {
    _usuarios.removeWhere((u) => u.id == id);
    if (_usuarioActivo.id == id) {
      _usuarioActivo = _usuarios.isNotEmpty
          ? _usuarios.first
          : const Usuario(
              id: 'guest',
              nombre: 'Invitado',
              edad: 6,
              avatar: '🦊',
              estrellasTotal: 0,
              cuentosLeidos: 0,
            );
    }
    _guardarProgreso();
    notifyListeners();
  }

  void alternarModoOscuro(bool value) {
    _modoOscuro = value;
    _guardarProgreso();
    notifyListeners();
  }

  bool verificarPinPadres(String pin) {
    return pin.trim() == _pinPadres;
  }

  void actualizarPinPadres(String nuevoPin) {
    final normalizado = nuevoPin.trim();
    if (normalizado.length != 4) return;
    _pinPadres = normalizado;
    _guardarProgreso();
    notifyListeners();
  }

  void actualizarTiempoMaximoDiario(double value) {
    _tiempoMaximoDiario = value.round();
    _guardarProgreso();
    notifyListeners();
  }

  void registrarRespuesta({required bool correcta, required String cuentoId}) {
    _totalRespuestas += 1;
    if (correcta) {
      _respuestasCorrectas += 1;
    }
    _guardarProgreso();
    notifyListeners();
  }

  Future<void> guardarProgreso() async {
    await _guardarProgresoInterno();
  }

  Future<void> marcarCuentoCompletado({
    required String cuentoId,
    required int estrellasGanadas,
  }) async {
    final estrellasPrevias = _estrellasPorCuento[cuentoId] ?? 0;
    final estrellasFinales = estrellasGanadas > estrellasPrevias
        ? estrellasGanadas
        : estrellasPrevias;
    _fechasCompletado[cuentoId] = DateTime.now();
    _estrellasPorCuento[cuentoId] = estrellasFinales;
    _aplicarEstadoCuentos();
    _sincronizarUsuarioActivo();
    await _guardarProgreso();
    notifyListeners();
  }

  Future<void> guardarCuentosActualizados(
    List<Cuento> cuentosActualizados,
  ) async {
    _cuentos = cuentosActualizados;
    await _guardarProgreso();
    notifyListeners();
  }

  Future<void> _guardarProgreso() async {
    await _guardarProgresoInterno();
  }

  Future<void> _guardarProgresoInterno() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'modoOscuro': _modoOscuro,
      'sesionTutorActiva': _sesionTutorActiva,
      'cuentaTutor': _cuentaTutor?.toJson(),
      'pinPadres': _pinPadres,
      'tiempoMaximoDiario': _tiempoMaximoDiario,
      'totalRespuestas': _totalRespuestas,
      'respuestasCorrectas': _respuestasCorrectas,
      'usuarioActivo': _usuarioActivo.toJson(),
      'usuarios': _usuarios.map((u) => u.toJson()).toList(),
      'cuentos': _cuentos.map((cuento) => cuento.toJson()).toList(),
      'favoritos': _favoritos.toList(),
      'fechasCompletado': _fechasCompletado.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'estrellasPorCuento': _estrellasPorCuento,
    };
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
