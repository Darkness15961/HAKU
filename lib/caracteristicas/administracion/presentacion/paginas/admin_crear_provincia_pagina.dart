// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_CREAR_PROVINCIA_PAGINA.DART ---
//
// Esta es la nueva página de formulario para Crear o Editar una Provincia.
// 1. (¡CORREGIDO!): Se movió el 'helperText' dentro del 'InputDecoration'.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';

class AdminCrearProvinciaPagina extends StatefulWidget {
  final Provincia? provincia; // Si no es nulo, estamos en modo Edición

  const AdminCrearProvinciaPagina({super.key, this.provincia});

  @override
  State<AdminCrearProvinciaPagina> createState() => _AdminCrearProvinciaPaginaState();
}

class _AdminCrearProvinciaPaginaState extends State<AdminCrearProvinciaPagina> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _urlImagenCtrl = TextEditingController();
  final TextEditingController _categoriasCtrl = TextEditingController();

  bool _esModoEdicion = false;

  @override
  void initState() {
    super.initState();

    if (widget.provincia != null) {
      _esModoEdicion = true;
      final provincia = widget.provincia!;

      _nombreCtrl.text = provincia.nombre;
      _urlImagenCtrl.text = provincia.urlImagen;
      // Convertimos la lista de categorías en un string separado por comas
      _categoriasCtrl.text = provincia.categories.join(', ');
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _urlImagenCtrl.dispose();
    _categoriasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vmLugares = context.read<LugaresVM>();

    // Convertimos el string de categorías en una lista
    final List<String> categoriesList = _categoriasCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final Map<String, dynamic> datosProvincia = {
      'nombre': _nombreCtrl.text,
      'urlImagen': _urlImagenCtrl.text,
      'categories': categoriesList,
    };

    if (datosProvincia['urlImagen'].isEmpty) {
      datosProvincia['urlImagen'] = 'https://picsum.photos/seed/${_nombreCtrl.text.replaceAll(' ', '')}/800/600';
    }

    vmLugares.cargarTodasLasProvincias(); // Activa el spinner

    try {
      if (_esModoEdicion) {
        await vmLugares.actualizarProvincia(widget.provincia!.id, datosProvincia);
      } else {
        await vmLugares.crearProvincia(datosProvincia);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Provincia ${ _esModoEdicion ? 'actualizada' : 'creada'} con éxito (Simulado)'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Regresa a la lista
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esModoEdicion ? 'Editar Provincia' : 'Crear Provincia'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Información de la Provincia'),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: _buildInputDecoration('Nombre de la Provincia'),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlImagenCtrl,
                    decoration: _buildInputDecoration('URL de Imagen (Opcional)'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _categoriasCtrl,
                    decoration: InputDecoration(
                      labelText: 'Categorías (separadas por coma)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Ej: Arqueología, Naturaleza, Aventura',
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_esModoEdicion ? 'Actualizar Provincia' : 'Crear Provincia'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (vmLugares.estaCargandoGestion)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}