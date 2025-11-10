// --- PIEDRA 10 (RUTAS): EL "MENÚ" DE CREAR RUTA (VERSIÓN ELEGANTE Y SIMPLIFICADA) ---
//
// 1. (DISEÑO SIMPLIFICADO): Se eliminó el campo de "minutos" de la tarjeta del lugar.
// 2. (DISEÑO SIMPLIFICADO): Se eliminó el cálculo de "Duración" del footer.
// 3. (LÓGICA SIMPLIFICADA): El formulario ya no envía 'duracionTotalMinutos'.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/rutas_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';
// ¡Importamos la Receta para el 'extra' en app_rutas.dart!
import '../../dominio/entidades/ruta.dart';

// Helper: Clase simple para representar un Lugar en la Ruta
// --- ¡SIMPLIFICADO! Ya no tiene 'durationMinutes' ---
class RouteLocation {
  final Lugar lugar;
  RouteLocation({ required this.lugar });
}

// 1. El "Edificio" (La Pantalla)
class CrearRutaPagina extends StatefulWidget {
  // --- ¡ACOMPLADO! Acepta la ruta para "Editar" ---
  final Ruta? ruta;

  const CrearRutaPagina({
    super.key,
    this.ruta, // <-- Acepta la ruta (nulable)
  });

  @override
  State<CrearRutaPagina> createState() => _CrearRutaPaginaState();
}

class _CrearRutaPaginaState extends State<CrearRutaPagina> {
  // --- Estado Local de la UI ---
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController(text: '0');
  final TextEditingController _diasCtrl = TextEditingController(text: '1');
  final TextEditingController _cuposCtrl = TextEditingController(text: '10');

  final _formKey = GlobalKey<FormState>();

  String _selectedDifficulty = 'medio';
  String _visibility = 'Privada';
  bool _estaGuardando = false;

  List<RouteLocation> _locations = [];

