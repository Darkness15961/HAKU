import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ViewModel de autenticación
import '../vista_modelos/autenticacion_vm.dart';
import '../widgets/terminos_condiciones_dialog.dart';

class LoginPagina extends StatefulWidget {
  const LoginPagina({super.key});

  @override
  State<LoginPagina> createState() => _LoginPaginaState();
}

class _LoginPaginaState extends State<LoginPagina> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submitGoogleLogin() async {
    final authVM = context.read<AutenticacionVM>();

    try {
      // Iniciar OAuth - esto abrirá el navegador y redirigirá la página
      await authVM.iniciarSesionGoogle();

      // NOTA: En web, el código no llegará aquí porque la página se redirige
      // No intentar navegar manualmente
    } catch (e) {
      // Solo mostrar error si falla al iniciar el OAuth
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión con Google'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a HAKU'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la app
              Icon(Icons.explore, size: 100, color: colorPrimario),
              const SizedBox(height: 24),

              Text(
                'Explora Cusco',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Descubre lugares increíbles y rutas turísticas',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),


// ==========================================
              // 👇 AQUÍ AGREGUÉ EL BOTÓN DE GOOGLE 👇
              // ==========================================
              OutlinedButton.icon(
                onPressed: authVM.estaCargando ? null : () async {
                  // Llamamos a la función que creaste en el VM
                  final exito = await authVM.iniciarSesionGoogle();

                  if (!mounted) return;

                  if (exito) {
                    // Usamos tu misma lógica de redirección
                    if (authVM.esAdmin) {
                      context.pushReplacement('/panel-admin');
                    } else {
                      context.pushReplacement('/inicio');
                    }
                  } else {
                    // Mensaje simple si falla o cancela
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo iniciar sesión con Google')),
                    );
                  }
                },
                // Icono de Google (desde internet para que no instales nada extra por ahora)
                icon: Image.network(
                  'https://www.google.com/favicon.ico',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.public, color: Colors.red), // Icono respaldo si falla la imagen
                ),
                label: const Text(
                  'Continuar con Google',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // ==========================================

              const SizedBox(height: 24),

              // Términos y condiciones clickeable
              GestureDetector(
                onTap: () => TerminosCondicionesDialog.mostrar(context),
                child: Text.rich(
                  TextSpan(
                    text: 'Al continuar, aceptas nuestros ',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    children: [
                      TextSpan(
                        text: 'términos y condiciones',
                        style: TextStyle(
                          color: colorPrimario,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
