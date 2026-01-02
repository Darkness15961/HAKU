import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../caracteristicas/autenticacion/dominio/entidades/usuario.dart';

/// Helper para validar si el usuario tiene DNI validado
class ValidacionDNIHelper {
  /// Verifica si el usuario tiene nombre completo (DNI validado)
  static bool tieneNombreCompleto(Usuario? usuario) {
    return usuario?.nombres != null && usuario!.nombres!.isNotEmpty;
  }

  /// Muestra un mensaje indicando que se requiere validar el DNI
  /// y ofrece un botón para ir a Ajustes de Cuenta
  static void mostrarMensajeDNIRequerido(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '⚠️ Debes validar tu nombre completo en Ajustes de Cuenta',
        ),
        backgroundColor: Colors.orange[900],
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ir a Ajustes',
          textColor: Colors.white,
          onPressed: () {
            context.push('/perfil/ajustes-cuenta');
          },
        ),
      ),
    );
  }

  /// Verifica si el usuario puede realizar acciones que requieren DNI validado
  /// Retorna true si puede continuar, false si debe validar DNI
  /// Si retorna false, automáticamente muestra el mensaje al usuario
  static bool verificarYMostrarMensaje(BuildContext context, Usuario? usuario) {
    if (!tieneNombreCompleto(usuario)) {
      mostrarMensajeDNIRequerido(context);
      return false;
    }
    return true;
  }
}
