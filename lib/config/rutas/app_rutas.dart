// ... imports ... (los mismos de siempre)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart' as mapa_vm;
// ... imports de entidades y paginas ...
import 'package:xplore_cusco/caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/login_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/registro_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/recuperar_contrasena_pagina.dart';
import 'package:xplore_cusco/caracteristicas/navegacion/presentacion/paginas/navegacion_principal.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/inicio_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/provincia_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/detalle_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/comentarios_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/rutas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/detalle_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_sin_guia_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_simple_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/crear_hakuparada_pagina.dart'; // 👈 NUEVO IMPORT
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/perfil_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_favoritos_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_rutas_inscritas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/ajustes_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/ajustes_cuenta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_publicados_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_hakuparadas_pagina.dart'; // 👈 NUEVO IMPORT
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/historial_rutas_pagina.dart'; // 👈 NUEVO IMPORT
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/solicitar_guia_pagina.dart';
import 'package:xplore_cusco/caracteristicas/notificaciones/presentacion/paginas/notificaciones_pagina.dart';
import 'package:xplore_cusco/caracteristicas/solicitudes/presentacion/paginas/turista/mis_solicitudes_pagina.dart';
import 'package:xplore_cusco/caracteristicas/solicitudes/presentacion/paginas/guia/solicitudes_disponibles_pagina.dart';
import 'package:xplore_cusco/caracteristicas/solicitudes/presentacion/paginas/guia/mis_postulaciones_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_guias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_cuentas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_contenido_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_provincias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_provincia_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/selector_ubicacion_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_hakuparadas_pagina.dart'; // 👈 NUEVO IMPORT

import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/rutas/dominio/entidades/ruta.dart';


final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ShellKey');

class AppRutas {
  static final router = GoRouter(
    navigatorKey: mapa_vm.navigatorKey,
    initialLocation: '/',
    routes: [
      // ... RUTAS SIMPLES (Splash, Login, etc) ...
      GoRoute(path: '/', builder: (context, state) => SplashPagina()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPagina()),
      GoRoute(path: '/registro', builder: (context, state) => const RegistroPagina()),
      GoRoute(path: '/recuperar-contrasena', builder: (context, state) => const RecuperarContrasenaPage()),
      GoRoute(path: '/panel-admin', builder: (context, state) => const AdminDashboardPagina()),
      GoRoute(path: '/admin/gestion-guias', builder: (context, state) => const AdminGestionGuiasPagina()),
      GoRoute(path: '/admin/gestion-cuentas', builder: (context, state) => const AdminGestionCuentasPagina()),
      GoRoute(path: '/admin/gestion-contenido', builder: (context, state) => const AdminGestionContenidoPagina()),
      GoRoute(path: '/admin/gestion-lugares', builder: (context, state) => const AdminGestionLugaresPagina()),
      GoRoute(path: '/admin/crear-lugar', builder: (context, state) { final lugar = state.extra as Lugar?; return AdminCrearLugarPagina(lugar: lugar); }),
      GoRoute(path: '/admin/gestion-provincias', builder: (context, state) => const AdminGestionProvinciasPagina()),
      GoRoute(path: '/admin/crear-provincia', builder: (context, state) { final provincia = state.extra as Provincia?; return AdminCrearProvinciaPagina(provincia: provincia); }),
      GoRoute(path: '/admin/selector-ubicacion', builder: (context, state) { final LatLng? ubicacionInicial = state.extra as LatLng?; return SelectorUbicacionPagina(ubicacionInicial: ubicacionInicial); }),
      GoRoute(path: '/admin/gestion-hakuparadas', builder: (context, state) => const AdminGestionHakuparadasPagina()), // 👈 NUEVA RUTA
      GoRoute(path: '/mapa-lugar', builder: (context, state) { final lugar = state.extra as Lugar; return MapaSimplePagina(lugar: lugar); }),
      GoRoute(path: '/notificaciones', builder: (context, state) => const NotificacionesPagina()),

      // SHELL (BARRA INFERIOR)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavegacionPrincipal(child: child);
        },
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => const InicioPagina(),
            routes: [
              GoRoute(path: 'provincia', builder: (context, state) => ProvinciaLugaresPagina(provincia: state.extra as Provincia)),
              GoRoute(path: 'detalle-lugar', builder: (context, state) => DetalleLugarPagina(lugar: state.extra as Lugar)),
              GoRoute(path: 'comentarios', builder: (context, state) => ComentariosPagina(lugar: state.extra as Lugar)),
            ],
          ),
          GoRoute(
            path: '/rutas',
            builder: (context, state) => const RutasPagina(),
            routes: [
              GoRoute(path: 'detalle-ruta', builder: (context, state) => DetalleRutaPagina(ruta: state.extra as Ruta)),
              GoRoute(path: 'crear-ruta', builder: (context, state) => CrearRutaPagina(ruta: state.extra as Ruta?)),
              GoRoute(path: 'crear-sin-guia', builder: (context, state) => CrearRutaSinGuiaPagina(ruta: state.extra as Ruta?)),
            ],
          ),

          // ESTA ES LA RUTA MÁGICA QUE FALTABA
          GoRoute(
            path: '/lugares',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              GoRoute(
                path: 'detalle-lugar',
                builder: (context, state) {
                  if (state.extra is Lugar) {
                    return DetalleLugarPagina(lugar: state.extra as Lugar);
                  } else {
                    // Ahora esto es válido porque DetalleLugarPagina tiene 'lugarId'
                    return DetalleLugarPagina(lugarId: state.extra as String);
                  }
                },
              ),
            ],
          ),

          GoRoute(path: '/mapa', builder: (context, state) => const MapaPagina()),
          GoRoute(path: '/crear-hakuparada', builder: (context, state) => const CrearHakuparadaPagina()), // 👈 NUEVA RUTA
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilPagina(),
            routes: [
              GoRoute(path: 'solicitar-guia', builder: (context, state) => const SolicitarGuiaPagina()),
              GoRoute(path: 'mis-favoritos', builder: (context, state) => const MisLugaresFavoritosPagina()),
              GoRoute(path: 'mis-rutas', builder: (context, state) => const MisRutasInscritasPagina()),
              GoRoute(path: 'ajustes', builder: (context, state) => const AjustesPagina()),
              GoRoute(path: 'ajustes-cuenta', builder: (context, state) => const AjustesCuentaPagina()),
              GoRoute(path: 'mis-lugares-publicados', builder: (context, state) => const MisLugaresPublicadosPagina()),
              GoRoute(path: 'mis-hakuparadas', builder: (context, state) => const MisHakuparadasPagina()), // 👈 NUEVA RUTA
              GoRoute(path: 'mis-solicitudes', builder: (context, state) => const MisSolicitudesPagina()),
              GoRoute(path: 'solicitudes-disponibles', builder: (context, state) => const SolicitudesDisponiblesPagina()),
              GoRoute(path: 'mis-postulaciones', builder: (context, state) => const MisPostulacionesPagina()),
              GoRoute(path: 'historial-rutas', builder: (context, state) => const HistorialRutasPagina()), // 👈 NUEVA RUTA
            ],
          ),
        ],
      ),
    ],
  );
}
