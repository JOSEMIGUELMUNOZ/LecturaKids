import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cuento.dart';

class OpenLibraryService {
  final http.Client _client;

  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Cuento>> obtenerLibrosInfantiles({int limit = 12}) async {
    const queries = [
      'cuentos infantiles',
      'literatura infantil',
      'fabulas infantiles',
      'cuentos para niños',
    ];
    final results = <Cuento>[];
    final seen = <String>{};

    for (final query in queries) {
      if (results.length >= limit) break;
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'q': query,
        'language': 'spa',
        'has_fulltext': 'true',
        'fields': 'key,title,author_name,cover_i,first_publish_year,subject',
        'limit': '${limit * 2}',
      });

      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw OpenLibraryException(
          'Open Library respondió ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = decoded['docs'] as List<dynamic>? ?? [];
      for (final doc in docs.whereType<Map<String, dynamic>>()) {
        final cuento = _mapDoc(doc);
        if (cuento == null || seen.contains(cuento.id)) continue;
        seen.add(cuento.id);
        results.add(cuento);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  Cuento? _mapDoc(Map<String, dynamic> doc) {
    final key = doc['key'] as String?;
    final title = (doc['title'] as String?)?.trim();
    if (key == null || title == null || title.isEmpty) return null;
    if (!_pareceLibroEspanol(title)) return null;

    final authors = (doc['author_name'] as List<dynamic>?)
            ?.whereType<String>()
            .take(2)
            .join(', ') ??
        'Open Library';
    final subjects = (doc['subject'] as List<dynamic>?)
            ?.whereType<String>()
            .take(8)
            .toList(growable: false) ??
        const <String>[];
    final tema = _temaDesdeSubjects(subjects, title);
    final coverId = doc['cover_i'] as int?;
    final year = doc['first_publish_year'] as int?;
    final level = _nivelDesdeTitulo(title);
    final ages = _edadDesdeNivel(level);
    final sourceId = key.replaceAll('/works/', 'ol-').replaceAll('/', '-');
    final coverUrl = coverId == null
        ? ''
        : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    final descripcion = [
      'Fuente: Open Library',
      'Autor: $authors',
      if (year != null) 'Año: $year',
      'Tema: $tema',
    ].join(' · ');

    return Cuento(
      id: sourceId,
      titulo: title,
      nivel: level,
      edadMin: ages.$1,
      edadMax: ages.$2,
      paginas: _paginasAdaptadas(title, authors, year, tema),
      completado: false,
      estrellasGanadas: 0,
      descripcion: descripcion,
      imagenPath: coverUrl,
    );
  }

  bool _pareceLibroEspanol(String title) {
    final lower = title.toLowerCase();
    const englishSignals = {
      ' the ',
      ' and ',
      ' of ',
      ' little ',
      ' fairy ',
      ' story ',
      ' stories ',
      ' book ',
      ' children ',
    };
    if (englishSignals.any((signal) => ' $lower '.contains(signal))) {
      return false;
    }
    const spanishSignals = {
      ' el ',
      ' la ',
      ' los ',
      ' las ',
      ' de ',
      ' del ',
      ' y ',
      ' un ',
      ' una ',
      ' niño',
      ' niña',
      'cuento',
      'cuentos',
      'aventura',
      'fábula',
      'fabula',
      'á',
      'é',
      'í',
      'ó',
      'ú',
      'ñ',
    };
    return spanishSignals.any((signal) => ' $lower '.contains(signal));
  }

  String _temaDesdeSubjects(List<String> subjects, String title) {
    final text = [...subjects, title].join(' ').toLowerCase();
    if (text.contains('animal') || text.contains('fable')) {
      return 'Animales y fábulas';
    }
    if (text.contains('fantasy') || text.contains('fantas')) {
      return 'Fantasía';
    }
    if (text.contains('famil') || text.contains('friend')) {
      return 'Familia y amistad';
    }
    if (text.contains('school') || text.contains('escuela')) {
      return 'Escuela';
    }
    if (text.contains('adventure') || text.contains('aventura')) {
      return 'Aventura';
    }
    return 'Lectura infantil';
  }

  String _nivelDesdeTitulo(String title) {
    final words = title.split(RegExp(r'\s+')).length;
    if (words <= 3) return 'Fácil';
    if (words <= 6) return 'Medio';
    return 'Avanzado';
  }

  (int, int) _edadDesdeNivel(String level) {
    return switch (level) {
      'Fácil' => (3, 6),
      'Medio' => (6, 9),
      _ => (8, 12),
    };
  }

  List<String> _paginasAdaptadas(
    String title,
    String authors,
    int? year,
    String tema,
  ) {
    final byline = authors.isEmpty ? 'un autor clásico' : authors;
    return [
      '"$title" es un libro infantil en español registrado en Open Library.',
      'La ficha indica autoría de $byline${year == null ? '' : ' y año $year'}.',
      'Su tema principal para esta actividad es $tema.',
      'Después de leerlo, revisa portada, autor, tema y palabras clave para responder.',
    ];
  }
}

class OpenLibraryException implements Exception {
  final String message;

  const OpenLibraryException(this.message);

  @override
  String toString() => message;
}
