import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/cuento.dart';
import '../services/data_service.dart';
import '../widgets/app_chrome.dart';
import '../widgets/avatar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DataService>();
    final usuario = service.usuarioActivo;
    final cuentos = service.cuentos;
    final sigueLeyendo = cuentos.firstWhere(
      (cuento) => !cuento.completado,
      orElse: () => cuentos.first,
    );
    final logros = service.obtenerLogros();

    return PhoneShell(
      selectedTab: AppTab.home,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarWidget(
                  avatar: usuario.avatar,
                  nombre: usuario.nombre,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Hola, ${usuario.nombre}! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ajustes',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.parentPanel,
                  ),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ContinueCard(cuento: sigueLeyendo),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Mis logros',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAchievements(context, service),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 126,
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.star_rounded,
                      value: '${usuario.estrellasTotal}',
                      label: 'Estrellas',
                      color: const Color(0xFFFFC338),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.menu_book_rounded,
                      value: '${usuario.cuentosLeidos}',
                      label: 'Historias',
                      color: const Color(0xFF20BFA9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.emoji_events_rounded,
                      value: '${logros.where((l) => l.desbloqueado).length}',
                      label: 'Insignias',
                      color: const Color(0xFF8E6BE8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Para ti', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.library),
                  child: const Text('Ver más'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 156,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cuentos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _RecommendationCard(cuento: cuentos[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievements(BuildContext context, DataService service) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final logros = service.obtenerLogros();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis logros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...logros.map(
                (logro) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipOval(
                    child: Image.asset(
                      logro.imagenPath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(logro.nombre),
                  subtitle: Text(logro.descripcion),
                  trailing: Icon(
                    logro.desbloqueado
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: logro.desbloqueado
                        ? Theme.of(context).colorScheme.tertiary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Cuento cuento;

  const _ContinueCard({required this.cuento});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFECCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sigue leyendo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: StoryCoverImage(
                  path: cuento.imagenPath,
                  width: 94,
                  height: 94,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cuento.titulo,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: cuento.completado ? 1 : 0.5,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${cuento.paginas.length * 2} min • ${cuento.nivel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.reader,
                arguments: cuento,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Cuento cuento;

  const _RecommendationCard({required this.cuento});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.reader,
        arguments: cuento,
      ),
      child: SizedBox(
        width: 124,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StoryCoverImage(path: cuento.imagenPath, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  cuento.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        height: 1.05,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
