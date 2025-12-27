import 'package:dio/dio.dart';

/// Servicio para consultar DNI con RENIEC a través de N8N webhook
class ReniecServicio {
  // URL del webhook de N8N para consulta DNI
  static const String _webhookUrl =
      'https://breakfast-dimensional-stocks-fabric.trycloudflare.com/webhook/consulta-dni';

  final Dio _dio = Dio();

  /// Consulta los datos de una persona por su DNI
  ///
  /// Retorna un Map con los datos si es exitoso, null si hay error
  ///
  /// Ejemplo de respuesta:
  /// ```json
  /// {
  ///   "dni": "12345678",
  ///   "nombre": "JUAN",
  ///   "apellidoPaterno": "PEREZ",
  ///   "apellidoMaterno": "GARCIA"
  /// }
  /// ```
  Future<Map<String, dynamic>?> consultarDNI(String dni) async {
    try {
      // Validar que el DNI tenga 8 dígitos
      if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
        throw Exception('DNI debe tener 8 dígitos');
      }

      print('🔍 [RENIEC] Consultando DNI: $dni');

      final response = await _dio.post(
        _webhookUrl,
        data: {'dni': dni},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('📡 [RENIEC] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print(
          '✅ [RENIEC] Datos recibidos: ${data['nombre']} ${data['apellidoPaterno']}',
        );
        return data;
      } else {
        print('❌ [RENIEC] Error: ${response.statusCode}');
        throw Exception('Error al consultar RENIEC: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [RENIEC] DioException: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [RENIEC] Excepción: $e');
      return null;
    }
  }
}
