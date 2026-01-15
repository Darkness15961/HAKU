import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xplore_cusco/caracteristicas/mapa/datos/modelos/hakuparada_model.dart';
import 'package:xplore_cusco/caracteristicas/mapa/dominio/entidades/hakuparada.dart';

class MisHakuparadasVM extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  String? _error;

  List<Hakuparada> _misPendientes = [];
  List<Hakuparada> _misAprobadas = [];

  bool get estaCargando => _estaCargando;
  String? get error => _error;
  List<Hakuparada> get misPendientes => _misPendientes;
  List<Hakuparada> get misAprobadas => _misAprobadas;

  MisHakuparadasVM() {
    cargarMisHakuparadas();
  }

  Future<void> cargarMisHakuparadas() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _error = "No has iniciado sesión";
      notifyListeners();
      return;
    }

    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('hakuparadas')
          .select()
          .eq('publicado_por', userId)
          .order('created_at', ascending: false);

      final listaTotal = (response as List)
          .map((json) => HakuparadaModel.fromJson(json))
          .toList();

      // Separamos en dos listas para la UI
      _misPendientes = listaTotal.where((h) => !h.verificado).toList();
      _misAprobadas = listaTotal.where((h) => h.verificado).toList();

    } catch (e) {
      _error = "Error cargando tus hakuparadas: $e";
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}
