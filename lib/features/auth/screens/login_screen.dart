import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/staff_portal_page.dart';

/// Ruta heredada: usa el mismo acceso real que la entrada pública.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const StaffPortalPage();
}
