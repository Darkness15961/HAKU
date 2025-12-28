import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ViewModel de autenticación
import '../vista_modelos/autenticacion_vm.dart';
// Tu widget de diálogo
import '../widgets/terminos_condiciones_dialog.dart';

class LoginPagina extends StatefulWidget {
  const LoginPagina({super.key});

  @override
  State<LoginPagina> createState() => _LoginPaginaState();
}

class _LoginPaginaState extends State<LoginPagina> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authVM = context.read<AutenticacionVM>();

    // Ocultar teclado suavemente
    FocusScope.of(context).unfocus();

    final exito = await authVM.iniciarSesion(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (exito) {
      if (authVM.esAdmin) {
        context.pushReplacement('/panel-admin');
      } else {
        context.pushReplacement('/inicio');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.error ?? 'Error de credenciales'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AutenticacionVM>();
    final theme = Theme.of(context);
    final colorPrimario = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,

      // BANNER SUPERIOR
      appBar: AppBar(
        backgroundColor: colorPrimario,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inicio');
            }
          },
        ),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          // MEJORA 2: ConstrainedBox para que no se estire en Tablets/PC
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGO HAKU
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorPrimario.withOpacity(0.1),
                      child: Icon(Icons.travel_explore, size: 45, color: colorPrimario),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Bienvenido a HAKU',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu aventura en Cusco comienza aquí.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 35),

                    // INPUTS
                    // MEJORA 1: Flujo de teclado (next -> done)
                    _buildInput(
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next, // Botón "Siguiente"
                    ),
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done, // Botón "Enviar"
                      onSubmitted: (_) => _submitLogin(), // Ejecuta login al dar Enter
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/recuperar-contrasena'),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: colorPrimario, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BOTÓN INGRESAR
                    ElevatedButton(
                      onPressed: authVM.estaCargando ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        backgroundColor: colorPrimario,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: authVM.estaCargando
                          ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                          : const Text(
                        'Ingresar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("O continúa con", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // BOTÓN GOOGLE
                    OutlinedButton(
                      onPressed: authVM.estaCargando ? null : () async {
                        final exito = await authVM.iniciarSesionGoogle();
                        if (!mounted) return;
                        if (exito) {
                          context.pushReplacement(authVM.esAdmin ? '/panel-admin' : '/inicio');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo iniciar con Google')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // MEJORA 3: Imagen segura (loading y error handler)
                          Image.network(
                            'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                            height: 24,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(width: 24, height: 24); // Espacio vacío mientras carga
                            },
                            errorBuilder: (_, __, ___) => const Icon(Icons.public, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // REGISTRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("¿No tienes cuenta?", style: TextStyle(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => context.push('/registro'),
                          child: const Text('Regístrate aquí', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // TÉRMINOS Y CONDICIONES
                    GestureDetector(
                      onTap: () => TerminosCondicionesDialog.mostrar(context),
                      child: Text.rich(
                        TextSpan(
                          text: 'Al continuar, aceptas nuestros ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MÉTODO _buildInput MEJORADO PARA RECIBIR ACCIONES DE TECLADO
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputAction? textInputAction, // Nuevo parámetro
    Function(String)? onSubmitted,    // Nuevo parámetro
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      // Aquí conectamos el teclado
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: onToggleVisibility,
        )
            : null,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Este campo es requerido';
        if (!isPassword && !v.contains('@')) return 'Correo inválido';
        if (isPassword && v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }
}