  // --- Lógica de Envío de Formulario (¡SIMPLIFICADA!) ---
  Future<void> _submitCrearRuta() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes añadir al menos un lugar al itinerario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() { _estaGuardando = true; });

    final String diasText = _diasCtrl.text.isEmpty ? '1' : _diasCtrl.text;
    final String cuposText = _cuposCtrl.text.isEmpty ? '10' : _cuposCtrl.text;

    final Map<String, dynamic> datosRuta = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
      'cupos': int.tryParse(cuposText) ?? 10,
      'dificultad': _selectedDifficulty,
      'visible': _visibility == 'Pública',
      'dias': int.tryParse(diasText) ?? 1,
      // 'duracionTotalMinutos' YA NO SE ENVÍA
      'lugaresIds': _locations.map((loc) => loc.lugar.id).toList(),
      'lugaresNombres': _locations.map((loc) => loc.lugar.nombre).toList(),
    };

    try {
      if (!mounted) return;
      await context.read<RutasVM>().crearRuta(datosRuta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ruta guardada con éxito! (Simulado)'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _estaGuardando = false; });
      }
    }
  }


  // --- MÉTODO DEL SELECTOR (Corregido y Simplificado) ---
  void _mostrarSelectorLugares() {
    final vmLugares = context.read<LugaresVM>();
    final lugaresDisponibles = vmLugares.lugaresTotales;
    List<String> idsSeleccionados = _locations.map((rl) => rl.lugar.id).toList();

    Set<String> seleccionTemporal = idsSeleccionados.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Header del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seleccione Lugares', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lugaresDisponibles.length,
                      itemBuilder: (context, index) {
                        final lugar = lugaresDisponibles[index];
                        final estaSeleccionado = seleccionTemporal.contains(lugar.id);
                        return CheckboxListTile(
                          title: Text(lugar.nombre),
                          subtitle: Text(lugar.categoria),
                          value: estaSeleccionado,
                          onChanged: (bool? seleccionado) {
                            setModalState(() {
                              if (seleccionado == true) {
                                seleccionTemporal.add(lugar.id);
                              } else {
                                seleccionTemporal.remove(lugar.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // Footer del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0, -2))]
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Confirmar (${seleccionTemporal.length}) Lugares'),
                      onPressed: () {
                        setState(() {
                          _locations = seleccionTemporal.map((id) {
                            final lugarEncontrado = lugaresDisponibles.firstWhere((l) => l.id == id);
                            // ¡SIMPLIFICADO! Ya no pasamos 'durationMinutes'
                            return RouteLocation(lugar: lugarEncontrado);
                          }).toList();
                        });
                        Navigator.of(modalContext).pop();
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Métodos de UI (se mantienen) ---
  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(() => setState(() {}));
    _descripcionCtrl.addListener(() => setState(() {}));
    _precioCtrl.addListener(() => setState(() {}));
    _diasCtrl.addListener(() => setState(() {}));
    _cuposCtrl.addListener(() => setState(() {}));

    // (Lógica para "Editar Ruta")
    if (widget.ruta != null) {
      _nombreCtrl.text = widget.ruta!.nombre;
      _descripcionCtrl.text = widget.ruta!.descripcion;
      _precioCtrl.text = widget.ruta!.precio.toString();
      _diasCtrl.text = widget.ruta!.dias.toString();
      _cuposCtrl.text = widget.ruta!.cuposTotales.toString();
      _selectedDifficulty = widget.ruta!.dificultad;
      _visibility = widget.ruta!.visible ? 'Pública' : 'Privada';

      // (Pre-cargamos los lugares si estamos editando)
      // (Necesitamos el LugaresVM para esto)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vmLugares = context.read<LugaresVM>();
        _locations = widget.ruta!.lugaresIncluidosIds.map((id) {
          final lugar = vmLugares.lugaresTotales.firstWhere((l) => l.id == id);
          return RouteLocation(lugar: lugar);
        }).toList();
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _diasCtrl.dispose();
    _cuposCtrl.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RouteLocation item = _locations.removeAt(oldIndex);
      _locations.insert(newIndex, item);
    });
  }

  bool _canSave(RutasVM vmRutas) {
    if (vmRutas.estaCargando) return false;
    return _nombreCtrl.text.isNotEmpty &&
        _descripcionCtrl.text.isNotEmpty &&
        _locations.isNotEmpty &&
        (double.tryParse(_precioCtrl.text) ?? 0.0) >= 0;
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    final vmRutas = context.watch<RutasVM>();
    final canSave = _canSave(vmRutas);
    final bool modoEdicion = widget.ruta != null;

    return Scaffold(
      appBar: AppBar(
        title:
        Text(modoEdicion ? 'Editar Ruta' : 'Crear Ruta', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _estaGuardando
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 3))),
          )
              : TextButton(
            onPressed: canSave ? _submitCrearRuta : null,
            child: Text(
              'Guardar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: canSave ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteDetailsInputs(),
                  const Divider(height: 32),
                  _buildRouteProperties(),
                  const Divider(height: 32),
                  _buildLocationList(),
                  const Divider(height: 32),
                  _buildVisibilityTools(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFixedFooter(), // <-- ¡SIMPLIFICADO!
            ),
          ],
        ),
      ),
    );
  }

  // --- TUS WIDGETS AUXILIARES (¡Adaptados!) ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildRouteDetailsInputs() {
    // (Sin cambios)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Nombre de la ruta *'),
        TextFormField(
          controller: _nombreCtrl,
          decoration: InputDecoration(
            hintText: 'Ej. Valle Sagrado - 1 día',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'El nombre es obligatorio' : null,
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Descripción *'),
        TextFormField(
          controller: _descripcionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Detalles sobre la experiencia, qué incluye, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'La descripción es obligatoria' : null,
        ),
      ],
    );
  }

  Widget _buildRouteProperties() {
    // (Sin cambios, se mantiene tu diseño)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildNumericInput('Precio (S/) *', _precioCtrl,
                  Icons.monetization_on, isInteger: false),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildNumericInput(
                  'Cupos *', _cuposCtrl, Icons.people, isInteger: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildNumericInput(
                  'Días *', _diasCtrl, Icons.calendar_today, isInteger: true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Dificultad *'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          items: ['facil', 'medio', 'dificil'].map((String value) {
                            return DropdownMenuItem<String>(
                                child: Text(value[0].toUpperCase() + value.substring(1)),
                                value: value);
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDifficulty = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumericInput(String label, TextEditingController controller,
      IconData icon, {required bool isInteger}) {
    // (Sin cambios)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
      ],
    );
  }

  // --- WIDGET DE LISTA DE LUGARES (Sin cambios) ---
  Widget _buildLocationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Lugares del Itinerario (${_locations.length}) *'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Añadir / Editar Lugares de la Lista'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          onPressed: _mostrarSelectorLugares,
        ),
        const SizedBox(height: 16),
        if (_locations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text('Aún no has añadido lugares.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _locations.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final location = _locations[index];
              return Dismissible(
                key: ValueKey(location.lugar.id + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _locations.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${location.lugar.nombre} eliminado.')));
                },
                background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade400,
                    child: const Icon(Icons.delete, color: Colors.white)),
                child: _buildLocationCard(context, location),
              );
            },
          ),
      ],
    );
  }

  // --- WIDGET DE TARJETA DE LUGAR (¡SIMPLIFICADO!) ---
  Widget _buildLocationCard(BuildContext context, RouteLocation routeLocation) {
    final lugar = routeLocation.lugar;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ReorderableDragStartListener(
                index: _locations.indexOf(routeLocation),
                child: Icon(Icons.drag_indicator, color: Colors.grey.shade600)),
            const SizedBox(width: 8),
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                    lugar.urlImagen,
                    width: 60, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(
                        width: 60, height: 50, color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 24, color: Colors.grey)
                    )
                )),
            const SizedBox(width: 12),
            // --- ¡SIMPLIFICADO! Se quitó el campo de minutos ---
            Expanded(
              child: Text(lugar.nombre,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DE VISIBILIDAD (Sin cambios) ---
  Widget _buildVisibilityTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Visibilidad de la Ruta'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: _buildVisibilityButton('Privada')),
              Expanded(child: _buildVisibilityButton('Pública')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
            _visibility == 'Pública'
                ? 'Las rutas públicas requieren aprobación del administrador.'
                : 'Solo tú puedes ver esta ruta.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildVisibilityButton(String label) {
    final bool isSelected = _visibility == label;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _visibility = label;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : Colors.transparent,
          foregroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
          elevation: isSelected ? 2 : 0,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- WIDGET DE FOOTER (¡SIMPLIFICADO!) ---
  Widget _buildFixedFooter() {
    // ¡Se eliminó el cálculo de 'totalDurationMinutes'!

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Días
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Días',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${_diasCtrl.text} día(s)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // Cupos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cupos',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${_cuposCtrl.text} pers.',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // Botón Previsualizar
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Previsualizando Ruta... (Próximamente)')));
            },
            child: const Icon(Icons.visibility, color: Colors.white),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }
}

// Extensión (se mantiene)
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}