import 'package:get_it/get_it.dart';

// --- IMPLEMENTACIONES REALES (SUPABASE) ---
import 'caracteristicas/inicio/datos/repositorios/lugares_repositorio_supabase.dart';
import 'caracteristicas/autenticacion/datos/repositorios/autenticacion_repositorio_supabase.dart';
import 'caracteristicas/rutas/datos/repositorios/rutas_repositorio_supabase.dart';

// --- CONTRATOS (INTERFACES) ---
import 'caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart';
import 'caracteristicas/autenticacion/dominio/repositorios/autenticacion_repositorio.dart';
import 'caracteristicas/rutas/dominio/repositorios/rutas_repositorio.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // 1. LUGARES (Conectado a Supabase)
  getIt.registerLazySingleton<LugaresRepositorio>(
    () => LugaresRepositorioSupabase(),
  );

  // 2. AUTENTICACIÓN (Conectado a Supabase)
  getIt.registerLazySingleton<AutenticacionRepositorio>(
    () => AutenticacionRepositorioSupabase(),
  );

  // 3. RUTAS (Conectado a Supabase)
  getIt.registerLazySingleton<RutasRepositorio>(
    () => RutasRepositorioSupabase(),
  );
}