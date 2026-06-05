import 'package:flutter/material.dart';

class StarWidget extends StatefulWidget {
  final bool active;
  final double size;

  const StarWidget({super.key, required this.active, this.size = 28});

  @override
  State<StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<StarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.active ? 1.0 + (_controller.value * 0.18) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.star_rounded,
            color:
                widget.active ? const Color(0xFFFFC107) : Colors.grey.shade400,
            size: widget.size,
          ),
        );
      },
    );
  }
}
