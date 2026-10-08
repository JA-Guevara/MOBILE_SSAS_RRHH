import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class PostulantesPage extends StatefulWidget {
  const PostulantesPage({super.key, required this.api});

  final StaffApi api;

  @override
  State<PostulantesPage> createState() => _PostulantesPageState();
}

class _PostulantesPageState extends State<PostulantesPage> {
  static const _limit = 50;
  int _offset = 0;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.api.applicants(offset: _offset, limit: _limit);
  }

  void _page(int offset) => setState(() {
    _offset = offset;
    _load();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Postulantes')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
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
                Text('${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final items = snapshot.data!;
        return ListView(
          children: [
            if (items.isEmpty && _offset == 0)
              const ListTile(title: Text('No hay postulantes registrados.')),
            for (final item in items)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  '${item['nombres'] ?? ''} ${item['apellidos'] ?? ''}'.trim(),
                ),
                subtitle: Text('${item['ciudad'] ?? ''}'),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: _offset == 0
                      ? null
                      : () => _page(_offset - _limit),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Página ${_offset ~/ _limit + 1}'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: items.length < _limit
                      ? null
                      : () => _page(_offset + _limit),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
