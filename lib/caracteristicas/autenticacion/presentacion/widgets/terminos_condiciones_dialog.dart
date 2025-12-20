import 'package:flutter/material.dart';

class TerminosCondicionesDialog extends StatelessWidget {
  const TerminosCondicionesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Términos y Condiciones',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccion(
                      context,
                      '1. CONCEPTO DEL SERVICIO',
                      'HAKU es una plataforma tecnológica intermedia diseñada para conectar a visitantes (turistas) con guías turísticos certificados en la región del Cusco. La aplicación facilita la visualización de rutas, gestión de grupos y comunicación entre las partes. HAKU no es una agencia de viajes ni un operador turístico, por lo tanto, no se responsabiliza por la ejecución, calidad o seguridad física de los tours.',
                    ),

                    _buildSeccion(
                      context,
                      '2. RÉGIMEN ECONÓMICO Y PAGOS',
                      null,
                      subsecciones: [
                        _buildSubseccion(
                          context,
                          'Intermediación sin Pagos',
                          'La aplicación no cuenta con una pasarela de pagos integrada. Cualquier acuerdo económico por el servicio de guiado es estrictamente directo entre el guía y el turista, fuera de la plataforma. HAKU no asume responsabilidad por impagos, estafas o reclamos monetarios.',
                        ),
                        _buildSubseccion(
                          context,
                          'Suscripción de Guías',
                          'Para mantener la facultad de publicar rutas y gestionar grupos, el usuario con rol de Guía acepta el pago de una tarifa de mantenimiento de plataforma de S/ 10.00 (diez soles) mensuales. El incumplimiento de este pago derivará en la suspensión temporal de las funciones de creación de contenido.',
                        ),
                      ],
                    ),

                    _buildSeccion(
                      context,
                      '3. POLÍTICA DE ASISTENCIA Y CANCELACIONES',
                      'Para garantizar la seriedad de las reservas y respetar el trabajo de los guías, se establecen las siguientes reglas:',
                      subsecciones: [
                        _buildSubseccion(
                          context,
                          'Cancelación Oportuna',
                          'El turista tiene derecho a cancelar su participación en una ruta sin penalización alguna, siempre que lo realice con una antelación mínima de 24 horas antes del inicio programado.',
                        ),
                        _buildSubseccion(
                          context,
                          'Inasistencia (No-Show)',
                          'Si un usuario no asiste al tour y no realizó la cancelación dentro del plazo estipulado (24 horas), se aplicarán las siguientes medidas:\n\n'
                              '1. Suspensión Inmediata: El perfil del usuario será bloqueado por un periodo de 30 días calendario, impidiéndole inscribirse en nuevas rutas.\n\n'
                              '2. Etiqueta de Riesgo: Una vez cumplida la sanción de 30 días y habilitada la cuenta, el perfil del usuario mostrará automáticamente una Etiqueta de Advertencia de Inasistencia visible para los guías durante 7 días adicionales.',
                        ),
                      ],
                    ),

                    _buildSeccion(
                      context,
                      '4. EXENCIÓN DE RESPONSABILIDAD POR SEGURIDAD',
                      'HAKU informa a todos sus usuarios que:\n\n'
                          '• La aplicación no provee ni exige un seguro de viaje o de accidentes para las rutas publicadas.\n'
                          '• El Guía no cuenta con seguro de viaje para sus grupos gestionado a través de esta plataforma.\n'
                          '• Es responsabilidad exclusiva del turista contratar un seguro personal y evaluar los riesgos inherentes a las actividades de caminata o exploración en Cusco.',
                    ),

                    _buildSeccion(
                      context,
                      '5. TRATAMIENTO DE DATOS PERSONALES',
                      'De conformidad con la Ley de Protección de Datos Personales, HAKU recolecta y procesa datos de registro y geolocalización con el fin de:\n\n'
                          '• Gestionar la autenticación y perfiles de usuario.\n'
                          '• Permitir la validación de guías mediante la revisión de credenciales por parte del Administrador.\n'
                          '• Aplicar el sistema de sanciones y etiquetas de riesgo mencionado en el punto 3.\n'
                          '• HAKU utiliza los servicios de Supabase para el almacenamiento seguro de datos, asegurando la integridad de la información mediante procesos transaccionales.',
                    ),

                    _buildSeccion(
                      context,
                      '6. ACEPTACIÓN DE TÉRMINOS',
                      'Al continuar con Google, el usuario declara haber leído, comprendido y aceptado todas las cláusulas aquí descritas, incluyendo el sistema de sanciones por inasistencia y la falta de seguros por parte de la plataforma y los guías.',
                      importante: true,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context,
    String titulo,
    String? contenido, {
    List<Widget>? subsecciones,
    bool importante = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: importante ? Colors.red[700] : null,
            ),
          ),
          const SizedBox(height: 8),
          if (contenido != null)
            Text(
              contenido,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          if (subsecciones != null) ...subsecciones,
        ],
      ),
    );
  }

  Widget _buildSubseccion(
    BuildContext context,
    String titulo,
    String contenido,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $titulo:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            contenido,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  static void mostrar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TerminosCondicionesDialog(),
    );
  }
}
