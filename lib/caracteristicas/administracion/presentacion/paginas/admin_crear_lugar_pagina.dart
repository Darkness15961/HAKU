// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_CREAR_LUGAR_PAGINA.DART ---
//
// Esta es la nueva página de formulario para Crear o Editar un Lugar.
// 1. (¡CORREGIDO!) Se cambió 'vmLugares.provincias' por
//    'vmLugares.provinciasFiltradas' para arreglar el error del getter.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/categoria.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';

class AdminCrearLugarPagina extends StatefulWidget {
  final Lugar? lugar; // Si 'lugar' no es nulo, estamos en modo Edición

  const AdminCrearLugarPagina({super.key, this.lugar});

  @override
  State<AdminCrearLugarPagina> createState() => _AdminCrearLugarPaginaState();
}

class _AdminCrearLugarPaginaState extends State<AdminCrearLugarPagina> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _urlImagenCtrl = TextEditingController();
  final TextEditingController _horarioCtrl = TextEditingController();
  final TextEditingController _costoEntradaCtrl = TextEditingController();
  final TextEditingController _latitudCtrl = TextEditingController();
  final TextEditingController _longitudCtrl = TextEditingController();

  // Variables para los Dropdowns
  String? _selectedProvinciaId;
  String? _selectedCategoriaId;

  bool _esModoEdicion = false;

  @override
  void initState() {
    super.initState();

    // Comprobamos si estamos en modo Edición
    if (widget.lugar != null) {
      _esModoEdicion = true;
      final lugar = widget.lugar!;

      // Llenamos los campos con los datos del lugar
      _nombreCtrl.text = lugar.nombre;
      _descripcionCtrl.text = lugar.descripcion;
      _urlImagenCtrl.text = lugar.urlImagen;
      _horarioCtrl.text = lugar.horario;
      _costoEntradaCtrl.text = lugar.costoEntrada;
      _latitudCtrl.text = lugar.latitud.toString();
      _longitudCtrl.text = lugar.longitud.toString();
      _selectedProvinciaId = lugar.provinciaId;

      final vmLugares = context.read<LugaresVM>();
      final categoria = vmLugares.categorias.firstWhere(
            (c) => c.nombre.toLowerCase() == lugar.categoria.toLowerCase(),
        orElse: () => vmLugares.categorias.first, // Fallback
      );
      _selectedCategoriaId = categoria.id;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _urlImagenCtrl.dispose();
    _horarioCtrl.dispose();
    _costoEntradaCtrl.dispose();
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    super.dispose();
  }

  // --- Lógica de Envío de Formulario ---
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vmLugares = context.read<LugaresVM>();

    final Map<String, dynamic> datosLugar = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'urlImagen': _urlImagenCtrl.text,
      'horario': _horarioCtrl.text,
      'costoEntrada': _costoEntradaCtrl.text,
      'latitud': double.tryParse(_latitudCtrl.text) ?? 0.0,
      'longitud': double.tryParse(_longitudCtrl.text) ?? 0.0,
      'provinciaId': _selectedProvinciaId,
      'categoriaId': _selectedCategoriaId,
      'puntosInteres': [],
    };

    if (datosLugar['urlImagen'].isEmpty) {
      datosLugar['urlImagen'] = 'https://picsum.photos/seed/${_nombreCtrl.text.replaceAll(' ', '')}/1000/600';
    }

    // Mostramos el spinner
    // (Simulamos la carga llamando al método que activa el booleano)
    vmLugares.cargarTodosLosLugares();

    try {
      if (_esModoEdicion) {
        await vmLugares.actualizarLugar(widget.lugar!.id, datosLugar);
      } else {
        await vmLugares.crearLugar(datosLugar);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lugar ${ _esModoEdicion ? 'actualizado' : 'creado'} con éxito (Simulado)'),
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
        title: Text(_esModoEdicion ? 'Editar Lugar' : 'Crear Nuevo Lugar'),
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
                  // --- Campos de Texto ---
                  _buildSectionTitle('Información Básica'),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: _buildInputDecoration('Nombre del Lugar'),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: _buildInputDecoration('Descripción'),
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlImagenCtrl,
                    decoration: _buildInputDecoration('URL de Imagen (Opcional)'),
                    keyboardType: TextInputType.url,
                  ),

                  const Divider(height: 32),

                  // --- Dropdowns (Clasificación y Distrito) ---
                  _buildSectionTitle('Clasificación'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown de Provincias
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedProvinciaId,
                          decoration: _buildInputDecoration('Provincia'),
                          // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                          items: vmLugares.provinciasFiltradas.map((Provincia p) {
                            // --- FIN DE LA CORRECCIÓN ---
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedProvinciaId = value);
                          },
                          validator: (v) => v == null ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dropdown de Categorías
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoriaId,
                          decoration: _buildInputDecoration('Categoría'),
                          items: vmLugares.categorias
                              .where((c) => c.id != '1') // Quitamos "Todas"
                              .map((Categoria c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoriaId = value);
                          },
                          validator: (v) => v == null ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // --- Otros Campos ---
                  _buildSectionTitle('Detalles Adicionales'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _horarioCtrl,
                          decoration: _buildInputDecoration('Horario (Ej. 9:00 - 17:00)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costoEntradaCtrl,
                          decoration: _buildInputDecoration('Costo (Ej. S/ 10.00)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudCtrl,
                          decoration: _buildInputDecoration('Latitud (Ej. -13.51)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudCtrl,
                          decoration: _buildInputDecoration('Longitud (Ej. -71.97)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- Botón de Guardar ---
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_esModoEdicion ? 'Actualizar Lugar' : 'Crear Lugar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Overlay de Carga (Spinner)
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

  // --- Widgets Auxiliares de Diseño ---
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