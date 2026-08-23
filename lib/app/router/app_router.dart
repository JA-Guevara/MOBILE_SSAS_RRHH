import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/bitacora/screens/bitacora_screen.dart';
import '../screens/dashboard_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const bitacora = '/bitacora';
}

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.dashboard => const DashboardScreen(),
      AppRoutes.bitacora => const BitacoraScreen(),
      _ => const LoginScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => screen, settings: settings);
  }
}
