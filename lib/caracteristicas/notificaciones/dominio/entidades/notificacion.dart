// lib/features/notificaciones/dominio/entidades/notificacion.dart

class Notificacion {
  final String id;
  final String titulo;
  final String cuerpo;
  bool leido; // Lo dejamos mutable (sin 'final') para poder cambiarlo
  final DateTime fecha;
  final String? tipo; // 'cancelacion', 'confirmacion', 'aviso'

  Notificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.leido,
    required this.fecha,
    this.tipo,
  });
}