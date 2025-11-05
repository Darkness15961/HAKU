// lib/caracteristicas/splash/presentacion/paginas/splash_pagina.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <-- 1. IMPORTANTE: Importar Go_Router

class SplashPagina extends StatefulWidget {
  const SplashPagina({super.key});

  @override
  State<SplashPagina> createState() => _SplashPaginaState();
}

class _SplashPaginaState extends State<SplashPagina> with SingleTickerProviderStateMixin {
  static const String assetFondo = 'assets/logo.webp';
  static const String assetLogo = 'assets/log.png';
  static const String titulo = 'Xplora Cusco';
  static const String subtitulo = 'Descubre el Valle Sagrado y rutas únicas.';
  static const String botonTexto = 'Comenzar';

  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _mostrarBoton = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    // Mostrar botón poco después de terminar la animación principal
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _mostrarBoton = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _irAlInicio() {
    // 2. CAMBIO CLAVE: Usamos Go_Router para navegar por la ruta
    // que definimos en app_rutas.dart.
    if (mounted) {
      context.pushReplacement('/navegacion');
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(0, 0, 0, 0.28),
                  Color.fromRGBO(0, 0, 0, 0.62),
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
                      child: Image.asset(
                        assetLogo,
                        height: 120,
                        errorBuilder: (_, __, ___) => const Icon(Icons.explore, size: 120, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 30),

                  AnimatedOpacity(
                    opacity: _mostrarBoton ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: _mostrarBoton ? _irAlInicio : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                        backgroundColor: colorPrimario,
                      ),
                      child: Text(botonTexto, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
            child: Center(child: Text('© Xplora Cusco', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))),
          ),
        ],
      ),
    );
  }
}
