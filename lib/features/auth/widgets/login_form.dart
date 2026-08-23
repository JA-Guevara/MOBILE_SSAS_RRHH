import 'package:flutter/material.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/app_router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await AppProviders.of(context).auth
        .login(email: _email.text.trim(), password: _password.text);
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppProviders.of(context).auth;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Ingresa un correo válido.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            validator: (value) => value != null && value.length >= 6
                ? null
                : 'Usa al menos 6 caracteres.',
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              auth.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: auth.isLoading ? null : _submit,
            child: Text(auth.isLoading ? 'Ingresando…' : 'Ingresar'),
          ),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () => Navigator.pushNamed(context, AppRoutes.register),
            child: const Text('Crear una cuenta'),
          ),
        ],
      ),
    );
  }
}
