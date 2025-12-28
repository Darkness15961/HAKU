// --- PIEDRA 9 (AUTENTICACIÓN): EL "MENÚ" DE REGISTRO MEJORADO (VERSIÓN PRO) ---
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ViewModels
import '../vista_modelos/autenticacion_vm.dart';

// Servicios
import '../../../../core/servicios/reniec_servicio.dart';

class RegistroPagina extends StatefulWidget {
  const RegistroPagina({super.key});

  @override
  State<RegistroPagina> createState() => _RegistroPaginaState();
}

class _RegistroPaginaState extends State<RegistroPagina> {
  // --- Controladores Principales ---
  final TextEditingController _seudonimoCtrl = TextEditingController();
  final TextEditingController _documentoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  // --- Controladores Manuales (Extranjeros) ---
  final TextEditingController _nombresCtrl = TextEditingController();
  final TextEditingController _apellidoPaternoCtrl = TextEditingController();
  final TextEditingController _apellidoMaternoCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ReniecServicio _reniecServicio = ReniecServicio();

  // --- Estado ---
  String _tipoDocumento = 'DNI'; // 'DNI' o 'CE'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _validandoReniec = false;
  bool _datosVerificados = false;

  // Datos temporales de RENIEC
  String? _nombresReniec;
  String? _apellidoPaternoReniec;
  String? _apellidoMaternoReniec;

