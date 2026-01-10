import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormularioInfoBasica extends StatefulWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController cuposCtrl;
  final TextEditingController diasCtrl;
  final String selectedDifficulty;
  final Function(String) onDifficultyChanged;
  final int minCupos; // Para validar contra inscritos actuales

  const FormularioInfoBasica({
    super.key,
    required this.nombreCtrl,
    required this.descripcionCtrl,
    required this.precioCtrl,
    required this.cuposCtrl,
    required this.diasCtrl,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
    this.minCupos = 0,
  });

  @override
  State<FormularioInfoBasica> createState() => _FormularioInfoBasicaState();
}

class _FormularioInfoBasicaState extends State<FormularioInfoBasica> {
  
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildNumericInput(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isInteger = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        TextFormField(
          controller: ctrl,
          keyboardType: isInteger
               ? TextInputType.number
               : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Obligatorio';
            if (isInteger) {
              final n = int.tryParse(v);
              if (n == null || n < 0) return 'Inválido';
            } else {
              final n = double.tryParse(v);
              if (n == null || n < 0) return 'Inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NOMBRE
        _buildInputLabel('Nombre de la ruta *'),
        TextFormField(
          controller: widget.nombreCtrl,
          decoration: InputDecoration(
            hintText: 'Ej. Valle Sagrado - 1 día',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'El nombre es obligatorio' : null,
        ),
        const SizedBox(height: 16),

        // DESCRIPCIÓN
        _buildInputLabel('Descripción *'),
        TextFormField(
          controller: widget.descripcionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Detalles sobre la experiencia, qué incluye, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'La descripción es obligatoria' : null,
        ),
        const SizedBox(height: 24),

        // PROPIEDADES (PRECIO, CUPOS, DÍAS, CATEGORÍA)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildNumericInput(
                'Precio (S/) *',
                widget.precioCtrl,
                Icons.monetization_on,
                isInteger: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Cupos *'),
                  TextFormField(
                    controller: widget.cuposCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    validator: (v) {
                       final n = int.tryParse(v ?? '');
                       if (n == null || n < 1) return 'Mín 1';
                       if (n < widget.minCupos) return 'Min ${widget.minCupos}';
                       return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DÍAS Y CATEGORÍA
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildNumericInput(
                'Días *',
                widget.diasCtrl,
                Icons.calendar_today,
                isInteger: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Dificultad *'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.selectedDifficulty,
                        isExpanded: true,
                        items: [
                          'Familiar',
                          'Cultural',
                          'Aventura',
                          '+18',
                          'Naturaleza',
                          'Extrema'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            widget.onDifficultyChanged(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
