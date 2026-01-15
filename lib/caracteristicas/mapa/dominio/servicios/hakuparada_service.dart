import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../entidades/hakuparada.dart';             // Paso 1
import '../../datos/modelos/hakuparada_model.dart'; // Paso 2




class HakuparadaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 📏 REGLAS DEL JUEGO (Aquí vive tu lógica de negocio)
  static const double RADIO_DETECCION_METROS = 50.0; // El "círculo invisible"
  static const int COOLDOWN_MINUTOS = 10;            // Tiempo para no repetir alertas

  // 💾 MEMORIA TEMPORAL (Cache)
  // Historial: Para recordar a quién ya le avisamos
  final Map<int, DateTime> _historialNotificaciones = {};

  // Lista Cache: Para no gastar datos consultando a Supabase a cada rato
  List<Hakuparada> _paradasEnCache = [];

  // Getter público para el Mapa
  List<Hakuparada> getParadasCache() => _paradasEnCache;

  // --- FUNCIÓN 1: FILTRO DE SEGURIDAD (Descarga Inteligente) ---
  Future<List<Hakuparada>> cargarParadasPorProvincia(int? provinciaId) async {
    try {
      var query = _supabase
          .from('hakuparadas')
          .select()
          .eq('visible', true)             // FILTRO 1: Solo si está activa
          .eq('verificado', true);         // FILTRO 2: Solo si tú la aprobaste

      if (provinciaId != null) {
        query = query.eq('provincia_id', provinciaId);
      }

      final response = await query;
      final data = response as List<dynamic>;

      // Convertimos JSON -> Modelo -> Entidad
      // NOTA: Si cargamos todo, esto podría crecer. A futuro paginar.
      final nuevasParadas = data.map((json) => HakuparadaModel.fromJson(json)).toList();
      
      // Actualizamos cache sin borrar lo anterior si es diferente zona, 
      // pero por simplicidad ahora reemplazamos o agregamos.
      // Estrategia Simple: Reemplazar cache con lo nuevo.
      _paradasEnCache = nuevasParadas;

      print('✅ Cargadas ${_paradasEnCache.length} hakuparadas verificadas.');
      return _paradasEnCache;
    } catch (e) {
      print('❌ Error crítico cargando hakuparadas: $e');
      return []; 
    }
  }

  // --- FUNCIÓN 2: EL RADAR (Matemática Pura) ---
  // Esta función se llamará cada 5-10 segundos desde el Mapa
  Hakuparada? verificarCercania(LatLng ubicacionUsuario) {
    final Distance calculadoraDistancia = Distance();

    for (var parada in _paradasEnCache) {
      // Ubicación de la parada
      final ubicacionParada = LatLng(parada.latitud, parada.longitud);

      // Calculamos distancia exacta
      final distancia = calculadoraDistancia.as(
          LengthUnit.Meter,
          ubicacionUsuario,
          ubicacionParada
      );

      // EVALUACIÓN: ¿Está dentro de los 50 metros?
      if (distancia <= RADIO_DETECCION_METROS) {
        // ¿Ya le avisamos hace poco? (Anti-spam)
        if (_puedoNotificar(parada.id)) {
          _registrarNotificacion(parada.id);
          return parada; // ¡BINGO! Devolvemos la parada para mostrar la alerta
        }
      }
    }

    return null; // Nada cerca o todo ya fue notificado
  }

  // --- LÓGICA PRIVADA (El guardia del Spam) ---
  bool _puedoNotificar(int paradaId) {
    // Si nunca le avisamos, adelante
    if (!_historialNotificaciones.containsKey(paradaId)) {
      return true;
    }

    final ultimaVez = _historialNotificaciones[paradaId]!;
    final tiempoTranscurrido = DateTime.now().difference(ultimaVez);

    // Si pasaron más de 10 minutos, permitimos otra alerta
    return tiempoTranscurrido.inMinutes >= COOLDOWN_MINUTOS;
  }

  void _registrarNotificacion(int paradaId) {
    _historialNotificaciones[paradaId] = DateTime.now();
  }

  // (Opcional) Para limpiar memoria si cambias de provincia
  void limpiarCache() {
    _paradasEnCache.clear();
    _historialNotificaciones.clear();
  }
}