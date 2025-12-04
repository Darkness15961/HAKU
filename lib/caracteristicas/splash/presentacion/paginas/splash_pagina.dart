// lib/caracteristicas/splash/presentacion/paginas/splash_pagina.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPagina extends StatefulWidget {
  const SplashPagina({super.key});

  @override
  State<SplashPagina> createState() => _SplashPaginaState();
}

class _SplashPaginaState extends State<SplashPagina> with SingleTickerProviderStateMixin {
  static const String assetFondo = 'assets/logo.webp';
  static const String assetLogo = 'assets/log.png';
  
  // --- REBRANDING HAKU ---
  static const String titulo = 'HAKU';
  static const String subtitulo = 'Redescubriendo el Cusco';
  static const String botonTexto = 'Vamos';

  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _mostrarBoton = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

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

          // Overlay degradado para contraste (Más dramático para HAKU)
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

          // Contenido centrado (logo + textos + botón)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimario.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          assetLogo,
                          height: 140,
                          errorBuilder: (_, __, ___) => Icon(Icons.travel_explore, size: 120, color: colorPrimario),
                        ),
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
                        fontFamily: 'Montserrat', // Ideal si se agrega, sino usa default
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
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                        backgroundColor: colorPrimario,
                        foregroundColor: Colors.white,
                        shadowColor: colorPrimario.withValues(alpha: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            botonTexto.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pie pequeño (Actualizado)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: Text('© HAKU Travel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
          ),
        ],
      ),
    );
  }
}