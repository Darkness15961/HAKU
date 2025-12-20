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
      await authVM.iniciarSesionConGoogle();

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

              // Botón de Google Sign-In
              OutlinedButton(
                onPressed: authVM.estaCargando ? null : _submitGoogleLogin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authVM.estaCargando
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.google.com/favicon.ico',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),

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
