import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class RespaldosEmpresaPage extends StatefulWidget {
  const RespaldosEmpresaPage({super.key, required this.api, required this.canCreate});

  final StaffApi api;
  final bool canCreate;

  @override
  State<RespaldosEmpresaPage> createState() => _RespaldosEmpresaPageState();
}

class _RespaldosEmpresaPageState extends State<RespaldosEmpresaPage> {
  late Future<Map<String, dynamic>> _future;
  bool _creating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.api.latestTenantBackup();

  Future<void> _confirmCreate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear respaldo'),
        content: const Text('¿Solicitar un respaldo de los datos de tu empresa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _create();
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _message = null;
    });
    try {
      await widget.api.createTenantBackup();
      if (!mounted) return;
      setState(() {
        _message = 'Respaldo solicitado. Consulta su estado aquí.';
        _reload();
      });
    } on StaffApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _date(Object? value) {
    if (value is! String) return 'Sin respaldo';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return 'Sin respaldo';
    final day = '${parsed.day}'.padLeft(2, '0');
    final month = '${parsed.month}'.padLeft(2, '0');
    final hour = '${parsed.hour}'.padLeft(2, '0');
    final minute = '${parsed.minute}'.padLeft(2, '0');
    return '$day/$month/${parsed.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Respaldos'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(_reload),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar los respaldos.'),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final last = snapshot.data?['ultimo_intento'] as Map<String, dynamic>?;
        final success = snapshot.data?['ultimo_exitoso'] as Map<String, dynamic>?;
        final running = last?['estado'] == 'PENDIENTE' ||
            last?['estado'] == 'PROCESANDO';
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('Último respaldo correcto'),
                subtitle: Text(_date(success?['fecha_finalizacion'])),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Último intento'),
                subtitle: Text(last == null
                    ? 'Todavía no hay respaldos.'
                    : '${last['estado']} · ${_date(last['fecha_creacion'])}'),
              ),
              if (last?['estado'] == 'FALLIDO')
                const ListTile(
                  title: Text('La última copia falló.'),
                  subtitle: Text('Consulta al administrador de plataforma si vuelve a ocurrir.'),
                ),
              if (_message != null) ListTile(title: Text(_message!)),
              if (widget.canCreate) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _creating || running ? null : _confirmCreate,
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(_creating ? 'Solicitando…' : 'Crear respaldo'),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
