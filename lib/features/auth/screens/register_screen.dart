import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AuthShell(title: 'Crear cuenta', child: RegisterForm());
}
