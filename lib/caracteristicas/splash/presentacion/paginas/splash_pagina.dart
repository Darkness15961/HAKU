// lib/caracteristicas/splash/presentacion/paginas/splash_pagina.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPagina extends StatefulWidget {
  const SplashPagina({super.key});

  @override
  State<SplashPagina> createState() => _SplashPaginaState();
}

class _SplashPaginaState extends State<SplashPagina>
    with SingleTickerProviderStateMixin {
  static const String assetFondo = 'assets/logo.webp';
  static const String assetLogo = 'assets/logoHaku1.png';

  // --- REBRANDING HAKU ---
  static const String titulo = 'HAKU';
  static const String subtitulo = 'Redescubriendo nuestra cultura milenaria';
  static const String botonTexto = 'VAMOS';

  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _mostrarBoton = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    // Mostrar botón poco después de terminar la animación principal
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _mostrarBoton = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _irAlInicio() {
    if (mounted) {
      context.pushReplacement('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Image.asset(
            assetFondo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ),

          // Overlay degradado para contraste
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenido centrado (icono + textos + botón)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo de la app
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Image.asset(
                        assetLogo,
                        height: 120,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.explore, size: 120, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  AnimatedOpacity(
                    opacity: _mostrarBoton ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: _mostrarBoton ? _irAlInicio : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        backgroundColor: colorPrimario,
                        foregroundColor: Colors.white,
                        shadowColor: colorPrimario.withValues(alpha: 0.6),
                      ),
                      child: Text(
                        botonTexto,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pie pequeño
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '© HAKU Travel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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
