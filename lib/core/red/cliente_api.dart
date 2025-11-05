// lib/core/red/cliente_api.dart
import 'package:dio/dio.dart';

class ClienteApi {
  static final ClienteApi _instancia = ClienteApi._internal();
  factory ClienteApi() => _instancia;
  late final Dio dio;

  ClienteApi._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/api', // EMULADOR Android -> 10.0.2.2
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
  }
}
