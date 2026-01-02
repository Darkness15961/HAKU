import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Configuración y Rutas
import 'package:xplore_cusco/config/rutas/app_rutas.dart';
import 'config/temas/app_tema.dart';
import 'package:xplore_cusco/config/supabase/supabase_config.dart';
import 'package:xplore_cusco/locator.dart';

// ViewModels
import 'caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'caracteristicas/rutas/presentacion/vista_modelos/rutas_vm.dart';
import 'caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart';
import 'caracteristicas/notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';
import 'caracteristicas/solicitudes/presentacion/vista_modelos/solicitudes_vm.dart';

// Notificaciones (Repositorios y Casos de Uso)
import 'caracteristicas/notificaciones/dominio/repositorios/notificacion_repositorio.dart';
import 'caracteristicas/notificaciones/datos/repositorios/notificacion_repositorio_mock.dart';
import 'caracteristicas/notificaciones/dominio/casos_uso/obtener_notificaciones.dart';
import 'caracteristicas/notificaciones/dominio/casos_uso/marcar_notificacion_leida.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,

    // Configuración obligatoria para OAuth en Android
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  setupLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LugaresVM()),
        ChangeNotifierProvider(create: (_) => AutenticacionVM()),
        ChangeNotifierProvider(create: (context) => RutasVM()),
        ChangeNotifierProvider(create: (_) => SolicitudesVM()),

        ChangeNotifierProxyProvider3<
          LugaresVM,
          AutenticacionVM,
          RutasVM,
          MapaVM
        >(
          create: (context) => MapaVM(),
          update: (context, lugaresVM, authVM, rutasVM, previousMapaVM) {
            return (previousMapaVM ?? MapaVM())
              ..actualizarDependencias(lugaresVM, authVM, rutasVM);
          },
        ),

        // Notificaciones
        Provider<NotificacionRepositorio>(
          create: (_) => NotificacionRepositorioMock(),
        ),
        Provider<ObtenerNotificaciones>(
          create: (context) =>
              ObtenerNotificaciones(context.read<NotificacionRepositorio>()),
        ),
        Provider<MarcarNotificacionLeida>(
          create: (context) =>
              MarcarNotificacionLeida(context.read<NotificacionRepositorio>()),
        ),
        ChangeNotifierProvider<NotificacionesVM>(
          create: (context) => NotificacionesVM(
            obtenerNotificaciones: context.read<ObtenerNotificaciones>(),
            marcarNotificacionLeida: context.read<MarcarNotificacionLeida>(),
          ),
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
      routerConfig: AppRutas.router,
      debugShowCheckedModeBanner: false,
      title: 'HAKU',
      theme: AppTema.temaHaku,
    );
  }
}
