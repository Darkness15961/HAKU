import 'dart:async';
import 'package:flutter/material.dart';
import '../../dominio/entidades/ruta.dart';

class RutaAccionCard extends StatefulWidget {
  final Ruta ruta;
  final bool esGuia;
  final VoidCallback onIniciar;
  final VoidCallback onFinalizar;
  final VoidCallback onMarcarAsistencia; // Para el turista (futuro)

  const RutaAccionCard({
    super.key,
    required this.ruta,
    required this.esGuia,
    required this.onIniciar,
    required this.onFinalizar,
    required this.onMarcarAsistencia,
  });

  @override
  State<RutaAccionCard> createState() => _RutaAccionCardState();
}

class _RutaAccionCardState extends State<RutaAccionCard> with SingleTickerProviderStateMixin {
  // Lógica de Deslizar
  double _dragValue = 0.0;
  // final double _maxWidth = 300.0; // Removed unused
  bool _isDragging = false;
  bool _completed = false;

  // Lógica de Timer (En Curso)
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.ruta.estado == 'en_curso') {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(RutaAccionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ruta.estado != 'en_curso' && widget.ruta.estado == 'en_curso') {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // Si NO es guía, no mostramos controles de ESTADO (salvo asistencia futura)
    if (!widget.esGuia) return const SizedBox.shrink();

    if (widget.ruta.estado == 'convocatoria') {
      return _buildSlideToStart();
    } else if (widget.ruta.estado == 'en_curso') {
      return _buildLiveCard();
    } else if (widget.ruta.estado == 'finalizada') {
      return _buildFinishedCard();
    }

    // Default / Cancelada
    return const SizedBox.shrink();
  }

  Widget _buildSlideToStart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag = constraints.maxWidth - 55; // 55 ancho del thumb
          
          return Stack(
            children: [
              // TEXTO FONDO
              Center(
                child: Opacity(
                  opacity: _isDragging ? 0.5 : 1.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "DESLIZAR PARA INICIAR",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),

              // THUMB DESLIZABLE
              Positioned(
                left: _dragValue,
                top: 5,
                bottom: 5,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > maxDrag) _dragValue = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragValue >= maxDrag * 0.9) {
                      // COMPLETADO
                      setState(() {
                         _dragValue = maxDrag;
                         _completed = true;
                      });
                      widget.onIniciar();
                    } else {
                      // RESET
                      setState(() {
                        _dragValue = 0;
                        _isDragging = false;
                      });
                    }
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    margin: const EdgeInsets.only(left: 5), // padding visual
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _completed 
                      ? const Icon(Icons.check, color: Colors.green, size: 30)
                      : const Icon(Icons.rocket_launch, color: Colors.green),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  bool _isMinimized = false;

  // Lógica de Timer (En Curso)

  // ... existing code ...

  Widget _buildLiveCard() {
    final tiempoTranscurrido = _formatDuration(_elapsed);

    if (_isMinimized) {
      return GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade900,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 10),
                  const Text("EN CURSO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                   Text(tiempoTranscurrido, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
              const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade800, Colors.deepOrange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildPulsingDot(),
                  const SizedBox(width: 10),
                  const Text(
                    "EN CURSO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () => setState(() => _isMinimized = true),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          
          // Timer Widget
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(tiempoTranscurrido, style: const TextStyle(color: Colors.white, fontSize: 14, fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Tu ubicación es visible para los participantes rezagados.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onFinalizar,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text("FINALIZAR RECORRIDO", style: TextStyle(color: Colors.red)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade700], // Gradiente Dorado/Naranja Vibrante
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.2), 
               shape: BoxShape.circle,
               border: Border.all(color: Colors.white, width: 2)
             ),
             child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   "¡RUTA COMPLETADA!", 
                   style: TextStyle(
                     fontWeight: FontWeight.w900, 
                     fontSize: 18, 
                     color: Colors.white, 
                     letterSpacing: 1.0,
                     shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
                   )
                 ),
                 const SizedBox(height: 4),
                 Text(
                   "Has guiado esta experiencia con éxito.\n¡Buen trabajo!", 
                   style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13, height: 1.3)
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
           BoxShadow(color: Colors.redAccent.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)
        ]
      ),
    );
  }
}
