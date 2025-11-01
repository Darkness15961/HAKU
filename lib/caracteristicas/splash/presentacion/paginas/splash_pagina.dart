import 'package:flutter/material.dart';
import '../../../navegacion/presentacion/paginas/navegacion_principal.dart';

/// SplashPagina mejorada (sin blur, con overlay degradado).
class SplashPagina extends StatefulWidget {
  const SplashPagina({super.key});

  @override
  State<SplashPagina> createState() => _SplashPaginaState();
}

class _SplashPaginaState extends State<SplashPagina>
    with SingleTickerProviderStateMixin {
  // ---------- CONFIGURACIÓN (ajústalo si quieres) ----------
  static const String assetFondo = 'assets/logo.webp'; // fondo (ajusta ruta)
  static const String assetLogo = 'assets/log.png'; // logo (ajusta ruta)
  static const String titulo = 'Xplora Cusco';
  static const String subtitulo =
      'Descubre el Valle Sagrado y rutas únicas.'; // cambiado grosor abajo
  static const String botonTexto = 'Comenzar';
  static const String copyright = '© 2025 Xplora Cusco';
  static const int animDurMs = 1400; // duración anim principal (ms)
  // ----------------------------------------------------

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeText;
  late final Animation<Offset> _slideText;

  bool _mostrarBoton = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animDurMs),
    );

    // Scale del logo: 0.92 -> 1.0 con overshoot sutil
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Fade para textos
    _fadeText = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    // Slide para subtítulo (desde abajo)
    _slideText = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Inicia animaciones
    _controller.forward();

    // Mostrar botón luego de la animación principal
    Future.delayed(Duration(milliseconds: animDurMs + 200), () {
      if (mounted) setState(() => _mostrarBoton = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irAlInicio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NavegacionPrincipal()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---------- Fondo (imagen) ----------
          Image.asset(
            assetFondo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ),

          // ---------- Overlay degradado (sin blur) ----------
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.35), // superior (sutil)
                    Color.fromRGBO(0, 0, 0, 0.6), // inferior (más oscuro)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ---------- Contenido central animado ----------
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo con escala animada
                  ScaleTransition(
                    scale: _logoScale,
                    child: Semantics(
                      label: 'Logo Xplora Cusco',
                      child: Image.asset(
                        assetLogo,
                        height: 140,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.explore, size: 140, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Título (aparece con fade)
                  FadeTransition(
                    opacity: _fadeText,
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtítulo (slide + fade) - ahora un poco más grueso
                  SlideTransition(
                    position: _slideText,
                    child: FadeTransition(
                      opacity: _fadeText,
                      child: Text(
                        subtitulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600, // <- un poco más grueso
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Botón principal (aparece con fade)
                  AnimatedOpacity(
                    opacity: _mostrarBoton ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: Semantics(
                      button: true,
                      label: 'Comenzar al menú principal',
                      child: ElevatedButton(
                        onPressed: _mostrarBoton ? _irAlInicio : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 44, vertical: 14),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.black87,
                        ).copyWith(
                          backgroundColor:
                          MaterialStateProperty.all(Colors.transparent),
                          elevation: MaterialStateProperty.all(10),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorPrimario,
                                colorPrimario.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(
                                minWidth: 160, minHeight: 44),
                            child: Text(
                              botonTexto,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Pie / copyright ----------
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                copyright,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
