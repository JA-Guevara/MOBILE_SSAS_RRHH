import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final storage = const FlutterSecureStorage();

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await storage.read(key: 'refresh_token');
        
        // Usamos una instancia limpia de Dio para evitar un bucle infinito
        final refreshDio = Dio(); 
        final response = await refreshDio.post(
          'https://backendssasrrhh-production-3012.up.railway.app/auth/refresh', 
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        // Guardamos los nuevos tokens
        await storage.write(key: 'access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await storage.write(key: 'refresh_token', value: newRefreshToken);
        }

        // Reintentamos la petición original con el nuevo token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await refreshDio.fetch(err.requestOptions);
        
        return handler.resolve(retryResponse);
      } catch (e) {
        // Si falla la renovación, borramos tokens para forzar inicio de sesión
        await storage.deleteAll();
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}