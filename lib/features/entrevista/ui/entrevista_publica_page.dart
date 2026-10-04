import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';

class EntrevistaPublicaPage extends StatefulWidget {
  const EntrevistaPublicaPage({super.key, required this.service});
  final EntrevistaService service;

  @override
  State<EntrevistaPublicaPage> createState() => _EntrevistaPublicaPageState();
}

class _EntrevistaPublicaPageState extends State<EntrevistaPublicaPage> {
  final _codigo = TextEditingController();
  Map<String, dynamic>? _entrevista;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() { _codigo.dispose(); super.dispose(); }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() { _ocupado = true; _error = null; });
    try {
      await accion();
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _consultar() async {
    if (_codigo.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa tu código de seguimiento.');
      return;
    }
    setState(() => _entrevista = null);
    await _ejecutar(() async {
      final item = await widget.service.consultarPorCodigo(
        _codigo.text.trim().toUpperCase());
      if (mounted) setState(() => _entrevista = item);
    });
  }

  Future<void> _confirmar() async => _ejecutar(() async {
    final item = await widget.service.confirmarPorCodigo(
      _codigo.text.trim().toUpperCase(),
      '${_entrevista!['id']}',
    );
    if (mounted) setState(() => _entrevista = item);
  });

  @override
  Widget build(BuildContext context) {
    final item = _entrevista;
    final fecha = item == null ? null : DateTime.tryParse('${item['fecha_hora']}')?.toLocal();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi entrevista')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(controller: _codigo, enabled: !_ocupado,
          decoration: const InputDecoration(labelText: 'Código de seguimiento')),
        FilledButton(onPressed: _ocupado ? null : _consultar,
          child: const Text('Ver entrevista')),
        if (_ocupado) const Center(child: CircularProgressIndicator()),
        if (_error != null) Padding(padding: const EdgeInsets.all(8),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (item != null) ...[
          const Divider(),
          Text('Fecha: ${fecha?.day}/${fecha?.month}/${fecha?.year} '
              '${fecha?.hour.toString().padLeft(2, '0')}:${fecha?.minute.toString().padLeft(2, '0')}'),
          Text('Modalidad: ${item['modalidad']}'),
          if (item['lugar'] != null) Text('Lugar: ${item['lugar']}'),
          if (item['enlace_reunion'] != null) SelectableText('Enlace: ${item['enlace_reunion']}'),
          Text('Estado: ${item['estado']}'),
          if (item['estado'] == 'PROGRAMADA') FilledButton.icon(
            onPressed: _ocupado ? null : _confirmar,
            icon: const Icon(Icons.check), label: const Text('Confirmar asistencia')),
        ],
      ]),
    );
  }
}
