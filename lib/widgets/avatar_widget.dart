import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String avatar;
  final String nombre;
  final double size;

  const AvatarWidget({
    super.key,
    required this.avatar,
    required this.nombre,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFFFFD54F),
      const Color(0xFF81C784),
      const Color(0xFFFF8A65),
    ];
    final bg = colors[nombre.codeUnitAt(0) % colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: bg, width: 2),
      ),
      child: Center(
        child: Text(avatar, style: TextStyle(fontSize: size * 0.42)),
      ),
    );
  }
}
