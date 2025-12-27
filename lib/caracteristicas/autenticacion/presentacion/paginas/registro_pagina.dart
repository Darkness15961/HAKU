// --- PIEDRA 9 (AUTENTICACIÓN): EL "MENÚ" DE REGISTRO MEJORADO ---
//
// NUEVO: Implementa validación con RENIEC y selector de tipo de documento
// 1. Selector DNI / Carnet de Extranjería
// 2. Validación automática con RENIEC para DNI
// 3. Confirmación de datos antes de crear cuenta
// 4. Ingreso manual para Carnet de Extranjería

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
  // --- Estado Local de la UI ---
  final TextEditingController _seudonimoCtrl = TextEditingController();
  final TextEditingController _documentoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  // Controladores para ingreso manual (Carnet de Extranjería)
  final TextEditingController _nombresCtrl = TextEditingController();
  final TextEditingController _apellidoPaternoCtrl = TextEditingController();
  final TextEditingController _apellidoMaternoCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ReniecServicio _reniecServicio = ReniecServicio();

  // Estado
  String _tipoDocumento = 'DNI'; // 'DNI' o 'CE'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _validandoReniec = false;
  bool _datosVerificados = false;

  // Datos de RENIEC
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

  // --- Validar con RENIEC (auto-llamado) ---
  Future<void> _validarConReniec() async {
    if (_documentoCtrl.text.length != 8) return;

    setState(() => _validandoReniec = true);

    final datos = await _reniecServicio.consultarDNI(_documentoCtrl.text);

    setState(() => _validandoReniec = false);

    if (datos != null) {
      setState(() {
        _nombresReniec = datos['nombre'];
        _apellidoPaternoReniec = datos['apellidoPaterno'];
        _apellidoMaternoReniec = datos['apellidoMaterno'];
        _datosVerificados = true;
        // Auto-llenar campos internos
        _nombresCtrl.text = _nombresReniec ?? '';
        _apellidoPaternoCtrl.text = _apellidoPaternoReniec ?? '';
        _apellidoMaternoCtrl.text = _apellidoMaternoReniec ?? '';
      });
    } else {
      setState(() {
        _nombresReniec = null;
        _apellidoPaternoReniec = null;
        _apellidoMaternoReniec = null;
        _datosVerificados = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo consultar el DNI. Verifica el número.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Mostrar diálogo de confirmación ---
  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Son correctos estos datos?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombres: $_nombresReniec'),
            Text('Apellido Paterno: $_apellidoPaternoReniec'),
            Text('Apellido Materno: $_apellidoMaternoReniec'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _nombresReniec = null;
                _apellidoPaternoReniec = null;
                _apellidoMaternoReniec = null;
                _nombresCtrl.clear();
                _apellidoPaternoCtrl.clear();
                _apellidoMaternoCtrl.clear();
              });
            },
            child: const Text('No, reintentar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _datosVerificados = true;
                // Auto-llenar campos
                _nombresCtrl.text = _nombresReniec ?? '';
                _apellidoPaternoCtrl.text = _apellidoPaternoReniec ?? '';
                _apellidoMaternoCtrl.text = _apellidoMaternoReniec ?? '';
              });
            },
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );
  }

  // --- Enviar formulario ---
  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validar datos según tipo de documento
    if (_tipoDocumento == 'DNI' && !_datosVerificados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes validar tu DNI con RENIEC primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tipoDocumento == 'CE') {
      if (_nombresCtrl.text.isEmpty ||
          _apellidoPaternoCtrl.text.isEmpty ||
          _apellidoMaternoCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los campos de nombres y apellidos'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Obtener datos según tipo de documento
    final String? nombres = _tipoDocumento == 'DNI'
        ? _nombresReniec
        : _nombresCtrl.text;
    final String? apellidoPaterno = _tipoDocumento == 'DNI'
        ? _apellidoPaternoReniec
        : _apellidoPaternoCtrl.text;
    final String? apellidoMaterno = _tipoDocumento == 'DNI'
        ? _apellidoMaternoReniec
        : _apellidoMaternoCtrl.text;

    final bool exito = await context.read<AutenticacionVM>().registrarUsuario(
      _seudonimoCtrl.text,
      _emailCtrl.text,
      _passwordCtrl.text,
      _documentoCtrl.text,
      _tipoDocumento,
      nombres,
      apellidoPaterno,
      apellidoMaterno,
    );

    if (!mounted) return;

    if (exito) {
      context.go('/inicio');
    } else {
      final errorMsg =
          context.read<AutenticacionVM>().error ??
          'Ocurrió un error desconocido.';
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
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
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Título ---
                Text(
                  'Únete a HAKU',
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

                // --- Selector de Tipo de Documento ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Documento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('DNI'),
                              value: 'DNI',
                              groupValue: _tipoDocumento,
                              onChanged: (value) {
                                setState(() {
                                  _tipoDocumento = value!;
                                  _datosVerificados = false;
                                  _nombresReniec = null;
                                  _apellidoPaternoReniec = null;
                                  _apellidoMaternoReniec = null;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('C. Extranjería'),
                              value: 'CE',
                              groupValue: _tipoDocumento,
                              onChanged: (value) {
                                setState(() {
                                  _tipoDocumento = value!;
                                  _datosVerificados = false;
                                  _nombresReniec = null;
                                  _apellidoPaternoReniec = null;
                                  _apellidoMaternoReniec = null;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Campo de Documento ---
                TextFormField(
                  controller: _documentoCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Limpiar datos si cambia el DNI
                    if (_tipoDocumento == 'DNI' && _datosVerificados) {
                      setState(() {
                        _datosVerificados = false;
                        _nombresReniec = null;
                        _apellidoPaternoReniec = null;
                        _apellidoMaternoReniec = null;
                      });
                    }
                  },
                  onEditingComplete: () {
                    // Auto-validar al salir del campo
                    if (_tipoDocumento == 'DNI' &&
                        _documentoCtrl.text.length == 8) {
                      _validarConReniec();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Documento de Identidad',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _validandoReniec
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu documento';
                    }
                    if (_tipoDocumento == 'DNI' && value.length != 8) {
                      return 'DNI debe tener 8 dígitos';
                    }
                    return null;
                  },
                ),

                // Mostrar nombre completo debajo del DNI
                if (_tipoDocumento == 'DNI' &&
                    _datosVerificados &&
                    _nombresReniec != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$_nombresReniec $_apellidoPaternoReniec $_apellidoMaternoReniec',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // --- Campos manuales SOLO para Carnet de Extranjería ---
                if (_tipoDocumento == 'CE') ...[
                  TextFormField(
                    controller: _nombresCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombres',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tus nombres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidoPaternoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Apellido Paterno',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu apellido paterno';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidoMaternoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Apellido Materno',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu apellido materno';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Campo de Usuario (antes Seudonimo) ---
                TextFormField(
                  controller: _seudonimoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    hintText: 'Ej: Viajero123',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 3) {
                      return 'Por favor, ingresa tu usuario.';
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
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
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
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
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
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordCtrl.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Botón de Registrar ---
                ElevatedButton(
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
                      : const Text(
                          'Crear Cuenta',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // --- Botón para ir a Login ---
                TextButton(
                  onPressed: () {
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
