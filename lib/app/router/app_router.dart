import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/login_screen.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/vacante_detalle_screen.dart';
// Comentado hasta crear los archivos fisicos
// import '../../features/auth/screens/login_screen.dart';
// import '../../features/auth/screens/register_screen.dart';
// import '../../features/bitacora/screens/bitacora_screen.dart';
// import '../screens/dashboard_screen.dart';

// Conservamos tu clase de constantes para evitar errores de tipeo en las rutas
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const bitacora = '/bitacora';
}

// Reemplazamos onGenerateRoute por la configuración de go_router
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login, 
    
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(), 
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen')),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Dashboard Screen')),
        ),
      ),
      GoRoute(
        path: AppRoutes.bitacora,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Bitacora Screen')),
        ),
      ),
    ],
  );
}