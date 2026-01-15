import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xplore_cusco/caracteristicas/mapa/datos/modelos/hakuparada_model.dart';
import 'package:xplore_cusco/caracteristicas/mapa/dominio/entidades/hakuparada.dart';

class AdminHakuparadasVM extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  String? _error;

  List<Hakuparada> _pendientes = [];
  List<Hakuparada> _verificadas = [];

  // Getters
  bool get estaCargando => _estaCargando;
  String? get error => _error;
  List<Hakuparada> get pendientes => _pendientes;
  List<Hakuparada> get verificadas => _verificadas;

  // Constructor
  AdminHakuparadasVM() {
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Cargar Pendientes
      final responsePendientes = await _supabase
          .from('hakuparadas')
          .select()
          .eq('verificado', false)
          .order('created_at', ascending: false);
      
      _pendientes = (responsePendientes as List)
          .map((json) => HakuparadaModel.fromJson(json))
          .toList();

      // 2. Cargar Verificadas (Limitamos a las ultimas 50 para no explotar)
      final responseVerificadas = await _supabase
          .from('hakuparadas')
          .select()
          .eq('verificado', true)
          .order('created_at', ascending: false)
          .limit(50);

      _verificadas = (responseVerificadas as List)
          .map((json) => HakuparadaModel.fromJson(json))
          .toList();

    } catch (e) {
      _error = "Error cargando listas: $e";
      print("Error AdminHakuparadas: $e");
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- ACCIONES ---

  Future<void> aprobarHakuparada(int id) async {
    _estaCargando = true;
    notifyListeners();
    try {
      await _supabase
          .from('hakuparadas')
          .update({'verificado': true})
          .eq('id', id);
      
      // Recargar localmente para actualizar UI
      await cargarDatos();
      
    } catch (e) {
      _error = "Error al aprobar: $e";
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> toggleVisibilidad(int id, bool estadoActual) async {
    // Optimistic update (opcional, pero aquí recargamos por seguridad)
    _estaCargando = true;
    notifyListeners();
    try {
      await _supabase
          .from('hakuparadas')
          .update({'visible': !estadoActual})
          .eq('id', id);
      
      await cargarDatos(); // Recargar para ver cambio
      
    } catch (e) {
      _error = "Error al cambiar visibilidad: $e";
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarHakuparada(int id) async {
    _estaCargando = true;
    notifyListeners();
    try {
      await _supabase
          .from('hakuparadas')
          .delete()
          .eq('id', id);
          
      // Recargar localmente
      await cargarDatos();

    } catch (e) {
      _error = "Error al eliminar: $e";
      _estaCargando = false;
      notifyListeners();
    }
  }
}
