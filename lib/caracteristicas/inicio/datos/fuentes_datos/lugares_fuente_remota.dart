
// lib/caracteristicas/inicio/datos/fuentes_datos/lugares_fuente_remota.dart
import '../../../../core/red/cliente_api.dart';
import '../modelos/lugar_modelo.dart';

class LugaresFuenteRemota {
  final dio = ClienteApi().dio;

  // Ejemplo: GET /inicio -> devuelve categories, provinces, popular
  Future<Map<String, dynamic>> obtenerDatosInicio() async {
    final resp = await dio.get('/inicio');
    return Map<String, dynamic>.from(resp.data);
  }

  // GET /lugares -> lista de lugares (opcional filtros)
  Future<List<LugarModelo>> obtenerLugares({int? provinciaId, String? categoria}) async {
    final resp = await dio.get('/lugares', queryParameters: {
      if (provinciaId != null) 'provincia_id': provinciaId,
      if (categoria != null) 'categoria': categoria,
    });
    final lista = resp.data as List;
    return lista.map((e) => LugarModelo.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
