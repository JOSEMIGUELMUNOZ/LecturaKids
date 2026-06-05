import 'package:flutter/material.dart';

import '../models/cuento.dart';
import 'star_widget.dart';

class CuentoCard extends StatelessWidget {
  final Cuento cuento;
  final VoidCallback onTap;

  const CuentoCard({super.key, required this.cuento, required this.onTap});

  Color _colorForStory(BuildContext context) {
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFFFFD54F),
      const Color(0xFF81C784),
      const Color(0xFFFF8A65),
      const Color(0xFF7986CB),
      const Color(0xFF4DB6AC),
    ];
    return colors[cuento.id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStory(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 118,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  image: cuento.imagenPath.isEmpty
                      ? null
                      : DecorationImage(
                          image: AssetImage(cuento.imagenPath),
                          fit: BoxFit.cover,
                        ),
                  gradient: cuento.imagenPath.isEmpty
                      ? LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.85),
                            color.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.18),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.16),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          cuento.nivel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (cuento.imagenPath.isEmpty)
                      const Positioned.fill(
                        child: Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: cuento.completado
                            ? Container(
                                key: const ValueKey('done'),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.24),
                                  shape: BoxShape.circle,
                                ),
                                child: const StarWidget(active: true, size: 24),
                              )
                            : const SizedBox.shrink(key: ValueKey('pending')),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cuento.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cuento.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cuento.edadMin}-${cuento.edadMax} años',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        Text(
                          '${cuento.estrellasGanadas} estrellas',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.amber.shade700,
                                    fontSize: 14,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
