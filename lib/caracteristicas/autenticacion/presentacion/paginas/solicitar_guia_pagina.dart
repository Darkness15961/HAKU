// --- PIEDRA 5 (BLOQUE 5): EL "MENÚ" DE SOLICITUD DE GUÍA ---
//
// Esta es la pantalla (el "Edificio") que corresponde
// a la dirección "/solicitar-guia".
//
// Es un formulario que le permite al Turista
// enviar la "ORDEN 5" (solicitarSerGuia) al "Mesero de Seguridad".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// 1. Importamos el "Mesero de Seguridad" (ViewModel)
import '../vista_modelos/autenticacion_vm.dart';

class SolicitarGuiaPagina extends StatefulWidget {
  const SolicitarGuiaPagina({super.key});

  @override
  State<SolicitarGuiaPagina> createState() => _SolicitarGuiaPaginaState();
}

class _SolicitarGuiaPaginaState extends State<SolicitarGuiaPagina> {
  // --- Estado Local de la UI ---
  //
  // Controladores para leer el texto de los campos
  final TextEditingController _experienciaCtrl = TextEditingController();
  final TextEditingController _certificadoCtrl = TextEditingController();

  // "Key" para validar el formulario
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // "Limpiamos" los controladores
    _experienciaCtrl.dispose();
    _certificadoCtrl.dispose();
    super.dispose();
  }

  // --- Lógica de Envío de Formulario ---
  Future<void> _submitSolicitud() async {
    // 1. Validamos el formulario
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Obtenemos los textos de los campos
    final experiencia = _experienciaCtrl.text;
    final certificado = _certificadoCtrl.text;

    // 3. --- MVVM: ORDEN AL "MESERO" ---
    //    Le damos la "ORDEN 5" (ver el VM de Auth) al "Mesero de Seguridad"
    final bool exito = await context.read<AutenticacionVM>().solicitarSerGuia(
      experiencia,
      certificado,
    );

    // 4. Verificamos la respuesta
    //    Usamos "mounted" para asegurar que la pantalla sigue "viva"
    if (mounted && exito) {
      // 5. ¡ÉXITO!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito! (Simulado)'),
          backgroundColor: Colors.green,
        ),
      );
      // 6. Usamos el "GPS" (GoRouter) para "volver"
      //    a la pantalla de perfil
      context.pop();
    } else if (mounted && !exito) {
      // 7. ¡ERROR!
      final errorMsg = context.read<AutenticacionVM>().error ??
          'Ocurrió un error desconocido.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (`watch`) al "Mesero" para saber
    // si está "cargando" (para bloquear el botón)
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar ser Guía'),
        backgroundColor: colorPrimario,
      ),
      body: Form(
        key: _formKey, // Conectamos la "llave"
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Icono y Título ---
              Icon(
                Icons.assignment_ind_outlined,
                size: 80,
                color: colorPrimario,
              ),
              const SizedBox(height: 16),
              Text(
                'Conviértete en Guía',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Comparte tu conocimiento y crea tus propias rutas. Completa tu información para que nuestro equipo la revise.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- Campo de Experiencia ---
              TextFormField(
                controller: _experienciaCtrl,
                decoration: _buildInputDecoration(
                    'Tu Experiencia',
                    'Cuéntanos sobre ti, tus años como guía, tus especialidades...',
                    Icons.notes),
                maxLines: 6, // Hacemos el campo más alto
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Este campo es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Campo de Certificado ---
              TextFormField(
                controller: _certificadoCtrl,
                decoration: _buildInputDecoration(
                    'Enlace a tu Certificado',
                    'Ej: URL de Google Drive, Dropbox, etc.',
                    Icons.link),
                keyboardType: TextInputType.url,
                validator: (value) {
                  // Validación simple de URL
                  if (value == null ||
                      value.isEmpty ||
                      !value.startsWith('http')) {
                    return 'Por favor, ingresa una URL válida (http...).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Sube tu certificado (carnet de guía, etc.) a un servicio como Google Drive o Dropbox y pega el enlace público aquí.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // --- Botón de Enviar ---
              ElevatedButton(
                // Si el "Mesero" está "cargando", se deshabilita
                onPressed: vmAuth.estaCargando ? null : _submitSolicitud,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: vmAuth.estaCargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar Solicitud',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Auxiliar de Diseño ---
  // (Para que todos los campos de texto se vean "amigables"
  // y consistentes)
  InputDecoration _buildInputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

