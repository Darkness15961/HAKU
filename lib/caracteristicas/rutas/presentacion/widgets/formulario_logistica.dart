import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormularioLogistica extends StatelessWidget {
  final TextEditingController whatsappCtrl;
  final TextEditingController puntoEncuentroCtrl;
  final TextEditingController equipamientoCtrl;
  final DateTime? fechaEvento;
  final DateTime? fechaCierre;
  final Function(DateTime?) onFechaEventoChanged;
  final Function(DateTime?) onFechaCierreChanged;
  
  const FormularioLogistica({
    super.key,
    required this.whatsappCtrl,
    required this.puntoEncuentroCtrl,
    required this.equipamientoCtrl,
    required this.fechaEvento,
    required this.fechaCierre,
    required this.onFechaEventoChanged,
    required this.onFechaCierreChanged,
  });

  Future<void> _seleccionarFechaHora(
      BuildContext context, {
        required DateTime? initialDate,
        required Function(DateTime) onSelected,
      }) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now, // Permitir hoy
      lastDate: lastDate,
    );

    if (date == null) return;

    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? now),
    );

    if (time == null) return;

    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. FECHAS (Row)
        Row(
          children: [
            Expanded(
              child: _FechaInput(
                label: 'Fecha del Evento',
                value: fechaEvento,
                onTap: () => _seleccionarFechaHora(
                  context,
                  initialDate: fechaEvento,
                  onSelected: (d) => onFechaEventoChanged(d),
                ),
                icon: Icons.event,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FechaInput(
                label: 'Cierre Inscripciones',
                value: fechaCierre,
                onTap: () => _seleccionarFechaHora(
                  context,
                  initialDate: fechaCierre,
                  onSelected: (d) => onFechaCierreChanged(d),
                ),
                icon: Icons.timer_off_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. PUNTO DE ENCUENTRO
        TextFormField(
          controller: puntoEncuentroCtrl,
          decoration: const InputDecoration(
            labelText: 'Punto de Encuentro',
            hintText: 'Ej. Plaza de Armas, Pileta Central',
            prefixIcon: Icon(Icons.place_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),

        // 3. ENLACE WHATSAPP
        TextFormField(
          controller: whatsappCtrl,
          decoration: const InputDecoration(
            labelText: 'Enlace Grupo WhatsApp',
            hintText: 'https://chat.whatsapp.com/...',
            prefixIcon: Icon(Icons.chat_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          // Opcional: Validar que sea url
        ),
        const SizedBox(height: 16),

        // 4. EQUIPAMIENTO (Texto simple por ahora)
        TextFormField(
          controller: equipamientoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Equipamiento Necesario',
            hintText: 'Ej. Botas de trekking, Casco, Bloqueador solar (Separar por comas)',
            prefixIcon: Icon(Icons.backpack_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _FechaInput extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final IconData icon;

  const _FechaInput({
    required this.label,
    required this.value,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Seleccionar'
        : DateFormat('dd/MM/yyyy HH:mm').format(value!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
