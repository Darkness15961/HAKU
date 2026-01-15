import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
/* import 'package:google_maps_flutter/google_maps_flutter.dart';  */

import 'package:latlong2/latlong.dart';

import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'package:xplore_cusco/core/servicios/imagen_servicio.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class AdminCrearLugarPagina extends StatefulWidget {
  final Lugar? lugar;

  const AdminCrearLugarPagina({super.key, this.lugar});

  @override
  State<AdminCrearLugarPagina> createState() => _AdminCrearLugarPaginaState();
}

class _AdminCrearLugarPaginaState extends State<AdminCrearLugarPagina> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _urlImagenCtrl = TextEditingController();
  final TextEditingController _latitudCtrl = TextEditingController();
  final TextEditingController _longitudCtrl = TextEditingController();
  final TextEditingController _videoTiktokCtrl = TextEditingController();

  final ImagenServicio _imagenServicio = ImagenServicio();

  String? _selectedProvinciaId;
  String? _horaInicioSeleccionada;
  String? _horaFinSeleccionada;

  bool _esModoEdicion = false;
  bool _subiendoImagen = false;

  final List<String> _listaHoras = List.generate(24, (index) {
    return '${index.toString().padLeft(2, '0')}:00';
  });

  @override
  void initState() {
    super.initState();
    if (widget.lugar != null) {
      _esModoEdicion = true;
      final lugar = widget.lugar!;
      _nombreCtrl.text = lugar.nombre;
      _descripcionCtrl.text = lugar.descripcion;
      _urlImagenCtrl.text = lugar.urlImagen;

      if (lugar.horario.contains('-')) {
        final partes = lugar.horario.split('-');
        if (partes.length == 2) {
          String inicio = partes[0].trim();
          String fin = partes[1].trim();
          if (_listaHoras.contains(inicio)) _horaInicioSeleccionada = inicio;
          if (_listaHoras.contains(fin)) _horaFinSeleccionada = fin;
        }
      }

      _latitudCtrl.text = lugar.latitud.toString();
      _longitudCtrl.text = lugar.longitud.toString();
      _videoTiktokCtrl.text = lugar.videoTiktokUrl ?? '';
      _selectedProvinciaId = lugar.provinciaId;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _urlImagenCtrl.dispose();
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    _videoTiktokCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirSelectorMapa() async {
    double? lat = double.tryParse(_latitudCtrl.text);
    double? lng = double.tryParse(_longitudCtrl.text);
    LatLng? ubicacionInicial;

    if (lat != null && lng != null && lat != 0 && lng != 0) {
      ubicacionInicial = LatLng(lat, lng);
    }

    final LatLng? resultado = await context.push<LatLng>(
      '/admin/selector-ubicacion',
      extra: ubicacionInicial,
    );

    if (resultado != null) {
      setState(() {
        _latitudCtrl.text = resultado.latitude.toString();
        _longitudCtrl.text = resultado.longitude.toString();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_urlImagenCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor sube una imagen')),
      );
      return;
    }

    final vmLugares = context.read<LugaresVM>();
    final vmAuth = context.read<AutenticacionVM>();

    if (vmAuth.usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sesión de usuario no válida.')),
      );
      return;
    }

    if (_selectedProvinciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Selecciona una Provincia')),
      );
      return;
    }

    String horarioFinal = '$_horaInicioSeleccionada - $_horaFinSeleccionada';

    final datosLugar = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'url_imagen': _urlImagenCtrl.text,
      'provincia_id': _selectedProvinciaId,
      'horario': horarioFinal,
      'latitud': double.tryParse(_latitudCtrl.text) ?? 0.0,
      'longitud': double.tryParse(_longitudCtrl.text) ?? 0.0,
      'video_tiktok_url': _videoTiktokCtrl.text.isNotEmpty
          ? _videoTiktokCtrl.text
          : null,
      'registrado_por': vmAuth.usuarioActual!.id,
    };

    // --- DEBUG PRINTS ---
    print('--- INTENTANDO CREAR/EDITAR LUGAR ---');
    print('DATOS A ENVIAR:');
    datosLugar.forEach((key, value) {
      print('$key: $value (${value.runtimeType})');
    });
    print('-------------------------------------');

    try {
      if (_esModoEdicion) {
        print('Modo: EDICIÓN (ID: ${widget.lugar!.id})');
        await vmLugares.actualizarLugar(widget.lugar!.id, datosLugar);
      } else {
        print('Modo: CREACIÓN');
        await vmLugares.crearLugar(datosLugar);
      }

      print('¡ÉXITO! Operación completada.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lugar ${_esModoEdicion ? 'actualizado' : 'creado'} con éxito',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      print('!!! ERROR AL GUARDAR LUGAR !!!');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Safety check: Ensure selected values exist in the current lists
    if (_selectedProvinciaId != null &&
        vmLugares.todasLasProvincias.isNotEmpty &&
        !vmLugares.todasLasProvincias.any(
          (p) => p.id == _selectedProvinciaId,
        )) {
      _selectedProvinciaId = null;
    }

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
                  _buildSectionTitle('Información Básica'),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: _buildInputDecoration('Nombre del Lugar'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: _buildInputDecoration('Descripción'),
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildInputLabel('Imagen Principal'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _subiendoImagen
                        ? null
                        : () async {
                            setState(() => _subiendoImagen = true);
                            final url = await _imagenServicio.seleccionarYSubir(
                              'lugares',
                            );
                            if (url != null) {
                              setState(() => _urlImagenCtrl.text = url);
                            }
                            setState(() => _subiendoImagen = false);
                          },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        image: _urlImagenCtrl.text.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_urlImagenCtrl.text),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _subiendoImagen
                          ? const Center(child: CircularProgressIndicator())
                          : _urlImagenCtrl.text.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para subir una foto',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const Divider(height: 32),

                  _buildSectionTitle('Clasificación'),
                  DropdownButtonFormField<String>(
                    value: _selectedProvinciaId,
                    decoration: _buildInputDecoration('Provincia'),
                    items: vmLugares.todasLasProvincias.map((Provincia p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          p.nombre.isNotEmpty ? p.nombre : 'Sin Nombre',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProvinciaId = value),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),

                  const Divider(height: 32),

                  _buildSectionTitle('Horas Recomendadas para Visitar'),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _horaInicioSeleccionada,
                          decoration: _buildInputDecoration('Desde'),
                          menuMaxHeight: 300,
                          items: _listaHoras.map((hora) {
                            return DropdownMenuItem(
                              value: hora,
                              child: Text(hora),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _horaInicioSeleccionada = val),
                          validator: (v) => v == null ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _horaFinSeleccionada,
                          decoration: _buildInputDecoration('Hasta'),
                          menuMaxHeight: 300,
                          items: _listaHoras.map((hora) {
                            return DropdownMenuItem(
                              value: hora,
                              child: Text(hora),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _horaFinSeleccionada = val),
                          validator: (v) => v == null ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Ubicación en Mapa'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _abrirSelectorMapa,
                          icon: const Icon(Icons.location_on_rounded),
                          label: const Text('Ubicar en el Mapa'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Indicador visual de estado
                        if (_latitudCtrl.text.isNotEmpty &&
                            _longitudCtrl.text.isNotEmpty &&
                            _latitudCtrl.text != '0.0' &&
                            _latitudCtrl.text != '0')
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Ubicación establecida',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No has definido la ubicación',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _videoTiktokCtrl,
                    decoration: _buildInputDecoration(
                      'Link de TikTok (Opcional)',
                    ),
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _esModoEdicion ? 'Actualizar Lugar' : 'Crear Lugar',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (vmLugares.estaCargandoGestion)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
