class ParticipanteRuta {
  final String usuarioId;
  final String seudonimo;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String dni;
  final String urlFotoPerfil;
  final bool mostrarNombreReal;
  final bool asistio;
  final bool soyYo; // Helper para UI

  ParticipanteRuta({
    required this.usuarioId,
    required this.seudonimo,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.dni,
    required this.urlFotoPerfil,
    required this.mostrarNombreReal,
    required this.asistio,
    this.soyYo = false,
  });

  String get nombreCompleto => '$nombres $apellidoPaterno $apellidoMaterno'.trim();
  
  // Logica de visualización según reglas de negocio
  String get tituloAMostrar {
    if (soyYo || mostrarNombreReal) return nombreCompleto;
    return seudonimo; // Default privacy
  }

  String get subtituloAMostrar {
    if (soyYo || mostrarNombreReal) return "Identidad Verificada (DNI)";
    return "Participante (Seudónimo)";
  }
}
