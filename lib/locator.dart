// --- PIEDRA 3 (CONECTOR): LA "CENTRAL DE CONEXIONES" ---
//
// Esta es la versión ACTUALIZADA de nuestra "Central".
// Le hemos "enseñado" a "conectar" el nuevo
// "Enchufe de Rutas" a la "Cocina Falsa de Rutas".

import 'package:get_it/get_it.dart';

// --- Importaciones del Menú 1 (Inicio) ---
import 'caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart';
import 'caracteristicas/inicio/datos/repositorios/lugares_repositorio_mock.dart';

// --- Importaciones de Autenticación ---
import 'caracteristicas/autenticacion/dominio/repositorios/autenticacion_repositorio.dart';
import 'caracteristicas/autenticacion/datos/repositorios/autenticacion_repositorio_mock.dart';

// --- ¡NUEVAS IMPORTACIONES! (Paso 4 - Rutas) ---
// 1. Importamos el "Enchufe" (Repositorio) del MENÚ 2 (Rutas)
import 'caracteristicas/rutas/dominio/repositorios/rutas_repositorio.dart';
// 2. Importamos la "Cocina Falsa" (Mock) del MENÚ 2 (Rutas)
import 'caracteristicas/rutas/datos/repositorios/rutas_repositorio_mock.dart';
// --- FIN DE NUEVAS IMPORTACIONES ---

// Creamos la "instancia" (la caja) de nuestra Central
final getIt = GetIt.instance;

// Esta es la función que "enciende" la central
// (La llamamos desde main.dart)
void setupLocator() {
  // --- Conexión 1: "Enchufe" de Lugares (El que ya teníamos) ---
  getIt.registerLazySingleton<LugaresRepositorio>(
        () => LugaresRepositorioMock(),
  );

  // --- Conexión 2: "Enchufe" de Autenticación (El que ya teníamos) ---
  getIt.registerLazySingleton<AutenticacionRepositorio>(
        () => AutenticacionRepositorioMock(),
  );

  // --- ¡NUEVA CONEXIÓN! (Paso 4 - Rutas) ---
  //
  // --- Conexión 3: "Enchufe" de Rutas ---
  //
  // "Cuando alguien pida el 'Enchufe' de Rutas..."
  getIt.registerLazySingleton<RutasRepositorio>(
    // "...dale la 'Cocina Falsa' de Rutas."
    // (Esta es la cocina que acabamos de crear)
        () => RutasRepositorioMock(),
  );
  // --- FIN DE LA NUEVA CONEXIÓN ---
}

