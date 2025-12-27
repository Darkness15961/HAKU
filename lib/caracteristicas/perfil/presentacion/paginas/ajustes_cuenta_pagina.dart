import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../../core/servicios/reniec_servicio.dart';

class AjustesCuentaPagina extends StatefulWidget {
  const AjustesCuentaPagina({super.key});

  @override
  State<AjustesCuentaPagina> createState() => _AjustesCuentaPaginaState();
}

class _AjustesCuentaPaginaState extends State<AjustesCuentaPagina> {
  final _formKey = GlobalKey<FormState>();
  final _seudonimoCtrl = TextEditingController();
  final _passwordActualCtrl = TextEditingController();
  final _passwordNuevaCtrl = TextEditingController();
  final _passwordConfirmarCtrl = TextEditingController();

  // Para completar perfil
  final _documentoCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();

  String _tipoDocumento = 'DNI';
  bool _validandoReniec = false;
  bool _datosVerificados = false;
  String? _nombresReniec;
  String? _apellidoPaternoReniec;
  String? _apellidoMaternoReniec;

  final _reniecServicio = ReniecServicio();

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AutenticacionVM>().usuarioActual;
    if (usuario != null) {
      _seudonimoCtrl.text = usuario.seudonimo ?? '';
    }
  }

  @override
  void dispose() {
    _seudonimoCtrl.dispose();
    _passwordActualCtrl.dispose();
    _passwordNuevaCtrl.dispose();
    _passwordConfirmarCtrl.dispose();
    _documentoCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    super.dispose();
  }

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
            content: Text('No se pudo consultar el DNI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = context.read<AutenticacionVM>();
    final usuario = authVM.usuarioActual;

    if (usuario == null) return;

    // TODO: Implementar actualización en repositorio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AutenticacionVM>();
    final usuario = authVM.usuarioActual;

    if (usuario == null) {
      return const Scaffold(body: Center(child: Text('No hay usuario')));
    }

    final tieneDNI = usuario.dni != null && usuario.dni!.isNotEmpty;
    final esGoogle = usuario.email?.contains('@') == true; // Simplificado

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de Cuenta'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de Perfil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: usuario.urlFotoPerfil != null
                          ? NetworkImage(usuario.urlFotoPerfil!)
                          : null,
                      child: usuario.urlFotoPerfil == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          color: Colors.white,
                          onPressed: () {
                            // TODO: Cambiar foto
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  usuario.email ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),

              // Información Personal
              Text(
                'Información Personal',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Usuario (editable)
              TextFormField(
                controller: _seudonimoCtrl,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre completo (solo lectura si ya existe)
              if (tieneDNI) ...[
                TextFormField(
                  initialValue:
                      '${usuario.nombres ?? ''} ${usuario.apellidoPaterno ?? ''} ${usuario.apellidoMaterno ?? ''}',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: usuario.dni,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                  ),
                ),
              ] else ...[
                // Completar perfil
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Completa tu perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Para inscribirte a rutas, necesitas completar tu información personal.',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de tipo de documento
                Text(
                  'Tipo de Documento',
                  style: Theme.of(context).textTheme.titleMedium,
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
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo de documento
                TextFormField(
                  controller: _documentoCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (_tipoDocumento == 'DNI' && _datosVerificados) {
                      setState(() {
                        _datosVerificados = false;
                        _nombresReniec = null;
                      });
                    }
                  },
                  onEditingComplete: () {
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

                // Mostrar nombre completo si DNI verificado
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

                // Campos manuales para CE
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
                ],
              ],

              const SizedBox(height: 32),

              // Información del sistema (solo lectura)
              Text(
                'Información',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Rol de Usuario'),
                subtitle: Text(usuario.rol ?? 'USUARIO'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('ID de Usuario'),
                subtitle: Text(usuario.id),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),

              // Seguridad (solo si no es Google)
              if (!esGoogle) ...[
                Text(
                  'Seguridad',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordActualCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordNuevaCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordConfirmarCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (_passwordNuevaCtrl.text.isNotEmpty &&
                        value != _passwordNuevaCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                FilledButton(
                  onPressed: () {
                    // TODO: Cambiar contraseña
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función próximamente')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Actualizar Contraseña'),
                ),
                const SizedBox(height: 32),
              ],

              // Botón guardar cambios
              FilledButton(
                onPressed: _guardarCambios,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
