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

      // AUTO-GUARDAR: Guardar automáticamente en la base de datos
      if (mounted) {
        final authVM = context.read<AutenticacionVM>();
        final usuario = authVM.usuarioActual;

        if (usuario != null &&
            (usuario.nombres == null || usuario.nombres!.isEmpty)) {
          // Solo guardar si el usuario aún no tiene nombres validados
          setState(() => _validandoReniec = true);

          final exitoPerfil = await authVM.completarPerfil(
            dni: _documentoCtrl.text.trim(),
            tipoDocumento: _tipoDocumento,
            nombres: _nombresReniec,
            apellidoPaterno: _apellidoPaternoReniec,
            apellidoMaterno: _apellidoMaternoReniec,
          );

          setState(() => _validandoReniec = false);

          if (exitoPerfil && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ DNI validado y guardado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authVM.error ?? 'Error al guardar DNI'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
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

    setState(() => _validandoReniec = true);

    try {
      // 1. Actualizar seudonimo si cambió
      if (_seudonimoCtrl.text != usuario.seudonimo) {
        final exitoSeudonimo = await authVM.actualizarSeudonimo(
          _seudonimoCtrl.text.trim(),
        );
        if (!exitoSeudonimo) {
          throw Exception('Error al actualizar usuario');
        }
      }

      // 2. Completar perfil solo si NO tiene DNI validado aún
      // (El DNI se guarda automáticamente al validar con RENIEC)
      if (usuario.nombres == null || usuario.nombres!.isEmpty) {
        if (_tipoDocumento == 'DNI' && !_datosVerificados) {
          throw Exception('Debes validar tu DNI primero');
        }

        if (_tipoDocumento == 'CE') {
          // Para Carnet de Extranjería, guardar manualmente
          final exitoPerfil = await authVM.completarPerfil(
            dni: _documentoCtrl.text.trim(),
            tipoDocumento: _tipoDocumento,
            nombres: _nombresCtrl.text,
            apellidoPaterno: _apellidoPaternoCtrl.text,
            apellidoMaterno: _apellidoMaternoCtrl.text,
          );

          if (!exitoPerfil) {
            throw Exception(authVM.error ?? 'Error al completar perfil');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cambios guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _validandoReniec = false);
      }
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passwordNuevaCtrl.text.isEmpty ||
        _passwordActualCtrl.text.isEmpty ||
        _passwordConfirmarCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos de contraseña'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordNuevaCtrl.text != _passwordConfirmarCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas nuevas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordNuevaCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authVM = context.read<AutenticacionVM>();

    try {
      await authVM.cambiarPasswordConValidacion(
        _passwordActualCtrl.text,
        _passwordNuevaCtrl.text,
      );

      if (mounted) {
        _passwordActualCtrl.clear();
        _passwordNuevaCtrl.clear();
        _passwordConfirmarCtrl.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraseña actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVM.error ?? 'Error al cambiar contraseña'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AutenticacionVM>();
    final usuario = authVM.usuarioActual;

    if (usuario == null) {
      return const Scaffold(body: Center(child: Text('No hay usuario')));
    }

    // DNI está validado solo si tiene nombres (validación RENIEC)
    final dniValidado = usuario.nombres != null && usuario.nombres!.isNotEmpty;
    final esGoogle = usuario.email?.contains('@') == true; // Simplificado

    // DEBUG: Ver qué datos tiene el usuario
    debugPrint('=== DEBUG AJUSTES CUENTA ===');
    debugPrint('DNI: ${usuario.dni}');
    debugPrint('Nombres: ${usuario.nombres}');
    debugPrint('Apellido Paterno: ${usuario.apellidoPaterno}');
    debugPrint('Apellido Materno: ${usuario.apellidoMaterno}');
    debugPrint('dniValidado: $dniValidado');
    debugPrint('===========================');

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

              // DNI y Nombre Completo - DNI PRIMERO
              if (dniValidado) ...[
                // DNI ya validado con RENIEC - solo lectura (PRIMERO)
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
                const SizedBox(height: 16),
                // Nombre completo (DESPUÉS, solo lectura)
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
                        'Para crear rutas, publicar lugares e inscribirte a rutas, necesitas validar tu DNI.',
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
                    // AUTO-VALIDACIÓN: Al completar 8 dígitos
                    if (_tipoDocumento == 'DNI' && value.length == 8) {
                      _validarConReniec();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Número de Documento',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: "",
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

                // Mostrar nombre completo si DNI verificado - MEJORADO
                if (_tipoDocumento == 'DNI' &&
                    _datosVerificados &&
                    _nombresReniec != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nombre Completo:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_nombresReniec $_apellidoPaternoReniec $_apellidoMaternoReniec',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

              // Cambiar Contraseña (solo si no es Google)
              if (!esGoogle) ...[
                Text(
                  'Cambiar Contraseña',
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
                  onPressed: _cambiarPassword,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Actualizar Contraseña'),
                ),
                const SizedBox(height: 32),
              ],

              // Información del sistema (solo lectura)
              Text(
                'Información',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Mostrar nombre completo si está validado
              if (dniValidado) ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Nombre Completo'),
                  subtitle: Text(
                    '${usuario.nombres ?? ''} ${usuario.apellidoPaterno ?? ''} ${usuario.apellidoMaterno ?? ''}'
                        .trim(),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],

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
