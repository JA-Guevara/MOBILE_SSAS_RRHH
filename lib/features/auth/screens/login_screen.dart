import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AuthShell(title: 'Iniciar sesión', child: LoginForm());
}
