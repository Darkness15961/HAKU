// --- PIEDRA 10 (RUTAS): EL "MENÚ" DE CREAR RUTA (¡DISEÑO AMIGABLE!) ---
//
// Esta es la pantalla (el "Edificio") que corresponde
// a la dirección "/crear-ruta".
//
// ¡USA TU DISEÑO "AMIGABLE"! (Stack, Footer, ReorderableList)
//
// Está conectada al "Mesero" (RutasVM) solo en el
// botón de "Guardar".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // Para filtrar números

// --- MVVM: IMPORTACIONES ---
// 1. Importamos el "Mesero de Rutas" (ViewModel)
import '../vista_modelos/rutas_vm.dart';
// 2. Importamos las "Recetas" (Entidades)
//    (Usaremos la "Receta" de Lugar para el selector)
import '../../../inicio/dominio/entidades/lugar.dart';

// Helper: Clase simple para representar un Lugar en la Ruta
// (Esta es la clase de tu "molde". ¡La mantenemos
// para que el formulario funcione!)
class RouteLocation {
  final String name;
  // TODO: Cambiar esto a un objeto "Lugar" real
  // final Lugar lugar;
  final String imagePath; // (Simulación)
  int durationMinutes;

  RouteLocation({
    required this.name,
    required this.imagePath,
    this.durationMinutes = 60,
  });
}

// 1. El "Edificio" (La Pantalla)
//    (Cambiamos el nombre a "CrearRutaPagina"
//    para que coincida con nuestro "GPS" app_rutas.dart)
class CrearRutaPagina extends StatefulWidget {
  const CrearRutaPagina({super.key});

  @override
  State<CrearRutaPagina> createState() => _CrearRutaPaginaState();
}

class _CrearRutaPaginaState extends State<CrearRutaPagina> {
  // --- Estado Local de la UI ---
  // (¡Mantenemos todo tu estado local de formulario!)
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController(text: '0');
  final TextEditingController _diasCtrl = TextEditingController(text: '1');
  final TextEditingController _newLocationNameController =
  TextEditingController();

  // (El "key" para validar el formulario)
  final _formKey = GlobalKey<FormState>();

  String _selectedDifficulty = 'medio'; // (Sin tilde, como en nuestro VM)
  String _visibility = 'Privada'; // Visibilidad

  // (Tu lista de lugares seleccionados)
  List<RouteLocation> _locations = [];

  // --- Lógica de Envío de Formulario (¡CONECTADA A MVVM!) ---
  Future<void> _submitCrearRuta() async {
    // 1. Validamos el formulario
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

    // 2. Creamos el "mapa" (JSON) de datos
    //    que nuestra "Cocina Falsa" (Mock) espera
    final datosRuta = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
      'cupos': 20, // (Simulado, ¡falta este campo en tu diseño!)
      'dificultad': _selectedDifficulty,
      'visible': _visibility == 'Pública',
      // (Mapeamos tu lista de objetos a una lista simple de nombres)
      'lugares': _locations.map((loc) => loc.name).toList(),
    };

