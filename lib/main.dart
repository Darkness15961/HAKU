// --- PUNTO DE ENTRADA PRINCIPAL DE LA APP ---
//
// Esta es la versión corregida.
// Simplificamos TODOS los providers.
// Los ViewModels se crean "tontos" y las Páginas
// (como RutasPagina) se encargan de "despertarlos".

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
        ChangeNotifierProvider(
          create: (_) => LugaresVM(),
        ),

        // --- CONTRATO 2: "Mesero de Seguridad" ---
        ChangeNotifierProvider(
          create: (_) => AutenticacionVM(),
        ),

        // --- CONTRATO 3: "Mesero de Rutas" (¡CORREGIDO!) ---
        // Se crea "tonto". La RutasPagina lo "despierta".
        // Esto corrige el error: "1 positional argument expected..."
        // porque coincide con el constructor RutasVM() de tu archivo.
        ChangeNotifierProvider(
          create: (context) => RutasVM(),
        ),

        // --- CONTRATO 4: "Mesero de Mapa" (¡CORREGIDO!) ---
        // Ya no usamos ProxyProvider2.
        // Se crea "tonto". La MapaPagina lo "despertará".
        // Esto corrige el error: "'actualizarDependencias' isn't defined..."
        ChangeNotifierProvider(
          create: (context) => MapaVM(),
        ),
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