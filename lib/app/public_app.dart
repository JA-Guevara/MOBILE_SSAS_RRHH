import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/core/constants/app_constants.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/staff_portal_page.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/ui/entrevista_publica_page.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/vacantes_publicas_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

class PublicApp extends StatelessWidget {
  const PublicApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _PortalInicio(),
  );
}

class _PortalInicio extends StatefulWidget {
  const _PortalInicio();

  @override
  State<_PortalInicio> createState() => _PortalInicioState();
}

class _PortalInicioState extends State<_PortalInicio> {
  final _slug = TextEditingController(text: AppConstants.empresaSlug);
  final _vacantes = VacantesService(baseUrl: AppConstants.apiBaseUrl);
  late final _postulaciones = PostulacionesService(baseUrl: AppConstants.apiBaseUrl);
  late final _seguimiento = SeguimientoService(baseUrl: AppConstants.apiBaseUrl);
  late final _entrevistas = EntrevistaService(baseUrl: AppConstants.apiBaseUrl);
  Future<String>? _empresa;
  String _slugActivo = AppConstants.empresaSlug;

  @override
  void initState() {
    super.initState();
    if (_slugActivo.isNotEmpty) {
      _empresa = _vacantes.nombreEmpresa(_slugActivo);
    }
  }

  void _cargar() {
    final slug = _slug.text.trim();
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la empresa.')),
      );
      return;
    }
    setState(() {
      _slugActivo = slug;
      _empresa = _vacantes.nombreEmpresa(slug);
    });
  }

  void _abrirPersonal() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const StaffPortalPage()),
  );

  void _abrirEntrevistas() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => EntrevistaPublicaPage(service: _entrevistas)),
  );

  @override
  void dispose() {
    _slug.dispose();
    _vacantes.close();
    _postulaciones.close();
    _seguimiento.close();
    _entrevistas.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final future = _empresa;
    if (future == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Empleos'), actions: [
          IconButton(onPressed: _abrirPersonal, tooltip: 'Acceso de personal',
            icon: const Icon(Icons.badge_outlined)),
        ]),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _slug,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _cargar(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _cargar, child: const Text('Ver vacantes')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Empleos'), actions: [
              IconButton(onPressed: _abrirPersonal, tooltip: 'Acceso de personal',
                icon: const Icon(Icons.badge_outlined)),
            ]),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar la empresa.'),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                    TextButton(
                      onPressed: () => setState(() => _empresa = null),
                      child: const Text('Cambiar empresa'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return VacantesPublicasPage(
          key: ValueKey(_slugActivo),
          slug: _slugActivo,
          empresaNombre: snapshot.data!,
          service: _vacantes,
          postulacionesService: _postulaciones,
          seguimientoService: _seguimiento,
          onCambiarEmpresa: () => setState(() => _empresa = null),
          onAccesoPersonal: _abrirPersonal,
          onVerEntrevista: _abrirEntrevistas,
        );
      },
    );
  }
}
