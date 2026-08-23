import 'package:flutter/material.dart';

import '../../../app/layouts/app_layout.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/full_page_status.dart';
import '../api/bitacora_api.dart';
import '../widgets/audit_log_card.dart';
import '../widgets/audit_log_filters.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});
  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  Future<List<AuditLog>>? _logs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logs ??= AppProviders.of(context).bitacoraApi.list();
  }

  void _load([String? search]) => setState(() {
    _logs = AppProviders.of(context).bitacoraApi.list(search: search);
  });

  @override
  Widget build(BuildContext context) => AppLayout(
    title: 'Bitácora',
    currentIndex: 1,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AuditLogFilters(onSearch: _load),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AuditLog>>(
              future: _logs,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is AppException
                      ? error.message
                      : 'No se pudo cargar la bitácora.';
                  return FullPageStatus(
                    icon: Icons.cloud_off,
                    message: message,
                    action: FilledButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  );
                }
                final logs = snapshot.data ?? const [];
                if (logs.isEmpty) {
                  return const FullPageStatus(
                    icon: Icons.inbox_outlined,
                    message: 'No hay registros para mostrar.',
                  );
                }
                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => AuditLogCard(log: logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
