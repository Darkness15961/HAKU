import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ViewModel de autenticación
import '../vista_modelos/autenticacion_vm.dart';
// Diálogo de términos
import '../widgets/terminos_condiciones_dialog.dart';

class RegistroPagina extends StatefulWidget {
  const RegistroPagina({super.key});

  @override
  State<RegistroPagina> createState() => _RegistroPaginaState();
}

class _RegistroPaginaState extends State<RegistroPagina> {
  // Controladores
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authVM = context.read<AutenticacionVM>();
    FocusScope.of(context).unfocus(); // Ocultar teclado

    final exito = await authVM.registrarUsuario(
      _nombreCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _dniCtrl.text.trim(),
    );

    if (!mounted) return;

    if (exito) {
      // CASO: REGISTRO "EXITOSO" (Real o Simulado por Supabase)
      // Si Confirm Email está ON, usuarioActual será null hasta que confirme.
      if (authVM.usuarioActual == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // --- MENSAJE DE INGENIERÍA PARA PRODUCCIÓN ---
            content: const Text(
              'Hemos enviado un enlace a tu correo. Si no lo recibes, es posible que ya tengas una cuenta registrada.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'IR AL LOGIN',
              textColor: Colors.white,
              onPressed: () => context.go('/login'),
            ),
          ),
        );

        // Damos 2 segundos para que lean antes de cambiar de pantalla
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');

      } else {
        // Si no requería confirmación, entra directo
        context.go('/inicio');
      }
    } else {
      // CASO: ERROR EXPLÍCITO (Si logramos que Supabase suelte el error)
      if (authVM.error == 'user_already_exists' ||
          (authVM.error ?? '').contains('already registered')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Este correo ya tiene una cuenta asociada.'),
            backgroundColor: Colors.orange.shade900,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'IR AL LOGIN',
              textColor: Colors.white,
              onPressed: () => context.go('/login'),
            ),
          ),
        );
      } else {
        // Otros errores (password débil, sin internet, etc.)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVM.error ?? 'Error al registrarse'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AutenticacionVM>();
    final theme = Theme.of(context);
    final colorPrimario = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,

      // BARRA SUPERIOR
      appBar: AppBar(
        backgroundColor: colorPrimario,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/login');
          },
        ),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
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
                    // TÍTULOS
                    Text(
                      'Únete a HAKU',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu cuenta para guardar favoritos y reservar rutas.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // --- FORMULARIO ---

                    // 1. Nombre
                    _buildInput(
                      controller: _nombreCtrl,
                      label: 'Nombre de Usuario',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 3) ? 'Ingresa tu nombre completo' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. DNI
                    _buildInput(
                      controller: _dniCtrl,
                      label: 'DNI',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length != 8) ? 'DNI inválido (8 dígitos)' : null,
                    ),
                    const SizedBox(height: 16),

                    // 3. Email
                    _buildInput(
                      controller: _emailCtrl,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Contraseña
                    _buildInput(
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 16),

                    // 5. Confirmar Contraseña
                    _buildInput(
                      controller: _confirmPasswordCtrl,
                      label: 'Confirmar Contraseña',
                      icon: Icons.lock_clock_outlined,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitRegister(),
                      validator: (v) {
                        if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // BOTÓN REGISTRAR
                    ElevatedButton(
                      onPressed: authVM.estaCargando ? null : _submitRegister,
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
                        height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text(
                        'Crear Cuenta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // DIVISOR
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("O regístrate con", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                          context.go('/inicio');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo registrar con Google')),
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
                          Image.network(
                            'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                            height: 24,
                            loadingBuilder: (ctx, child, progress) => progress == null ? child : const SizedBox(width: 24),
                            errorBuilder: (_, __, ___) => const Icon(Icons.public, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Google',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // YA TIENES CUENTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("¿Ya tienes una cuenta?", style: TextStyle(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => context.pushReplacement('/login'),
                          child: const Text('Inicia Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // TÉRMINOS
                    GestureDetector(
                      onTap: () => TerminosCondicionesDialog.mostrar(context),
                      child: Text.rich(
                        TextSpan(
                          text: 'Al registrarte, aceptas nuestros ',
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

  // WIDGET INPUT HELPER
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
      validator: validator,
    );
  }
}