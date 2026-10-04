import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/core/constants/app_constants.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class StaffPortalPage extends StatefulWidget {
  const StaffPortalPage({super.key, this.restoreSession = true});

  final bool restoreSession;

  @override
  State<StaffPortalPage> createState() => _StaffPortalPageState();
}

class _StaffPortalPageState extends State<StaffPortalPage> {
  final _api = StaffApi(baseUrl: AppConstants.apiBaseUrl);
  final _empresa = TextEditingController(text: AppConstants.empresaSlug);
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _empresaId = TextEditingController();
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>>? _vacantes;
  bool _plataforma = false;
  bool _ocupado = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.restoreSession) {
      _restaurar();
    } else {
      _ocupado = false;
    }
  }

  Future<void> _restaurar() async {
    try {
      final perfil = await _api.profile();
      if (!mounted) return;
      setState(() => _perfil = perfil);
      await _cargarVacantes();
    } on StaffApiException catch (error) {
      if (!mounted) return;
      if (error.status != 401) setState(() => _error = error.message);
    } on Exception {
      if (mounted) setState(() => _error = 'No se pudo restaurar la sesión.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  bool get _esPlataforma => _perfil != null && _perfil!['empresa_id'] == null;

  bool get _puedeVer => (_perfil?['permissions'] as List? ?? const [])
      .any((value) => value == 'postulaciones:ver' || value == 'platform:postulaciones:ver');

  Future<void> _entrar() async {
    if (_usuario.text.trim().isEmpty || _clave.text.isEmpty ||
        (!_plataforma && _empresa.text.trim().isEmpty)) {
      setState(() => _error = 'Completa empresa, usuario y contraseña.');
      return;
    }
    setState(() { _ocupado = true; _error = null; });
    try {
      final perfil = await _api.login(
        identifier: _usuario.text.trim(), password: _clave.text,
        empresaSlug: _plataforma ? null : _empresa.text.trim(),
      );
      _clave.clear();
      if (!mounted) return;
      setState(() => _perfil = perfil);
      await _cargarVacantes();
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() {
          if (error.status == 401) { _perfil = null; _vacantes = null; }
          _error = error.message;
        });
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cargarVacantes() async {
    if (!_puedeVer) return;
    try {
      if (_esPlataforma && _empresaId.text.trim().isEmpty) return;
      final items = await _api.vacancies(
          empresaId: _esPlataforma ? _empresaId.text.trim() : null);
      if (mounted) setState(() => _vacantes = items);
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() {
          if (error.status == 401) { _perfil = null; _vacantes = null; }
          _error = error.message;
        });
      }
    }
  }

  Future<void> _salir() async {
    setState(() => _ocupado = true);
    try {
      await _api.logout();
    } on StaffApiException {
      // La sesión local se borra incluso si la revocación remota no respondió.
    } finally {
      if (mounted) {
        setState(() {
          _perfil = null; _vacantes = null; _ocupado = false; _error = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _api.close();
    _empresa.dispose(); _usuario.dispose(); _clave.dispose(); _empresaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_perfil == null ? 'Acceso de personal' : 'Selección'),
      actions: [if (_perfil != null) IconButton(
        tooltip: 'Cerrar sesión', onPressed: _ocupado ? null : _salir,
        icon: const Icon(Icons.logout),
      )]),
    body: _ocupado && _perfil == null
        ? const Center(child: CircularProgressIndicator())
        : _perfil == null ? _login() : _inicio(),
  );

  Widget _login() => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<bool>(segments: const [
          ButtonSegment(value: false, label: Text('Empresa')),
          ButtonSegment(value: true, label: Text('Plataforma')),
        ], selected: {_plataforma}, onSelectionChanged: (value) =>
            setState(() => _plataforma = value.first)),
        if (!_plataforma) TextField(controller: _empresa,
          decoration: const InputDecoration(labelText: 'Código de empresa')),
        TextField(controller: _usuario,
          decoration: const InputDecoration(labelText: 'Correo o usuario')),
        TextField(controller: _clave, obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña'),
          onSubmitted: (_) => _entrar()),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        FilledButton(onPressed: _ocupado ? null : _entrar,
          child: const Text('Ingresar')),
      ])),
  ));

  Widget _inicio() => RefreshIndicator(onRefresh: _cargarVacantes,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Text('Hola, ${_perfil?['name'] ?? 'usuario'}',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      if (!_puedeVer) const Text('Tu cuenta no tiene permiso para ver postulaciones.'),
      if (_puedeVer && _esPlataforma) ...[
        TextField(controller: _empresaId,
          decoration: const InputDecoration(labelText: 'ID de empresa')),
        TextButton.icon(onPressed: _cargarVacantes,
          icon: const Icon(Icons.search), label: const Text('Cargar vacantes')),
      ],
      if (_puedeVer && _vacantes == null && !_esPlataforma)
        const Center(child: CircularProgressIndicator()),
      if (_vacantes != null && _vacantes!.isEmpty) const Text('No hay vacantes disponibles.'),
      for (final vacante in _vacantes ?? const <Map<String, dynamic>>[])
        ListTile(title: Text('${vacante['titulo'] ?? 'Vacante'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _RankingRealPage(api: _api,
              id: '${vacante['id']}', titulo: '${vacante['titulo'] ?? 'Vacante'}',
              empresaId: _esPlataforma ? _empresaId.text.trim() : null),
          ))),
    ]),
  );
}

