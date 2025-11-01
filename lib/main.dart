import 'package:flutter/material.dart';

import 'caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import 'config/temas/app_tema.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xplora Cusco',
      theme: AppTema.temaAzulAventura,
      home: const SplashPagina(),

    );
  }
}
