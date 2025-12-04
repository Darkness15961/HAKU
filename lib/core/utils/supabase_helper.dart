// lib/core/utils/supabase_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper para acceder fácilmente al cliente de Supabase
class SupabaseHelper {
  // Instancia del cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;
  
  // Acceso rápido a Auth
  static GoTrueClient get auth => client.auth;
  
  // Acceso rápido a Storage
  static SupabaseStorageClient get storage => client.storage;
  
  // Usuario actual (si está logueado)
  static User? get currentUser => auth.currentUser;
  
  // ID del usuario actual
  static String? get currentUserId => currentUser?.id;
  
  // Email del usuario actual
  static String? get currentUserEmail => currentUser?.email;
  
  // Verificar si hay un usuario logueado
  static bool get isLoggedIn => currentUser != null;
}
