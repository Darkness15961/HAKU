// --- PUNTO DE ENTRADA PRINCIPAL DE LA APP (VERSIÓN FINAL) ---
//
// 1. (CORREGIDO): Se eliminó la línea '..routerDelegate.navigatorKey'
//    que causaba el error.
// 2. Se mantiene el ProxyProvider3 para el MapaVM.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Importamos el "GPS" (GoRouter)
import 'package:xplore_cusco/config/rutas/app_rutas.dart';
// 2. Importamos el "Tema" (Diseño)
import 'config/temas/app_tema.dart';
// 3. Importamos el "Conector" (GetIt)
import 'package:xplore_cusco/locator.dart';

// --- IMPORTACIONES DE "MESEROS" (VIEWMODELS) ---
import 'caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'caracteristicas/rutas/presentacion/vista_modelos/rutas_vm.dart';
import 'caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart';
// (Ya no necesitamos la importación 'as mapa_vm')


void main() {
  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        // --- CONTRATO 1: "Mesero de Comida" ---
        ChangeNotifierProvider(
          create: (_) => LugaresVM(),
        ),

        // --- CONTRATO 2: "Mesero de Seguridad" (Cerebro) ---
        ChangeNotifierProvider(
          create: (_) => AutenticacionVM(),
        ),

        // --- CONTRATO 3: "Mesero de Rutas" ---
        ChangeNotifierProvider(
          create: (context) => RutasVM(),
        ),

        // --- CONTRATO 4: "Mesero de Mapa" ---
        // (Esta es la "Super-Conexión" que necesitas)
        ChangeNotifierProxyProvider3<LugaresVM, AutenticacionVM, RutasVM, MapaVM>(
          create: (context) => MapaVM(),
          update: ( context, lugaresVM, authVM, rutasVM, previousMapaVM) {
            return (previousMapaVM ?? MapaVM())
              ..actualizarDependencias(lugaresVM, authVM, rutasVM);
          },
        ),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      // Simplemente usamos el router como antes.
      // La 'navigatorKey' se configurará DENTRO de AppRutas.
      routerConfig: AppRutas.router,
      // --- FIN DE CORRECCIÓN ---

      debugShowCheckedModeBanner: false,
      title: 'Xplora Cusco',
      theme: AppTema.temaAzulAventura,
    );
  }
}