import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app/app.dart';

// import '../features/auth/presentation/screens/login_screen.dart';
void main() {
  runApp(const App());
}
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // Ruta inicial al abrir la app
    
    // Aquí definimos todas las rutas de la aplicación
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla de Login (Placeholder)')),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla Principal (Placeholder)')),
        ),
      ),
    ],

    // (Opcional) Aquí puedes agregar lógica de redirección más adelante
    // redirect: (context, state) {
    //   final isAuthenticated = ... // Lógica para verificar token
    //   if (!isAuthenticated && state.matchedLocation != '/login') return '/login';
    //   return null;
    // },
  );
}