  @override
  void dispose() {
    _seudonimoCtrl.dispose();
    _documentoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA: Validar con RENIEC ---
  Future<void> _validarConReniec() async {
    if (_documentoCtrl.text.length != 8) return;
    setState(() => _validandoReniec = true);

    // Simulamos o llamamos al servicio real
    final datos = await _reniecServicio.consultarDNI(_documentoCtrl.text);

    setState(() => _validandoReniec = false);

    if (datos != null) {
      setState(() {
        _nombresReniec = datos['nombre'];
        _apellidoPaternoReniec = datos['apellidoPaterno'];
        _apellidoMaternoReniec = datos['apellidoMaterno'];
        _datosVerificados = true;

        // Truco de UX: Llenamos los controladores ocultos por si acaso
        _nombresCtrl.text = _nombresReniec ?? '';
        _apellidoPaternoCtrl.text = _apellidoPaternoReniec ?? '';
        _apellidoMaternoCtrl.text = _apellidoMaternoReniec ?? '';
      });
    } else {
      _resetearDatosReniec();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo validar el DNI. Inténtalo de nuevo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _resetearDatosReniec() {
    setState(() {
      _nombresReniec = null;
      _apellidoPaternoReniec = null;
      _apellidoMaternoReniec = null;
      _datosVerificados = false;
    });
  }

  // --- LÓGICA: Enviar Formulario ---
  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validación extra para DNI
    if (_tipoDocumento == 'DNI' && !_datosVerificados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, valida tu DNI primero (escribe 8 dígitos).')),
      );
      return;
    }

    final vmAuth = context.read<AutenticacionVM>(); // Referencia rápida

    // Decisión inteligente: ¿Qué nombres enviamos?
    final String? nombres = _tipoDocumento == 'DNI' ? _nombresReniec : _nombresCtrl.text;
    final String? apPaterno = _tipoDocumento == 'DNI' ? _apellidoPaternoReniec : _apellidoPaternoCtrl.text;
    final String? apMaterno = _tipoDocumento == 'DNI' ? _apellidoMaternoReniec : _apellidoMaternoCtrl.text;

    final exito = await vmAuth.registrarUsuario(
      _seudonimoCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _documentoCtrl.text.trim(),
      _tipoDocumento,
      nombres,
      apPaterno,
      apMaterno,
    );

    if (!mounted) return;

    if (exito) {
      context.go('/inicio');
    } else {
      // --- ULTIMA MODIFICACIÓN ---
      final mensajeError = vmAuth.error ?? 'Error desconocido';

      // Detectamos si el error es de cuenta duplicada (mirando el texto del ViewModel)
      final esErrorDeCuenta = mensajeError.toLowerCase().contains('ya tiene cuenta') ||
          mensajeError.toLowerCase().contains('registrado') ||
          mensajeError.toLowerCase().contains('ya está en uso');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          // Naranja para advertencia (ya existe), Rojo para error técnico (internet)
          backgroundColor: esErrorDeCuenta ? Colors.orange.shade900 : Colors.red,
          duration: const Duration(seconds: 8), // Un poco más de tiempo para leer

          // EL BOTÓN MÁGICO
          action: esErrorDeCuenta
              ? SnackBarAction(
            label: 'IR AL LOGIN',
            textColor: Colors.white,
            onPressed: () {
              // Te lleva directo al login sin dar vueltas
              context.pushReplacement('/login');
            },
          )
              : null, // Si no es error de cuenta duplicada, no muestra botón
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox( // MEJORA 1: Evita que se estire en Tablets/PC
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Alineación prolija
                children: [
                  Text(
                    'Únete a HAKU',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu cuenta para conocer nuevos lugares, reservar rutas y mucho mas.',

                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // --- BLOQUE 1: DOCUMENTO ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildRadioOption('DNI', 'DNI')),
                            Expanded(child: _buildRadioOption('Carnet Ext.', 'CE')),
                          ],
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _documentoCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: _tipoDocumento == 'DNI' ? 8 : 12,
                          decoration: InputDecoration(
                            labelText: 'Número de Documento',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: InputBorder.none,
                            counterText: "", // Oculta el contador pequeño
                            suffixIcon: _validandoReniec
                                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                                : (_datosVerificados && _tipoDocumento == 'DNI')
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          ),
                          onChanged: (v) {
                            if (_datosVerificados) _resetearDatosReniec();
                            if (_tipoDocumento == 'DNI' && v.length == 8) _validarConReniec();
                          },
                        ),

                        // Nombre detectado automáticamente
                        if (_tipoDocumento == 'DNI' && _datosVerificados)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "$_nombresReniec $_apellidoPaternoReniec",
                                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BLOQUE 2: DATOS MANUALES (Solo Extranjeros) ---
                  if (_tipoDocumento == 'CE') ...[
                    _buildInput(_nombresCtrl, 'Nombres', Icons.person),
                    const SizedBox(height: 12),
                    _buildInput(_apellidoPaternoCtrl, 'Apellido Paterno', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildInput(_apellidoMaternoCtrl, 'Apellido Materno', Icons.person_outline),
                    const SizedBox(height: 20),
                  ],

                  // --- BLOQUE 3: CUENTA ---
                  _buildInput(_seudonimoCtrl, 'Nombre de Usuario', Icons.person_outline,
                      validator: (v) => (v!.length < 3) ? 'Mínimo 3 letras' : null),
                  const SizedBox(height: 12),

                  _buildInput(_emailCtrl, 'Correo Electrónico', Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) => (!v!.contains('@')) ? 'Correo inválido' : null),
                  const SizedBox(height: 12),

                  _buildInput(_passwordCtrl, 'Contraseña', Icons.lock_outline,
                      isPassword: true, showPass: !_obscurePassword,
                      onClickEye: () => setState(()=> _obscurePassword = !_obscurePassword),
                      validator: (v) => (v!.length < 6) ? 'Mínimo 6 caracteres' : null),
                  const SizedBox(height: 12),

                  _buildInput(_confirmPasswordCtrl, 'Confirmar Contraseña', Icons.lock_reset,
                      isPassword: true, showPass: !_obscureConfirmPassword,
                      onClickEye: () => setState(()=> _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (v) => (v != _passwordCtrl.text) ? 'No coinciden' : null),

                  const SizedBox(height: 30),

                  // --- BOTÓN PRINCIPAL ---
                  ElevatedButton(
                    onPressed: vmAuth.estaCargando ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: vmAuth.estaCargando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 24),
                  const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.all(8.0), child: Text("O")), Expanded(child: Divider())]),
                  const SizedBox(height: 24),

                  // --- BOTÓN GOOGLE (Tu versión corregida y bonita) ---
                  OutlinedButton(
                    onPressed: vmAuth.estaCargando ? null : () async {
                      final exito = await vmAuth.iniciarSesionGoogle();
                      if (!mounted) return;
                      if (exito) {
                        if (vmAuth.esAdmin) {
                          context.pushReplacement('/panel-admin');
                        } else {
                          context.go('/inicio');
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error con Google'), backgroundColor: Colors.red));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network('https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png', height: 24),
                        const SizedBox(width: 12),
                        const Text('Continuar con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => context.pushReplacement('/login'),
                    child: Text('¿Ya tienes cuenta? Inicia Sesión', style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER 1: RADIO BUTTON (Más limpio) ---
  Widget _buildRadioOption(String label, String val) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: val,
      groupValue: _tipoDocumento,
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onChanged: (v) => setState(() { _tipoDocumento = v!; _resetearDatosReniec(); }),
    );
  }

  // --- HELPER 2: INPUT REUTILIZABLE (MEJORA PRO: Menos código repetido) ---
  Widget _buildInput(
      TextEditingController ctrl,
      String label,
      IconData icon,
      {
        TextInputType type = TextInputType.text,
        bool isPassword = false,
        bool showPass = false,
        VoidCallback? onClickEye,
        String? Function(String?)? validator
      }
      ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: isPassword && !showPass,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(showPass ? Icons.visibility_off : Icons.visibility), onPressed: onClickEye)
            : null,
      ),
    );
  }
}