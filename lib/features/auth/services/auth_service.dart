import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/app/router/app_router.dart'; // Asegúrate de usar tu ruta correcta

class AuthService {
  static final _storage = const FlutterSecureStorage();

  static Future<void> cerrarSesion(BuildContext context) async {
    // 1. Borramos todos los tokens del almacenamiento seguro
    await _storage.deleteAll();
    
    // 2. Redirigimos al usuario a la pantalla de login usando GoRouter
    if (context.mounted) {
      context.go(AppRoutes.login); // Asegúrate de que esta sea tu ruta de login
    }
  }
}