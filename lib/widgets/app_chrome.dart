import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/cuento.dart';

enum AppTab { home, library, favorites, profile, parent }

class PhoneShell extends StatelessWidget {
  final Widget child;
  final AppTab? selectedTab;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const PhoneShell({
    super.key,
    required this.child,
    this.selectedTab,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
                if (selectedTab != null) AppBottomNav(selected: selectedTab!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final AppTab selected;

  const AppBottomNav({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(AppTab.home, Icons.home_rounded, 'Inicio', AppRoutes.home),
      _NavItem(
        AppTab.library,
        Icons.menu_book_rounded,
        'Biblioteca',
        AppRoutes.library,
      ),
      _NavItem(
        AppTab.profile,
        Icons.person_rounded,
        'Perfil',
        AppRoutes.profileSelection,
      ),
      _NavItem(
        AppTab.parent,
        Icons.family_restroom_rounded,
        'Padres',
        AppRoutes.parentPanel,
      ),
    ];
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final active = item.tab == selected;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (item.route.isEmpty || active) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  item.route,
                  (route) => false,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final AppTab tab;
  final IconData icon;
  final String label;
  final String route;

  const _NavItem(this.tab, this.icon, this.label, this.route);
}

class LogoMark extends StatelessWidget {
  final double size;

  const LogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: size * 0.76,
          ),
          Positioned(
            top: size * 0.03,
            right: size * 0.08,
            child: Icon(
              Icons.star_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: size * 0.42,
            ),
          ),
        ],
      ),
    );
  }
}

class StoryTile extends StatelessWidget {
  final Cuento cuento;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback? onFavoriteTap;

  const StoryTile({
    super.key,
    required this.cuento,
    required this.onTap,
    this.favorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: StoryCoverImage(
                  path: cuento.imagenPath,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cuento.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nivel ${_nivelNumero(cuento.nivel)}  •  ${cuento.paginas.length * 2} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _TinyPill(label: cuento.nivel),
                        if (cuento.completado) const _TinyPill(label: 'Leído'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: favorite ? 'Quitar favorito' : 'Agregar favorito',
                onPressed: onFavoriteTap,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favorite
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _nivelNumero(String nivel) {
    return switch (nivel) {
      'Fácil' => 1,
      'Medio' => 2,
      _ => 3,
    };
  }
}

class StoryCoverImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const StoryCoverImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _CoverFallback(
          width: width,
          height: height,
        ),
      );
    }
    if (path.isEmpty) {
      return _CoverFallback(width: width, height: height);
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _CoverFallback(
        width: width,
        height: height,
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final double? width;
  final double? height;

  const _CoverFallback({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.menu_book_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;

  const _TinyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
