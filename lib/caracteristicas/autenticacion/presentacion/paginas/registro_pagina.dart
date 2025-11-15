// --- PIEDRA 9 (AUTENTICACIÓN): EL "MENÚ" DE REGISTRO ---
//
// 1. (BUG NAVEGACIÓN CORREGIDO): Se cambió context.pushReplacement('/inicio')
//    por context.go('/inicio') para evitar el "failed assertion" de
//    navigator.dart al navegar entre stacks (root vs shell)
//    después de un 'await'.
// 2. (DISEÑO CORREGIDO): Se restauró el color del AppBar para
//    que el título y la flecha de retroceso sean visibles.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 1. Importamos el "Mesero de Seguridad" (ViewModel)
import '../vista_modelos/autenticacion_vm.dart';

class RegistroPagina extends StatefulWidget {
  const RegistroPagina({super.key});

  @override
  State<RegistroPagina> createState() => _RegistroPaginaState();
}

class _RegistroPaginaState extends State<RegistroPagina> {
  // --- Estado Local de la UI ---

  // Controladores para leer el texto de los campos
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  // "Key" para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Para ocultar/mostrar las contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // "Limpiamos" los controladores
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _dniCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // --- Lógica de Envío de Formulario ---
  //
  // Esta es la función que se llama al presionar el botón "Crear Cuenta"
  Future<void> _submitRegister() async {
    // 1. Validamos el formulario
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // --- ¡ARREGLO PARA EL BUG DEL SNACKBAR! ---
    // Guardamos la referencia al ScaffoldMessenger ANTES del 'await'.
    // Esto evita un error si el 'context' se vuelve inválido.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // --- FIN DE ARREGLO ---

    // 2. Obtenemos los textos de los campos
    final nombre = _nombreCtrl.text;
    final email = _emailCtrl.text;
    final dni = _dniCtrl.text;
    final password = _passwordCtrl.text;

    // 3. --- MVVM: ORDEN AL "MESERO" ---
    //    Le damos la "ORDEN 3" (ver el VM de Auth) al "Mesero de Seguridad"
    final bool exito = await context.read<AutenticacionVM>().registrarUsuario(
      nombre,
      email,
      password,
      dni,
    );

    // 4. Verificamos la respuesta del "Mesero"
    // ¡Aseguramos que el widget sigue montado ANTES de usar el context!
    if (!mounted) return;

    if (exito) {
      // 5. ¡ÉXITO!
      //    Usamos el "GPS" (GoRouter) para "reemplazar" esta pantalla
      //    y la de Login, y llevar al usuario directo a la app.

      // --- ¡CORREGIDO! ---
      // Usamos 'go' para reiniciar el stack de navegación
      // en lugar de 'pushReplacement'.
      context.go('/inicio');
      // --- FIN DE LA CORRECCIÓN ---

    } else {
      // 6. ¡ERROR!
      final errorMsg = context.read<AutenticacionVM>().error ??
          'Ocurrió un error desconocido.';

      // --- ¡CORREGIDO! ---
      // Usamos la referencia 'safe' al scaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
      // --- FIN DE CORRECCIÓN ---
    }
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (`watch`) al "Mesero" para saber
    // si está "cargando" (para bloquear el botón).
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
        // Se quita la transparencia para que el AppBar sea visible
        // backgroundColor: Colors.transparent, // <-- Eliminado
        // elevation: 0, // <-- Eliminado

        // Se añade 'surfaceTintColor' para un diseño limpio en Material 3
        surfaceTintColor: Colors.transparent,
        // --- FIN DE LA CORRECCIÓN ---
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey, // Conectamos la "llave" al formulario
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Título ---
                Text(
                  'Únete a Xplora Cusco',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu cuenta para guardar favoritos y reservar rutas.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- Campo de Nombre Completo ---
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 3) {
                      return 'Por favor, ingresa tu nombre.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo de DNI ---
                TextFormField(
                  controller: _dniCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 8) {
                      return 'Ingresa un DNI válido (8 dígitos).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo de Email ---
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Por favor, ingresa un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo de Contraseña ---
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },

                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo de Confirmar Contraseña ---
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword =
                        !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    // Compara con el campo de contraseña
                    if (value != _passwordCtrl.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Botón de Registrar ---
                ElevatedButton(
                  // Si el "Mesero" está "cargando", se deshabilita
                  onPressed: vmAuth.estaCargando ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vmAuth.estaCargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Crear Cuenta', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // --- Botón para ir a Login ---
                TextButton(
                  onPressed: () {
                    // --- MVVM: Navegación con "GPS" ---
                    // Le decimos al "GPS" que nos "reemplace"
                    // esta pantalla por la de login.
                    context.pushReplacement('/login');
                  },
                  child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}