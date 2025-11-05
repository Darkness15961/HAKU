// --- PIEDRA 5 (AUTENTICACIÓN): EL "MESERO DE SEGURIDAD" (ACTUALIZADO) ---
//
// Esta es la versión actualizada del "Mesero".
// Le hemos "enseñado" la nueva "ORDEN 5: solicitarSerGuia"
// que el formulario (que vamos a crear) necesitará.

import 'package:flutter/material.dart';

// 1. Importamos el "Enchufe" (Repositorio) de Autenticación
import '../../dominio/repositorios/autenticacion_repositorio.dart';
// 2. Importamos la "Receta" (Entidad) de Usuario
import '../../dominio/entidades/usuario.dart';

// 3. Importamos el "Conector" (GetIt)
import '../../../../locator.dart';

class AutenticacionVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final AutenticacionRepositorio _repositorio;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  Usuario? _usuarioActual;
  String? _error;

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Usuario? get usuarioActual => _usuarioActual;
  String? get error => _error;
  bool get estaLogueado => _usuarioActual != null;

  // --- D. CONSTRUCTOR ---
  AutenticacionVM() {
    _repositorio = getIt<AutenticacionRepositorio>();
    verificarEstadoSesion();
  }

  // --- E. MÉTODOS (Las "Órdenes") ---

  // ORDEN 1: "Verificar si ya hay una sesión"
  Future<void> verificarEstadoSesion() async {
    _estaCargando = true;
    notifyListeners();
    _usuarioActual = await _repositorio.verificarEstadoSesion();
    _estaCargando = false;
    notifyListeners();
  }

  // ORDEN 2: "Intentar iniciar sesión"
  Future<bool> iniciarSesion(String email, String password) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual = await _repositorio.iniciarSesion(email, password);
      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ORDEN 3: "Intentar registrar un usuario"
  Future<bool> registrarUsuario(
      String nombre, String email, String password, String dni) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual =
      await _repositorio.registrarUsuario(nombre, email, password, dni);
      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ORDEN 4: "Cerrar la sesión actual"
  Future<void> cerrarSesion() async {
    _estaCargando = true;
    notifyListeners();
    await _repositorio.cerrarSesion();
    _usuarioActual = null;
    _estaCargando = false;
    notifyListeners();
  }

  // --- ¡NUEVO MÉTODO! (Paso 3 - Bloque 5) ---
  //
  // ORDEN 5: "Enviar la solicitud para ser guía"
  // (Llamado por el formulario "solicitar_guia_pagina.dart")
  Future<bool> solicitarSerGuia(
      String experiencia, String rutaCertificado) async {
    // 1. Encendemos el "interruptor"
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 2. Le damos la "ORDEN 5" a la "Cocina" (Mock)
      await _repositorio.solicitarSerGuia(experiencia, rutaCertificado);

      // 3. ¡IMPORTANTE! Después de enviar la solicitud,
      //    volvemos a verificar el estado del usuario.
      //    (La "Cocina Falsa" (el Canvas) habrá cambiado
      //    el rol a "guia_pendiente", así que
      //    "verificarEstadoSesion" traerá ese nuevo usuario).
      await verificarEstadoSesion();

      // 4. Apagamos el "interruptor" y "avisamos"
      _estaCargando = false;
      notifyListeners();
      return true; // ¡Éxito!
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false; // ¡Error!
    }
  }
// --- FIN DEL NUEVO MÉTODO ---
}

