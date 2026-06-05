import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../services/data_service.dart';
import '../widgets/app_chrome.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _nivel = 'Todos';
  String _grupoEdad = 'Todas';
  bool _soloFavoritos = false;
  bool _buscando = false;
  String _consulta = '';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DataService>();
    final consulta = _consulta.trim().toLowerCase();
    final cuentos = service
        .obtenerCuentosFiltrados(
          nivel: _nivel,
          grupoEdad: _grupoEdad,
        )
        .where((cuento) =>
            consulta.isEmpty ||
            cuento.titulo.toLowerCase().contains(consulta) ||
            cuento.descripcion.toLowerCase().contains(consulta))
        .where((cuento) => !_soloFavoritos || service.esFavorito(cuento.id))
        .toList();

    return PhoneShell(
      selectedTab: AppTab.library,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Biblioteca',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Buscar',
                onPressed: () => setState(() {
                  _buscando = !_buscando;
                  if (!_buscando) _consulta = '';
                }),
                icon: Icon(
                  _buscando ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Actualizar biblioteca',
                onPressed: service.sincronizandoBiblioteca
                    ? null
                    : () => service.sincronizarBibliotecaExterna(force: true),
                icon: service.sincronizandoBiblioteca
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          if (service.bibliotecaError != null) ...[
            const SizedBox(height: 10),
            _LibraryNotice(message: service.bibliotecaError!),
          ],
          if (_buscando) ...[
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar cuento',
              ),
              onChanged: (value) => setState(() => _consulta = value),
            ),
          ],
          const SizedBox(height: 14),
          _ChipScroller(
            values: const ['Todos', 'Favoritos', 'Fácil', 'Medio', 'Avanzado'],
            selected: _soloFavoritos ? 'Favoritos' : _nivel,
            onChanged: (value) => setState(() {
              _soloFavoritos = value == 'Favoritos';
              _nivel = value == 'Favoritos' ? 'Todos' : value;
            }),
          ),
          const SizedBox(height: 10),
          _ChipScroller(
            values: const ['Todas', '3-5', '6-8', '9-12'],
            selected: _grupoEdad,
            onChanged: (value) => setState(() => _grupoEdad = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: cuentos.isEmpty
                ? const _EmptyLibraryState()
                : ListView.separated(
                    itemCount: cuentos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cuento = cuentos[index];
                      return StoryTile(
                        cuento: cuento,
                        favorite: service.esFavorito(cuento.id),
                        onFavoriteTap: () =>
                            service.alternarFavorito(cuento.id),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.reader,
                          arguments: cuento,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LibraryNotice extends StatelessWidget {
  final String message;

  const _LibraryNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'No encontramos cuentos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba con otro nivel, edad o búsqueda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ChipScroller extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChipScroller({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          final label = value == 'Avanzado' ? 'Avanz.' : value;
          return ChoiceChip(
            label: Text(label),
            selected: selected == value,
            showCheckmark: false,
            onSelected: (_) => onChanged(value),
          );
        },
      ),
    );
  }
}
