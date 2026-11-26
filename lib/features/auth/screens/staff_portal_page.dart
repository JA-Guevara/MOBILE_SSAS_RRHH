import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/app/chatbot_page.dart';
import 'package:mobile_ssas_rrhh/core/constants/app_constants.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/postulantes_page.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/respaldos_empresa_page.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/suscripcion_page.dart';
import 'package:mobile_ssas_rrhh/features/reportes/reportes_page.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/capacitacion/my_courses_page.dart';
import 'package:mobile_ssas_rrhh/features/capacitacion/my_skills_page.dart';
import 'package:mobile_ssas_rrhh/features/reportes/indicators_page.dart';
import 'package:mobile_ssas_rrhh/features/dashboard/dashboard_page.dart';
import 'package:mobile_ssas_rrhh/features/notifications/push_registration.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/bandeja_page.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/equipo_page.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/ui/asistencia_page.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/boletas_page.dart';
import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
import 'package:mobile_ssas_rrhh/features/legajo/ui/legajo_page.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/ui/mi_contrato_page.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/ui/mis_dias_page.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/solicitar_ausencia_page.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/tipos_ausencia_page.dart';

class StaffPortalPage extends StatefulWidget {
  const StaffPortalPage({super.key, this.restoreSession = true});

  final bool restoreSession;

  @override
  State<StaffPortalPage> createState() => _StaffPortalPageState();
}

