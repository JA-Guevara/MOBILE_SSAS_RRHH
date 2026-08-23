import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    initialLocation: AppRoutes.login, // Inicia en la ruta de login
    
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(
          // Cuando exista el archivo, cambias este Scaffold por: const LoginScreen()
          body: Center(child: Text('Login Screen')), 
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(
          // Cambiar luego por: const RegisterScreen()
          body: Center(child: Text('Register Screen')),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const Scaffold(
          // Cambiar luego por: const DashboardScreen()
          body: Center(child: Text('Dashboard Screen')),
        ),
      ),
      GoRoute(
        path: AppRoutes.bitacora,
        builder: (context, state) => const Scaffold(
          // Cambiar luego por: const BitacoraScreen()
          body: Center(child: Text('Bitacora Screen')),
        ),
      ),
    ],
  );
}