class _RankingRealPage extends StatefulWidget {
  const _RankingRealPage({required this.api, required this.id, required this.titulo,
    this.empresaId});
  final StaffApi api;
  final String id;
  final String titulo;
  final String? empresaId;

  @override
  State<_RankingRealPage> createState() => _RankingRealPageState();
}

class _RankingRealPageState extends State<_RankingRealPage> {
  String _orden = 'ia';
  String? _estado;
  int _offset = 0;
  static const _limit = 20;
  late Future<Map<String, dynamic>> _futuro;

  @override
  void initState() { super.initState(); _cargar(); }

  void _cargar() => _futuro = widget.api.ranking(widget.id,
      order: _orden, empresaId: widget.empresaId, estado: _estado,
      offset: _offset, limit: _limit);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.titulo), actions: [
      PopupMenuButton<String>(tooltip: 'Ordenar candidatos',
        onSelected: (value) => setState(() { _orden = value; _offset = 0; _cargar(); }),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'ia', child: Text('Afinidad IA')),
          PopupMenuItem(value: 'manual', child: Text('Puntaje manual')),
        ], icon: const Icon(Icons.sort)),
    ]),
    body: FutureBuilder<Map<String, dynamic>>(future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              Text('${snapshot.error}'),
              TextButton(onPressed: () => setState(_cargar), child: const Text('Reintentar')),
            ]));
        }
        final items = (snapshot.data!['items'] as List? ?? const []);
        final total = snapshot.data!['total'] as int? ?? items.length;
        return ListView(children: [
          DropdownButton<String?>(value: _estado,
            hint: const Text('Todos los estados'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todos los estados')),
              DropdownMenuItem<String?>(value: 'ACTIVA', child: Text('Activa')),
              DropdownMenuItem<String?>(value: 'RETIRADA', child: Text('Retirada')),
              DropdownMenuItem<String?>(value: 'DESCARTADA', child: Text('Descartada')),
              DropdownMenuItem<String?>(value: 'CONTRATADA', child: Text('Contratada')),
            ],
            onChanged: (value) => setState(() { _estado = value; _offset = 0; _cargar(); })),
          if (items.isEmpty) const ListTile(title: Text('Sin postulantes.')),
          for (final raw in items) Builder(builder: (_) {
            final item = raw as Map<String, dynamic>;
            final score = item['puntaje_$_orden'];
            return ListTile(title: Text('${item['nombre_postulante'] ?? 'Candidato'}'),
              subtitle: Text('${item['estado'] ?? ''} · ${item['experiencia_anios'] ?? 0} años'),
              trailing: score == null ? const Text('Sin puntaje') : Text('$score'));
          }),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(tooltip: 'Página anterior', icon: const Icon(Icons.chevron_left),
              onPressed: _offset == 0 ? null : () => setState(() {
                _offset = (_offset - _limit).clamp(0, total); _cargar();
              })),
            Text('${total == 0 ? 0 : _offset + 1}-${(_offset + items.length)} de $total'),
            IconButton(tooltip: 'Página siguiente', icon: const Icon(Icons.chevron_right),
              onPressed: _offset + items.length >= total ? null : () => setState(() {
                _offset += _limit; _cargar();
              })),
          ]),
        ]);
      }),
  );
}