class _StaffPortalPageState extends State<StaffPortalPage>
    with WidgetsBindingObserver {
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
  List<Map<String, dynamic>> _notifications = [];
  Timer? _notificationTimer;
  bool _loadingNotifications = false;
  String? _notificationError;
  final _push = PushRegistration();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      unawaited(_loadNotifications());
      unawaited(_push.start(_api));
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

  bool get _puedeVer => (_perfil?['permissions'] as List? ?? const []).any(
    (value) =>
        value == 'postulaciones:ver' || value == 'platform:postulaciones:ver',
  );

  Set<String> get _permisos =>
      (_perfil?['permissions'] as List? ?? const []).cast<String>().toSet();

  final _tokenPersonal = const SecureTokenStorage();
  late final _clientePersonal = AppHttpClient(baseUrl: AppConstants.apiBaseUrl);

  bool _permiso(String codigo) =>
      _permisos.contains(codigo) || _permisos.contains('platform:$codigo');

  void _abrirPersonal(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  bool get _puedeVerReportes =>
      _permisos.contains('reportes:ver') ||
      _permisos.contains('platform:reportes:gestionar');

  bool get _puedeVerDashboard =>
      _permisos.contains('empresa:ver') ||
      _permisos.contains('platform:empresas:ver');

  bool get _puedeVerRespaldos =>
      !_esPlataforma && _permisos.contains('backup:ver');

  bool get _puedeVerSuscripcion =>
      !_esPlataforma && _permisos.contains('suscripcion:ver');

  int get _unreadNotificationCount =>
      _notifications.where((item) => item['leida_en'] == null).length;

  Future<void> _loadNotifications() async {
    if (_perfil?['empresa_id'] == null || _loadingNotifications) return;
    _loadingNotifications = true;
    try {
      final items = await _api.notifications();
      if (!mounted || _perfil?['empresa_id'] == null) return;
      setState(() {
        _notifications = items;
        _notificationError = null;
      });
      _notificationTimer ??= Timer.periodic(
        const Duration(seconds: 60),
        (_) => _loadNotifications(),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _notificationError = '$error');
    } finally {
      _loadingNotifications = false;
    }
  }

  Future<void> _showNotifications() async {
    await _loadNotifications();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_unreadNotificationCount > 0)
                TextButton(
                  onPressed: () async {
                    try {
                      await _api.markAllNotificationsRead();
                      await _loadNotifications();
                      if (context.mounted) Navigator.pop(context);
                    } on Exception catch (error) {
                      if (mounted) {
                        setState(() => _notificationError = '$error');
                      }
                    }
                  },
                  child: const Text('Marcar todas como leídas'),
                ),
              if (_notificationError != null)
                ListTile(
                  title: Text(
                    'No se pudieron cargar los avisos: $_notificationError',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _loadNotifications();
                      if (context.mounted) Navigator.pop(context);
                      if (mounted) _showNotifications();
                    },
                  ),
                ),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(child: Text('No tienes avisos recientes.'))
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final date = DateTime.tryParse('${item['fecha']}')
                              ?.toLocal();
                          return ListTile(
                            leading: Icon(
                              item['tipo'] == 'SUSCRIPCION'
                                  ? Icons.credit_card_outlined
                                  : Icons.event_available_outlined,
                            ),
                            title: Text('${item['titulo']}'),
                            subtitle: Text('${item['mensaje']}'),
                            selected: item['leida_en'] == null,
                            onTap: () async {
                              try {
                                await _api.markNotificationRead(
                                  '${item['id']}',
                                );
                                if (mounted) await _loadNotifications();
                                if (context.mounted) Navigator.pop(context);
                                if (mounted) _showNotifications();
                              } on Exception catch (error) {
                                if (mounted) {
                                  setState(() => _notificationError = '$error');
                                }
                              }
                            },
                            trailing: date == null
                                ? null
                                : Text('${date.day}/${date.month}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
      if (_perfil != null) unawaited(_push.start(_api));
    }
  }

  void _abrirReportes() {
    final empresaId = _empresaId.text.trim();
    if (_esPlataforma && empresaId.isEmpty) {
      setState(
        () => _error = 'Introduce el ID de empresa para ver sus reportes.',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportesPage(
          api: _api,
          permissions: _permisos,
          empresaId: _esPlataforma ? empresaId : null,
        ),
      ),
    );
  }

  Future<void> _abrirChatbot() async {
    final route = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ChatbotPage.personal(staffApi: _api),
      ),
    );
    if (!mounted || route == null) return;
    switch (route) {
      case '/reportes':
        if (_puedeVerReportes) {
          _abrirReportes();
          return;
        }
      case '/postulantes':
        if (_permisos.contains('postulantes:ver')) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PostulantesPage(api: _api)),
          );
          return;
        }
      case '/personal/ausencias/mi':
        if (!_esPlataforma && _permiso('ausencias:solicitar')) {
          _abrirPersonal(
            SolicitarAusenciaPage(
              service: SolicitudesService(_clientePersonal, _tokenPersonal),
            ),
          );
          return;
        }
      case '/nomina/mis-boletas':
        if (!_esPlataforma && _permiso('boletas:mi')) {
          _abrirPersonal(
            BoletasPage(
              service: BoletasService(_clientePersonal, _tokenPersonal),
            ),
          );
          return;
        }
      case '/capacitacion/mis-habilidades':
        if (!_esPlataforma && _permiso('capacitacion:aprender')) {
          _abrirPersonal(MySkillsPage(api: _api));
          return;
        }
      case '/vacantes':
      case '/seleccion':
        if (_puedeVer) {
          await _cargarVacantes();
          return;
        }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta sección está disponible en la web.'),
        ),
      );
    }
  }

  Future<void> _entrar() async {
    if (_usuario.text.trim().isEmpty ||
        _clave.text.isEmpty ||
        (!_plataforma && _empresa.text.trim().isEmpty)) {
      setState(() => _error = 'Completa empresa, usuario y contraseña.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final perfil = await _api.login(
        identifier: _usuario.text.trim(),
        password: _clave.text,
        empresaSlug: _plataforma ? null : _empresa.text.trim(),
      );
      _clave.clear();
      if (!mounted) return;
      setState(() => _perfil = perfil);
      unawaited(_loadNotifications());
      unawaited(_push.start(_api));
      await _cargarVacantes();
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() {
          if (error.status == 401) {
            _perfil = null;
            _vacantes = null;
          }
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
        empresaId: _esPlataforma ? _empresaId.text.trim() : null,
      );
      if (mounted) setState(() => _vacantes = items);
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() {
          if (error.status == 401) {
            _perfil = null;
            _vacantes = null;
          }
          _error = error.message;
        });
      }
    }
  }

  Future<void> _salir() async {
    setState(() => _ocupado = true);
    try {
      await _push.stop(_api);
      await _api.logout();
    } on StaffApiException {
      // La sesión local se borra incluso si la revocación remota no respondió.
    } finally {
      if (mounted) {
        setState(() {
          _perfil = null;
          _notifications = [];
          _vacantes = null;
          _ocupado = false;
          _error = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _push.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _api.close();
    _clientePersonal.close();
    _empresa.dispose();
    _usuario.dispose();
    _clave.dispose();
    _empresaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _perfil == null ? 'Acceso de personal' : 'Portal de personal',
      ),
      actions: [
        if (_perfil != null && !_esPlataforma)
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: _showNotifications,
            icon: Badge(
              isLabelVisible: _unreadNotificationCount > 0,
              label: Text('$_unreadNotificationCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        if (_perfil != null && !_esPlataforma)
          IconButton(
            tooltip: 'Asistente RRHH',
            icon: const Icon(Icons.chat_outlined),
            onPressed: _abrirChatbot,
          ),
        if (_perfil != null && _puedeVerReportes)
          IconButton(
            tooltip: 'Reportes',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: _abrirReportes,
          ),
        if (_perfil != null)
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _ocupado ? null : _salir,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: _ocupado && _perfil == null
        ? const Center(child: CircularProgressIndicator())
        : _perfil == null
        ? _login()
        : _inicio(),
  );

  Widget _login() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Empresa')),
                ButtonSegment(value: true, label: Text('Plataforma')),
              ],
              selected: {_plataforma},
              onSelectionChanged: (value) =>
                  setState(() => _plataforma = value.first),
            ),
            if (!_plataforma)
              TextField(
                controller: _empresa,
                decoration: const InputDecoration(
                  labelText: 'Código de empresa',
                ),
              ),
            TextField(
              controller: _usuario,
              decoration: const InputDecoration(labelText: 'Correo o usuario'),
            ),
            TextField(
              controller: _clave,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              onSubmitted: (_) => _entrar(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _ocupado ? null : _entrar,
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _inicio() => RefreshIndicator(
    onRefresh: _cargarVacantes,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hola, ${_perfil?['name'] ?? 'usuario'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_permisos.isEmpty)
          const Text('Tu cuenta no tiene funciones asignadas.'),
        if (_puedeVerDashboard)
          Card(
            color: const Color(0xFF153F30),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: const Icon(
                Icons.space_dashboard_rounded,
                color: Color(0xFFAFE0BE),
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Indicadores y actividad en vivo',
                style: TextStyle(color: Color(0xFFD4E9D9)),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
              onTap: () => _abrirPersonal(DashboardPage(api: _api)),
            ),
          ),
        if (_puedeVerSuscripcion)
          ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: const Text('Mi suscripción'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SuscripcionPage(api: _api, permissions: _permisos),
              ),
            ),
          ),
        if (_puedeVerRespaldos)
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Respaldos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RespaldosEmpresaPage(
                  api: _api,
                  canCreate: _permisos.contains('backup:crear'),
                ),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('asistencia:marcar'))
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Marcar asistencia'),
            onTap: () => _abrirPersonal(
              AsistenciaPage(
                service: AsistenciaService(_clientePersonal, _tokenPersonal),
                ubicacion: const UbicacionService(),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('capacitacion:aprender'))
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Mis cursos'),
            onTap: () => _abrirPersonal(MyCoursesPage(api: _api)),
          ),
        if (!_esPlataforma && _permiso('capacitacion:aprender'))
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Mis habilidades'),
            onTap: () => _abrirPersonal(MySkillsPage(api: _api)),
          ),
        if (_permiso('indicadores:ver'))
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Indicadores'),
            onTap: () => _abrirPersonal(
              IndicatorsPage(
                api: _api,
                companyId: _esPlataforma ? _empresaId.text.trim() : null,
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('asistencia:mi'))
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Mis días trabajados'),
            onTap: () => _abrirPersonal(
              MisDiasPage(
                service: MisDiasService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('boletas:mi'))
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Mis boletas'),
            onTap: () => _abrirPersonal(
              BoletasPage(
                service: BoletasService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('personal:mi')) ...[
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Mi legajo'),
            onTap: () => _abrirPersonal(
              LegajoPage(
                service: LegajoService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Mi contrato'),
            onTap: () => _abrirPersonal(
              MiContratoPage(
                service: MiContratoService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        ],
        if (!_esPlataforma && _permiso('ausencias:solicitar'))
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Solicitar ausencia'),
            onTap: () => _abrirPersonal(
              SolicitarAusenciaPage(
                service: SolicitudesService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('ausencias:gestionar'))
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Tipos de ausencia'),
            onTap: () => _abrirPersonal(
              TiposAusenciaPage(
                service: TiposAusenciaService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('ausencias:aprobar'))
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Aprobar ausencias'),
            onTap: () => _abrirPersonal(
              BandejaPage(
                service: AprobacionesService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if (!_esPlataforma && _permiso('asistencia:ver_equipo'))
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Mi equipo'),
            onTap: () => _abrirPersonal(
              EquipoPage(
                service: EquipoService(_clientePersonal, _tokenPersonal),
              ),
            ),
          ),
        if ((_puedeVer || _puedeVerReportes) && _esPlataforma) ...[
          TextField(
            controller: _empresaId,
            decoration: const InputDecoration(labelText: 'ID de empresa'),
          ),
          if (_puedeVer)
            TextButton.icon(
              onPressed: _cargarVacantes,
              icon: const Icon(Icons.search),
              label: const Text('Cargar vacantes'),
            ),
        ],
        if (_puedeVer && _vacantes == null && !_esPlataforma)
          const Center(child: CircularProgressIndicator()),
        if (_vacantes != null && _vacantes!.isEmpty)
          const Text('No hay vacantes disponibles.'),
        for (final vacante in _vacantes ?? const <Map<String, dynamic>>[])
          ListTile(
            title: Text('${vacante['titulo'] ?? 'Vacante'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _RankingRealPage(
                  api: _api,
                  id: '${vacante['id']}',
                  titulo: '${vacante['titulo'] ?? 'Vacante'}',
                  empresaId: _esPlataforma ? _empresaId.text.trim() : null,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _RankingRealPage extends StatefulWidget {
  const _RankingRealPage({
    required this.api,
    required this.id,
    required this.titulo,
    this.empresaId,
  });
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
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => _futuro = widget.api.ranking(
    widget.id,
    order: _orden,
    empresaId: widget.empresaId,
    estado: _estado,
    offset: _offset,
    limit: _limit,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.titulo),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Ordenar candidatos',
          onSelected: (value) => setState(() {
            _orden = value;
            _offset = 0;
            _cargar();
          }),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'ia', child: Text('Afinidad IA')),
            PopupMenuItem(value: 'manual', child: Text('Puntaje manual')),
          ],
          icon: const Icon(Icons.sort),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _futuro,
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
                  onPressed: () => setState(_cargar),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final items = (snapshot.data!['items'] as List? ?? const []);
        final total = snapshot.data!['total'] as int? ?? items.length;
        return ListView(
          children: [
            DropdownButton<String?>(
              value: _estado,
              hint: const Text('Todos los estados'),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                DropdownMenuItem<String?>(
                  value: 'ACTIVA',
                  child: Text('Activa'),
                ),
                DropdownMenuItem<String?>(
                  value: 'RETIRADA',
                  child: Text('Retirada'),
                ),
                DropdownMenuItem<String?>(
                  value: 'DESCARTADA',
                  child: Text('Descartada'),
                ),
                DropdownMenuItem<String?>(
                  value: 'CONTRATADA',
                  child: Text('Contratada'),
                ),
              ],
              onChanged: (value) => setState(() {
                _estado = value;
                _offset = 0;
                _cargar();
              }),
            ),
            if (items.isEmpty) const ListTile(title: Text('Sin postulantes.')),
            for (final raw in items)
              Builder(
                builder: (_) {
                  final item = raw as Map<String, dynamic>;
                  final score = item['puntaje_$_orden'];
                  return ListTile(
                    title: Text('${item['nombre_postulante'] ?? 'Candidato'}'),
                    subtitle: Text(
                      '${item['estado'] ?? ''} · ${item['experiencia_anios'] ?? 0} años',
                    ),
                    trailing: score == null
                        ? const Text('Sin puntaje')
                        : Text('$score'),
                  );
                },
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _offset == 0
                      ? null
                      : () => setState(() {
                          _offset = (_offset - _limit).clamp(0, total);
                          _cargar();
                        }),
                ),
                Text(
                  '${total == 0 ? 0 : _offset + 1}-${(_offset + items.length)} de $total',
                ),
                IconButton(
                  tooltip: 'Página siguiente',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _offset + items.length >= total
                      ? null
                      : () => setState(() {
                          _offset += _limit;
                          _cargar();
                        }),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
