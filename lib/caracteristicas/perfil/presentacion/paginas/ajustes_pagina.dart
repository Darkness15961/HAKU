import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/core/servicios/imagen_servicio.dart';

class AjustesPagina extends StatefulWidget {
  const AjustesPagina({super.key});

  @override
  State<AjustesPagina> createState() => _AjustesPaginaState();
}

class _AjustesPaginaState extends State<AjustesPagina> {
  final ImagenServicio _imagenServicio = ImagenServicio();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _cambiandoFoto = false;
  bool _cambiandoPassword = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarFotoPerfil() async {
    setState(() => _cambiandoFoto = true);
    try {
      // 1. Seleccionar y subir imagen
      final url = await _imagenServicio.seleccionarYSubir('perfiles');
      
      if (url != null) {
        // 2. Actualizar en Supabase y VM
        if (mounted) {
          await context.read<AutenticacionVM>().actualizarFotoPerfil(url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada ✅')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoFoto = false);
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _cambiandoPassword = true);
    try {
      await context.read<AutenticacionVM>().cambiarPassword(_passwordCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente 🔒')),
        );
        _passwordCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final usuario = vmAuth.usuarioActual;
    final colorPrimario = Theme.of(context).colorScheme.primary;

    if (usuario == null) return const Scaffold(body: Center(child: Text('No hay sesión')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Cuenta'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN 1: FOTO DE PERFIL ---
            const Text(
              'Foto de Perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (usuario.urlFotoPerfil != null && usuario.urlFotoPerfil!.isNotEmpty)
                            ? NetworkImage(usuario.urlFotoPerfil!)
                            : null,
                        child: (usuario.urlFotoPerfil == null || usuario.urlFotoPerfil!.isEmpty)
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      if (_cambiandoFoto)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: colorPrimario,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            onPressed: _cambiandoFoto ? null : _cambiarFotoPerfil,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(usuario.email, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            
            const Divider(height: 40),

            // --- SECCIÓN 2: SEGURIDAD ---
            const Text(
              'Seguridad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                hintText: 'Mínimo 6 caracteres',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cambiandoPassword ? null : _cambiarPassword,
                icon: _cambiandoPassword 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Actualizar Contraseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const Divider(height: 40),

            // --- SECCIÓN 3: INFORMACIÓN ---
            const Text(
              'Información',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rol de Usuario'),
              subtitle: Text(usuario.rol.toUpperCase()),
              leading: const Icon(Icons.badge_outlined),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ID de Usuario'),
              subtitle: Text(usuario.id, style: const TextStyle(fontSize: 12)),
              leading: const Icon(Icons.fingerprint),
            ),
          ],
        ),
      ),
    );
  }
}
