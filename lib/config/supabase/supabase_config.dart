// lib/config/supabase/supabase_config.dart

/// Configuración de Supabase para Xplora Cusco
class SupabaseConfig {
  // URL del proyecto Supabase
  static const String supabaseUrl = 'https://fnedjdwdtidqspshovjn.supabase.co';
  
  // Anon Key (clave pública)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZuZWRqZHdkdGlkcXNwc2hvdmpuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzOTkxNjAsImV4cCI6MjA3ODk3NTE2MH0.1RkK6p-SvQP28BqOJkwtJcwC5ScSUbP7Zh8j6J5VDWs';
  
  // Nombres de las tablas en Supabase
  static const String tableLugares = 'lugares';
  static const String tableUsuarios = 'usuarios';
  static const String tableRutas = 'rutas';
  static const String tableComentarios = 'comentarios';
  static const String tableFavoritos = 'favoritos';
  static const String tableInscripciones = 'inscripciones';
  static const String tableNotificaciones = 'notificaciones';
  
  // Nombres de los buckets de Storage
  static const String bucketLugares = 'lugares';
  static const String bucketUsuarios = 'usuarios';
  static const String bucketRutas = 'rutas';
}
