
import 'package:flutter/material.dart';

class MarcadorPulsante extends StatefulWidget {
  final Widget child;
  final Color color;

  const MarcadorPulsante({super.key, required this.child, required this.color});

  @override
  State<MarcadorPulsante> createState() => _MarcadorPulsanteState();
}

class _MarcadorPulsanteState extends State<MarcadorPulsante> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Onda animada (Detrás)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(_opacityAnimation.value),
                ),
              ),
            );
          },
        ),
        // Widget principal (Frente)
        widget.child,
      ],
    );
  }
}
