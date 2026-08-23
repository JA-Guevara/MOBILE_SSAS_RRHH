import 'package:flutter/material.dart';
import 'router/app_router.dart'; // Importe corregido
// import '../shared/theme/app_theme.dart'; 

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SSAS RRHH',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
