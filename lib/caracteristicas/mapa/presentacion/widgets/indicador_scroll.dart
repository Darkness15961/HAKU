import 'package:flutter/material.dart';
import 'dart:ui';

/// Widget que añade indicadores visuales (flechas o gradiente)
/// cuando el contenido de un ScrollView es más grande que el contenedor visible.
class IndicadorScroll extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final Axis scrollDirection;
  final bool showArrows;
  final bool showGradient;

  const IndicadorScroll({
    super.key,
    required this.child,
    required this.scrollController,
    this.scrollDirection = Axis.horizontal,
    this.showArrows = true,
    this.showGradient = true,
  });

  @override
  State<IndicadorScroll> createState() => _IndicadorScrollState();
}

class _IndicadorScrollState extends State<IndicadorScroll> {
  bool _canScrollStart = false;
  bool _canScrollEnd = true; // Asumimos true inicial hasta que se verifique

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_checkScrollability);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkScrollability);
    super.dispose();
  }

  void _checkScrollability() {
    if (!widget.scrollController.hasClients) return;

    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.offset;

    // Pequeño margen de tolerancia
    final canStart = currentScroll > 1.0;
    final canEnd = currentScroll < maxScroll - 1.0;

    if (canStart != _canScrollStart || canEnd != _canScrollEnd) {
      setState(() {
        _canScrollStart = canStart;
        _canScrollEnd = canEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Indicador Inicio (Izquierda/Arriba)
        if (_canScrollStart && widget.showArrows)
          Positioned(
            left: widget.scrollDirection == Axis.horizontal ? 0 : null,
            top: widget.scrollDirection == Axis.vertical ? 0 : 0,
            bottom: widget.scrollDirection == Axis.horizontal ? 0 : null,
            right: widget.scrollDirection == Axis.vertical ? 0 : null,
            child: _buildArrow(
              icon: widget.scrollDirection == Axis.horizontal 
                  ? Icons.chevron_left 
                  : Icons.keyboard_arrow_up,
              onTap: () {
                 widget.scrollController.animateTo(
                  widget.scrollController.offset - 200, // Aumentado para mayor desplazamiento
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeOut
                );
              }
            ),
          ),

        // Indicador Final (Derecha/Abajo)
        if (_canScrollEnd && widget.showArrows)
          Positioned(
            right: widget.scrollDirection == Axis.horizontal ? 0 : null,
            bottom: widget.scrollDirection == Axis.vertical ? 0 : 0,
            top: widget.scrollDirection == Axis.horizontal ? 0 : null,
            left: widget.scrollDirection == Axis.vertical ? 0 : null,
            child: _buildArrow(
              icon: widget.scrollDirection == Axis.horizontal 
                  ? Icons.chevron_right 
                  : Icons.keyboard_arrow_down,
              onTap: () {
                // Aumentamos el desplazamiento a 200 para que se sienta que avanza
                // un elemento completo (aprox ancho de tarjeta o varios chips).
                widget.scrollController.animateTo(
                  widget.scrollController.offset + 200, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeOut
                );
              }
            ),
          ),
      ],
    );
  }

  Widget _buildArrow({required IconData icon, required VoidCallback onTap}) {
    // DISEÑO SENIOR / PREMIUM:
    // Evitamos el "efecto niebla" (blur) que puede verse sucio.
    // Usamos el estándar de industria (Airbnb, Maps, Uber): Blanco PURO sólido + Sombra difusa de alta calidad.
    // Esto garantiza legibilidad y sensación de "limpieza".
    
    return Padding(
      padding: const EdgeInsets.all(6.0), // Un poco más de aire
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36, // Tamaño touch-friendly ideal
          decoration: BoxDecoration(
            color: Colors.white, // Blanco sólido, NO transparente
            shape: BoxShape.circle,
            boxShadow: [
              // Sombra doble para elevación realista "premium"
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 4, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            // Borde sutilísimo para definición contra fondos claros
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[800]), // Gris oscuro suave, no negro puro
        ),
      ),
    );
  }
}
