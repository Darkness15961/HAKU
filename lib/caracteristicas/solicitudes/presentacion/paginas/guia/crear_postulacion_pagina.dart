import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';
import '../../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../dominio/entidades/postulacion_guia.dart';

class CrearPostulacionPagina extends StatefulWidget {
  final dynamic solicitud;

  const CrearPostulacionPagina({Key? key, required this.solicitud})
    : super(key: key);

  @override
  State<CrearPostulacionPagina> createState() => _CrearPostulacionPaginaState();
}

class _CrearPostulacionPaginaState extends State<CrearPostulacionPagina> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _itinerarioController = TextEditingController();

  String _moneda = 'PEN';
  final List<String> _serviciosSeleccionados = [];
  bool _creando = false;

  final List<String> _serviciosDisponibles = [
    'Transporte privado',
    'Transporte compartido',
    'Almuerzo',
    'Cena',
    'Entradas a sitios',
    'Guía certificado',
    'Seguro de viaje',
    'Agua y snacks',
    'Fotografía profesional',
  ];

  @override
  void dispose() {
    _precioController.dispose();
    _descripcionController.dispose();
    _itinerarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorPrimario.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colorPrimario),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSolicitudInfo(colorPrimario),
                      const SizedBox(height: 20),
                      _buildSeccion('💰 Tu Propuesta Económica', [
                        _buildSelectorMoneda(),
                        const SizedBox(height: 15),
                        _buildCampoPrecio(),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('📝 Descripción de tu Propuesta', [
                        _buildCampoTexto(
                          controller: _descripcionController,
                          label: 'Descripción',
                          hint:
                              'Describe tu propuesta, qué incluye, por qué eres el mejor guía...',
                          maxLineas: 5,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Campo requerido' : null,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('🗓️ Itinerario Detallado', [
                        _buildCampoTexto(
                          controller: _itinerarioController,
                          label: 'Itinerario',
                          hint:
                              '8:00 AM - Recojo en hotel\n9:00 AM - Primera parada...',
                          maxLineas: 8,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('✅ Servicios Incluidos', [
                        _buildSelectorServicios(),
                      ]),
                      const SizedBox(height: 30),
                      _buildBotonEnviar(colorPrimario),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enviar Propuesta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudInfo(Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorPrimario.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorPrimario.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.solicitud.titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 5),
              Text('${widget.solicitud.numeroPersonas} personas'),
              const SizedBox(width: 20),
              if (widget.solicitud.presupuestoMaximo != null) ...[
                Icon(Icons.attach_money, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 5),
                Text(
                  'Presupuesto: S/ ${widget.solicitud.presupuestoMaximo!.toStringAsFixed(0)}',
                ),
              ],
            ],
          ),
        ],
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

  Widget _buildSelectorMoneda() {
    return Row(
      children: [
        const Text('Moneda:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('PEN (S/)'),
                  value: 'PEN',
                  groupValue: _moneda,
                  onChanged: (value) => setState(() => _moneda = value!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('USD (\$)'),
                  value: 'USD',
                  groupValue: _moneda,
                  onChanged: (value) => setState(() => _moneda = value!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampoPrecio() {
    return TextFormField(
      controller: _precioController,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v?.isEmpty ?? true) return 'Campo requerido';
        if (double.tryParse(v!) == null) return 'Ingresa un número válido';
        if (double.parse(v) <= 0) return 'El precio debe ser mayor a 0';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Precio Ofertado',
        hintText: 'Ej: 450',
        prefixIcon: Icon(
          _moneda == 'PEN' ? Icons.currency_exchange : Icons.attach_money,
        ),
        prefixText: _moneda == 'PEN' ? 'S/ ' : '\$ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLineas = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLineas,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSelectorServicios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona los servicios que incluyes:',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _serviciosDisponibles.map((servicio) {
            final seleccionado = _serviciosSeleccionados.contains(servicio);
            return FilterChip(
              label: Text(servicio),
              selected: seleccionado,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _serviciosSeleccionados.add(servicio);
                  } else {
                    _serviciosSeleccionados.remove(servicio);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBotonEnviar(Color colorPrimario) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _creando ? null : _enviarPropuesta,
        icon: _creando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(_creando ? 'Enviando...' : 'Enviar Propuesta'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _enviarPropuesta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un servicio incluido'),
        ),
      );
      return;
    }

    setState(() => _creando = true);

    final vmAuth = context.read<AutenticacionVM>();
    final vmSolicitudes = context.read<SolicitudesVM>();

    final postulacion = PostulacionGuia(
      id: '',
      solicitudId: widget.solicitud.id,
      guiaId: vmAuth.usuarioActual!.id,
      precioOfertado: double.parse(_precioController.text),
      moneda: _moneda,
      descripcionPropuesta: _descripcionController.text,
      itinerarioDetallado: _itinerarioController.text.isNotEmpty
          ? _itinerarioController.text
          : null,
      serviciosIncluidos: _serviciosSeleccionados,
      estado: 'pendiente',
      fechaPostulacion: DateTime.now(),
    );

    try {
      final exito = await vmSolicitudes.crearPostulacion(postulacion);

      setState(() => _creando = false);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Propuesta enviada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _creando = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ ${e.toString()}')));
      }
    }
  }
}
