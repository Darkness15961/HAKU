// --- PIEDRA 7 (AUTENTICACIÓN): EL "MENÚ" DE LOGIN ---
//
// Esta es la pantalla de "Inicio de Sesión".
// Es un "Menú" (diseño) que se conecta al
// "Mesero de Seguridad" (AutenticacionVM) para
// darle la "orden" de iniciar sesión.
//
// 1. (DISEÑO CORREGIDO): Se restauró el color del AppBar para
//    que el título y la flecha de retroceso sean visibles.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 1. Importamos el "Mesero de Seguridad" (ViewModel)
import '../vista_modelos/autenticacion_vm.dart';

class LoginPagina extends StatefulWidget {
  const LoginPagina({super.key});

  @override
  State<LoginPagina> createState() => _LoginPaginaState();
}

class _LoginPaginaState extends State<LoginPagina> {
  // --- Estado Local de la UI ---
  //
  // Controladores para leer el texto de los campos
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // "Key" para validar el formulario (asegura que los campos no estén vacíos)
  final _formKey = GlobalKey<FormState>();

  // Para ocultar/mostrar la contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Siempre "limpiamos" los controladores cuando la pantalla se destruye
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // --- Lógica de Envío de Formulario ---
  //
  // Esta es la función que se llama al presionar el botón "Ingresar"
  Future<void> _submitLogin() async {
    // 1. Validamos el formulario
    //    (Si "validate()" devuelve "false", se detiene aquí)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Obtenemos los textos de los campos
    final email = _emailCtrl.text;
    final password = _passwordCtrl.text;

    // 3. --- MVVM: ORDEN AL "MESERO" ---
    //    "context.read" es para "dar una orden"
    //    Le damos la "ORDEN 2" (ver el VM de Auth) al "Mesero de Seguridad"
    final bool exito =
    await context.read<AutenticacionVM>().iniciarSesion(email, password);

    // 4. Verificamos la respuesta del "Mesero"
    //    (El "await" esperó a que el "Mesero" terminara)
    //    Usamos "mounted" para asegurar que la pantalla sigue "viva"

    // --- ¡CORREGIDO Y MEJORADO! ---
    if (mounted && exito) {
      // 5. ¡ÉXITO!
      //    Ahora que el VM autenticó, le preguntamos el ROL
      //    para saber a dónde redirigir.

      // Usamos "read" de nuevo porque estamos dentro de una función/evento
      final vmAuth = context.read<AutenticacionVM>();

      if (vmAuth.esAdmin) {
        // Es Admin -> Lo llevamos al panel de admin
        context.pushReplacement('/panel-admin');
      } else {
        // Es Turista o Guía -> Lo llevamos al inicio normal
        context.pushReplacement('/inicio');
      }

    } else if (mounted && !exito) {
      // 6. ¡ERROR!
      //    Si la app sigue "viva", leemos el error que
      //    el "Mesero" guardó y lo mostramos en un aviso.
      final errorMsg = context.read<AutenticacionVM>().error ??
          'Ocurrió un error desconocido.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
    // --- FIN DE LA CORRECCIÓN ---
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // --- MVVM: CONEXIÓN CON EL "MESERO" ---
    // "Escuchamos" (`watch`) al "Mesero" para saber
    // si está "cargando" (para bloquear el botón).
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
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
                // --- Logo (Placeholder) ---
                Icon(
                  Icons.explore,
                  size: 80,
                  color: colorPrimario,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido a Xplora Cusco',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa a tu cuenta para continuar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

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
                  // "validator" es el "inspector" del campo
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
                  obscureText: _obscurePassword, // Oculta el texto
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Botón para "ver/ocultar" contraseña
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
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
                const SizedBox(height: 24),

                // --- Botón de Ingresar ---
                ElevatedButton(
                  // --- MVVM: Lectura de Estado ---
                  // Si el "Mesero" está "cargando", el botón se deshabilita
                  onPressed: vmAuth.estaCargando ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // Botón grande
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vmAuth.estaCargando
                  // Si está cargando, muestra un spinner
                      ? const CircularProgressIndicator(color: Colors.white)
                  // Si no, muestra el texto
                      : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // --- Botón para Registrar ---
                TextButton(
                  onPressed: () {
                    // --- MVVM: Navegación con "GPS" ---
                    // Le decimos al "GPS" que nos lleve a la
                    // "dirección" de registro.
                    context.push('/registro');
                  },
                  child: const Text('¿No tienes una cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}