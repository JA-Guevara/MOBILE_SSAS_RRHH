import 'package:flutter/material.dart';

import '../providers/app_providers.dart';
import '../router/app_router.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({
    required this.title,
    required this.currentIndex,
    required this.body,
    super.key,
  });

  final String title;
  final int currentIndex;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AppProviders.of(context).auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final route = index == 0 ? AppRoutes.dashboard : AppRoutes.bitacora;
          Navigator.pushReplacementNamed(context, route);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Bitácora',
          ),
        ],
      ),
    );
  }
}
