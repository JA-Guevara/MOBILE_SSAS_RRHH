import 'package:flutter/material.dart';

import '../layouts/app_layout.dart';
import '../providers/app_providers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = AppProviders.of(context).auth.userName ?? 'Usuario';
    return AppLayout(
      title: 'Panel principal',
      currentIndex: 0,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Bienvenido al sistema de Recursos Humanos.'),
          ],
        ),
      ),
    );
  }
}
