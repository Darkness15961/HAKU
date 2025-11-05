// --- PUNTO DE ENTRADA PRINCIPAL DE LA APP ---
//
// Esta es la versión FINAL de tu main.dart.
// Le hemos "presentado" al nuevo "Mesero de Mapa" (MapaVM)
// a nuestro "Gerente" (MultiProvider).

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

// 4. --- ¡NUEVA IMPORTACIÓN! (Paso 2 - Bloque 5) ---
//    Importamos el "Mesero de Mapa" (el que está en el Canvas)
import 'caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart';
// --- FIN DE NUEVA IMPORTACIÓN ---

// "void main()" es lo primero que se ejecuta
void main() {
  // "Encendemos" la "Central de Conexiones" (GetIt)
  setupLocator();

  // "Corremos" la aplicación
  runApp(
    // "MultiProvider" es el "Gerente"
    MultiProvider(
      providers: [
        // --- CONTRATO 1: "Mesero de Comida" ---
        // (Debe ir ANTES del "Proxy" de Mapa)
        ChangeNotifierProvider(
          create: (_) => LugaresVM(),
        ),

        // --- CONTRATO 2: "Mesero de Seguridad" ---
        // (Debe ir ANTES de Rutas y Mapa)
        ChangeNotifierProvider(
          create: (_) => AutenticacionVM(),
        ),

        // --- CONTRATO 3: "Mesero de Rutas" (Depende de Auth) ---
        ChangeNotifierProxyProvider<AutenticacionVM, RutasVM>(
          // 1. "create": Crea una instancia "base"
          create: (context) => RutasVM(null),

          // 2. "update": Se ejecuta cuando AuthVM cambia
          update: (
              context,
              authVM, // <-- Nos da el "Mesero de Seguridad"
              previousRutasVM,
              ) {
            // 3. Le "pasamos" el Mesero de Seguridad al Mesero de Rutas
            return RutasVM(authVM);
          },
        ),

        // --- ¡NUEVO CONTRATO! (Paso 2 - Bloque 5) ---
        //
        // --- CONTRATO 4: "Mesero de Mapa" (Depende de Lugares y Auth) ---
        //
        // Usamos "ChangeNotifierProxyProvider2"
        // (porque "escucha" a 2 "Meseros": LugaresVM y AutenticacionVM)
        ChangeNotifierProxyProvider2<LugaresVM, AutenticacionVM, MapaVM>(
          // 1. Crea la instancia base
          create: (context) => MapaVM(null, null),

          // 2. "update": Se actualiza cada vez que
          //    LugaresVM o AuthVM cambian
          update: (
              context,
              lugaresVM, // <-- Nos da el "Mesero de Comida"
              authVM, // <-- Nos da el "Mesero de Seguridad"
              previousMapaVM,
              ) {
            // 3. Retornamos el "Mesero de Mapa",
            //    pasándole los otros dos "Meseros"
            //    para que pueda "escucharlos"
            return MapaVM(lugaresVM, authVM);
          },
        ),
        // --- FIN DEL NUEVO CONTRATO ---
      ],
      child: const MyApp(),
    ),
  );
}

// "MyApp" es el widget raíz
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRutas.router,
      debugShowCheckedModeBanner: false,
      title: 'Xplora Cusco',
      theme: AppTema.temaAzulAventura,
    );
  }
}