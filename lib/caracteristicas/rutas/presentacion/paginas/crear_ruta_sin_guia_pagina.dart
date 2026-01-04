import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart'; // <--- 1. IMPORT NECESARIO

import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';
import '../vista_modelos/rutas_vm.dart';

class CrearRutaSinGuiaPagina extends StatefulWidget {
  const CrearRutaSinGuiaPagina({Key? key}) : super(key: key);

  @override
  State<CrearRutaSinGuiaPagina> createState() => _CrearRutaSinGuiaPaginaState();
}

class _CrearRutaSinGuiaPaginaState extends State<CrearRutaSinGuiaPagina> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _puntoEncuentroController = TextEditingController();

  List<Lugar> _lugaresSeleccionados = [];
  int _cuposTotales = 1;
  String _preferenciaPrivacidad = 'publica';
  DateTime? _fechaEvento;
  String _categoria = 'familiar';
  bool _creando = false;

  final List<String> _categorias = [
    'familiar',
    'cultural',
    'aventura',
    'naturaleza',
    'extrema',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _puntoEncuentroController.dispose();
    super.dispose();
  }

  String _generarCodigoAcceso() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
          (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _mostrarCodigoAcceso(String codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text('Ruta Privada Creada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu ruta ha sido creada exitosamente. Comparte este código con tus invitados:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    codigo,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Código copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar código'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Guarda este código, lo necesitarás para que otros se unan a tu ruta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/rutas');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Ruta Personalizada'),
        backgroundColor: colorPrimario,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSeccion('📍 Lugares a Visitar', [_buildSelectorLugares()]),
            const SizedBox(height: 20),
            _buildSeccion('📝 Información Básica', [
              _buildCampoTexto(
                controller: _nombreController,
                label: 'Nombre de la ruta',
                hint: 'Ej: Tour por el Valle Sagrado',
                icono: Icons.title,
                validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 15),
              _buildCampoTexto(
                controller: _descripcionController,
                label: 'Descripción',
                hint: 'Describe tu ruta...',
                icono: Icons.description,
                maxLineas: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
            ]),
            const SizedBox(height: 20),
            _buildSeccion('🎯 Categoría', [_buildSelectorCategoria()]),
            const SizedBox(height: 20),
            _buildSeccion('📅 Detalles del Viaje', [
              _buildSelectorFecha(),
              const SizedBox(height: 15),
              _buildCampoTexto(
                controller: _puntoEncuentroController,
                label: 'Punto de Encuentro',
                hint: 'Ej: Plaza de Armas',
                icono: Icons.location_on,
              ),
              const SizedBox(height: 15),
              _buildSelectorCupos(),
              const SizedBox(height: 15),
              _buildCampoTexto(
                controller: _precioController,
                label: 'Precio por Persona',
                hint: 'Ej: 50',
                icono: Icons.attach_money,
                teclado: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
            ]),
            const SizedBox(height: 20),
            _buildSeccion('🔒 Privacidad', [_buildSelectorPrivacidad()]),
            const SizedBox(height: 30),
            _buildBotonCrear(colorPrimario),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icono,
    int maxLineas = 1,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLineas,
      keyboardType: teclado,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSelectorLugares() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _mostrarSelectorLugares,
          icon: const Icon(Icons.add_location),
          label: const Text('Agregar Lugares'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_lugaresSeleccionados.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lugaresSeleccionados.map((lugar) {
              return Chip(
                label: Text(lugar.nombre),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _lugaresSeleccionados.remove(lugar);
                  });
                },
              );
            }).toList(),
          ),
        ],
        if (_lugaresSeleccionados.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Selecciona al menos un lugar',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectorCategoria() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categorias.map((cat) {
        final isSelected = _categoria == cat;
        return ChoiceChip(
          label: Text(cat.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _categoria = cat);
          },
          selectedColor: _getColorCategoria(cat).withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? _getColorCategoria(cat) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorFecha() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _fechaEvento == null
                    ? 'Seleccionar fecha del evento'
                    : _formatearFecha(_fechaEvento!),
                style: TextStyle(
                  color: _fechaEvento == null ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCupos() {
    return Row(
      children: [
        const Icon(Icons.people),
        const SizedBox(width: 15),
        const Text('Cupos totales:'),
        const Spacer(),
        IconButton(
          onPressed: _cuposTotales > 1
              ? () => setState(() => _cuposTotales--)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$_cuposTotales',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => setState(() => _cuposTotales++),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildSelectorPrivacidad() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Pública'),
          subtitle: const Text('Cualquiera puede inscribirse'),
          value: 'publica',
          groupValue: _preferenciaPrivacidad,
          onChanged: (value) {
            setState(() => _preferenciaPrivacidad = value!);
          },
        ),
        RadioListTile<String>(
          title: const Text('Privada'),
          subtitle: const Text('Solo con código de acceso'),
          value: 'privada',
          groupValue: _preferenciaPrivacidad,
          onChanged: (value) {
            setState(() => _preferenciaPrivacidad = value!);
          },
        ),
        if (_preferenciaPrivacidad == 'privada') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Se generará un código único automáticamente que podrás compartir con tus invitados',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotonCrear(Color colorPrimario) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _creando ? null : _crearRuta,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _creando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Crear Ruta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _mostrarSelectorLugares() {
    final lugaresVM = context.read<LugaresVM>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Lugares'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: lugaresVM.lugaresTotales.isEmpty
              ? const Center(child: Text('No hay lugares disponibles'))
              : ListView.builder(
            itemCount: lugaresVM.lugaresTotales.length,
            itemBuilder: (context, index) {
              final lugar = lugaresVM.lugaresTotales[index];
              final isSelected = _lugaresSeleccionados.contains(lugar);

              return CheckboxListTile(
                title: Text(lugar.nombre),
                subtitle: Text(lugar.descripcion, maxLines: 2),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected!) {
                      _lugaresSeleccionados.add(lugar);
                    } else {
                      _lugaresSeleccionados.remove(lugar);
                    }
                  });
                  Navigator.pop(context);
                  _mostrarSelectorLugares();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaEvento = fecha);
    }
  }

  // --- LÓGICA DE CREACIÓN CORREGIDA ---
  Future<void> _crearRuta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lugaresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un lugar')),
      );
      return;
    }

    setState(() => _creando = true);

    try {
      final vmAuth = context.read<AutenticacionVM>();
      final vmRutas = context.read<RutasVM>();

      // Validar autenticación
      if (vmAuth.usuarioActual == null) {
        throw Exception('Debes iniciar sesión para crear una ruta');
      }

      final userId = vmAuth.usuarioActual!.id;

      // Generar código para ruta privada
      String? codigoAcceso;
      if (_preferenciaPrivacidad == 'privada') {
        codigoAcceso = _generarCodigoAcceso();
      }

      // Crear ruta usando datos del primer lugar seleccionado
      final lugarPrincipal = _lugaresSeleccionados.first;

      // --- ¡MAPA DE DATOS CORREGIDO! ---
      final datosRuta = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'categoria': _categoria,
        'precio': double.tryParse(_precioController.text) ?? 0,

        // CORRECCIÓN 1: Usar 'cupos' (repo) en lugar de 'cupos_totales'
        'cupos': _cuposTotales,

        'dias': 1,
        'visible': true,
        'es_privada': _preferenciaPrivacidad == 'privada',
        'guia_id': userId,
        'url_imagen_principal': lugarPrincipal.urlImagen,

        // CORRECCIÓN 2: Usar 'lugaresIds' (repo) en lugar de 'lugares_incluidos_ids'
        'lugaresIds': _lugaresSeleccionados.map((l) => l.id).toList(),

        // CORRECCIÓN 3: ¡AGREGAR COORDENADAS PARA OSRM!
        'puntos_coordenadas': _lugaresSeleccionados.map((l) => LatLng(l.latitud, l.longitud)).toList(),

        'fecha_evento': _fechaEvento?.toIso8601String(),
        'punto_encuentro': _puntoEncuentroController.text.isNotEmpty
            ? _puntoEncuentroController.text
            : null,
        'estado': 'convocatoria',
        if (codigoAcceso != null) 'codigo_acceso': codigoAcceso,
      };

      print('📤 Datos a enviar: $datosRuta');

      await vmRutas.crearRuta(datosRuta);

      setState(() => _creando = false);

      if (mounted) {
        if (codigoAcceso != null) {
          _mostrarCodigoAcceso(codigoAcceso);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ruta creada exitosamente'),
              duration: Duration(seconds: 2),
            ),
          );
          context.go('/rutas');
        }
      }
    } catch (e) {
      setState(() => _creando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Color _getColorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'familiar': return const Color(0xFF4CAF50);
      case 'cultural': return const Color(0xFF3F51B5);
      case 'aventura': return const Color(0xFFFF9800);
      case 'naturaleza': return const Color(0xFF9C27B0);
      case 'extrema': return const Color(0xFFD32F2F);
      default: return Colors.grey;
    }
  }
}