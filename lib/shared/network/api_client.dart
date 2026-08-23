import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  late final Openapi api; // Declaramos la instancia de la API

  // Patrón Singleton para usar siempre la misma conexión en toda la app
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://backendssasrrhh-production-3012.up.railway.app', 
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Añadimos el interceptor de tokens
    dio.interceptors.add(AuthInterceptor(dio));

    // Inicializamos la API inyectándole nuestro Dio ya configurado
    api = Openapi(dio: dio);
  }
}