    // 3. --- ¡ARREGLO! (Usamos try/catch) ---
    try {
      if (!mounted) return;

      // 4. (Llamamos al "Mesero")
      //    Le damos la "ORDEN 7" (crearRuta)
      await context.read<RutasVM>().crearRuta(datosRuta);

      // 5. ¡ÉXITO!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ruta guardada con éxito! (Simulado)'),
            backgroundColor: Colors.green,
          ),
        );
        // 6. Volvemos a la pantalla anterior
        context.pop();
      }
    } catch (e) {
      // 7. ¡ERROR!
      if (mounted) {
        final errorMsg = context.read<RutasVM>().error ??
            'Ocurrió un error desconocido.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Tus Métodos de UI (¡Perfectos!) ---
  @override
  void initState() {
    super.initState();
    // (Añadimos el listener para el formulario)
    _nombreCtrl.addListener(() => setState(() {}));
    _descripcionCtrl.addListener(() => setState(() {}));
    _precioCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _diasCtrl.dispose();
    _newLocationNameController.dispose();
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

  void _addLocationFromText() {
    final name = _newLocationNameController.text.trim();
    if (name.isEmpty) return;
    final newLocation = RouteLocation(
      name: name,
      imagePath: 'https://placehold.co/100x100/grey/FFFFFF?text=Lugar',
      durationMinutes: 45,
    );
    setState(() {
      _locations.add(newLocation);
      _newLocationNameController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lugar "$name" añadido al itinerario.')),
    );
  }

  // Condición de Guardado (¡Conectada al "Mesero"!)
  bool _canSave(RutasVM vmRutas) {
    // 1. Revisa si el "Mesero" está ocupado
    if (vmRutas.estaCargando) return false;
    // 2. Revisa tu lógica local
    return _nombreCtrl.text.isNotEmpty &&
        _descripcionCtrl.text.isNotEmpty &&
        _locations.isNotEmpty &&
        (double.tryParse(_precioCtrl.text) ?? 0.0) >= 0;
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (`watch`) al "Mesero"
    final vmRutas = context.watch<RutasVM>();
    final canSave = _canSave(vmRutas); // Revisamos si se puede guardar

    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Crear Ruta', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // --- ¡BOTÓN DE GUARDAR CONECTADO! ---
          TextButton(
            // 1. Llama a nuestra lógica MVVM
            onPressed: canSave ? _submitCrearRuta : null,
            child: Text(
              'Guardar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // 2. Se deshabilita si "canSave" es falso
                color: canSave ? Colors.indigo : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        // --- ¡TU DISEÑO DE STACK Y FOOTER! ---
        child: Stack(
          children: [
            // 1. Contenido Principal Desplazable
            SingleChildScrollView(
              // (Usamos un "padding" para que el footer
              // no tape el último item)
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteDetailsInputs(),
                  const SizedBox(height: 16),
                  _buildRouteProperties(),
                  const SizedBox(height: 16),
                  _buildLocationList(),
                  const SizedBox(height: 16),
                  _buildAddLocationSection(),
                  const SizedBox(height: 24),
                  _buildVisibilityTools(),
                ],
              ),
            ),

            // 2. FOOTER Flotante Fijo (¡Tu diseño!)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFixedFooter(),
            ),
          ],
        ),
      ),
    );
  }

  // --- TUS WIDGETS AUXILIARES (¡Perfectos!) ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildRouteDetailsInputs() {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildNumericInput(
                  'Días', _diasCtrl, Icons.calendar_today, isInteger: true),
            ),
            const SizedBox(width: 16),
            Expanded(
              // --- ¡ARREGLO DE DISEÑO (Tu Petición)! ---
              // Ícono de moneda local, no de dólar
              child: _buildNumericInput('Precio (S/) *', _precioCtrl,
                  Icons.local_atm, isInteger: false),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              // (Valores sin tilde, para que coincidan con el VM)
              items: ['facil', 'medio', 'dificil'].map((String value) {
                return DropdownMenuItem<String>(
                  // Mostramos el texto amigable
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
    );
  }

  Widget _buildNumericInput(String label, TextEditingController controller,
      IconData icon, {required bool isInteger}) {
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
            prefixIcon: Icon(icon, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Este campo es obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildAddLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Añadir Lugar (Escribe y Añade)'),
        TextField(
          controller: _newLocationNameController,
          onSubmitted: (_) => _addLocationFromText(), // Permite añadir con Enter
          decoration: InputDecoration(
            hintText: 'Escribe el nombre del lugar...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_location_alt, color: Colors.indigo),
              onPressed: _addLocationFromText,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
            'El Guía escribe el nombre y lo añade. (Simulación)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

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

  Widget _buildLocationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Lugares de la ruta (${_locations.length})'),
        const SizedBox(height: 8),
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
                // (Usamos "ValueKey" para que la "key" sea única)
                key: ValueKey(location.name + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _locations.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${location.name} eliminado.')));
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

  Widget _buildLocationCard(BuildContext context, RouteLocation location) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ReorderableDragStartListener(
                index: _locations.indexOf(location),
                child: Icon(Icons.drag_indicator, color: Colors.grey.shade600)),
            const SizedBox(width: 8),
            Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey[300]),
                child: const Icon(Icons.landscape, size: 24, color: Colors.grey)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: TextEditingController(
                              text: location.durationMinutes.toString()),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: UnderlineInputBorder()),
                          onChanged: (value) {
                            location.durationMinutes = int.tryParse(value) ?? 0;
                            // (No necesitamos setState, el footer lo recalcula)
                          },
                        ),
                      ),
                      const Text('min',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _locations.remove(location);
                  });
                }),
          ],
        ),
      ),
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
          foregroundColor: isSelected ? Colors.indigo : Colors.grey.shade600,
          elevation: isSelected ? 2 : 0,
          shadowColor: Colors.indigo.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFixedFooter() {
    // (Calculamos la duración total)
    final totalDurationMinutes =
    _locations.fold(0, (sum, item) => sum + item.durationMinutes);
    String formattedDuration;
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0) {
      formattedDuration = '${hours}h ${minutes}m';
    } else {
      formattedDuration = '${minutes}m';
    }

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duración estimada',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(formattedDuration,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Días totales',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${_diasCtrl.text} día(s)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Previsualizando Ruta...')));
            },
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text('Previsualizar',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }
}

