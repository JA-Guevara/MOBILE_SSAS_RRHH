import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

const _forest = Color(0xFF153F30);
const _green = Color(0xFF16845B);
const _mint = Color(0xFFE7F5EC);
const _paper = Color(0xFFF5F7F3);

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.api, super.key});
  final StaffApi api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  Timer? _timer;
  bool _loading = false;
  bool _active = true;
  bool _changed = false;
  String? _error;
  DateTime? _updated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_active) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final next = await widget.api.dashboard();
      if (!mounted) return;
      setState(() {
        final previous = _data;
        _changed = previous != null && !_sameSnapshot(previous, next);
        _data = next;
        _error = null;
        _updated = DateTime.now();
      });
    } on StaffApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'No se pudo actualizar el resumen.');
      }
    } finally {
      _loading = false;
    }
  }

  bool _sameSnapshot(Map<String, dynamic> a, Map<String, dynamic> b) =>
      a.toString() == b.toString();

  Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  int _number(Object? value) => value is num ? value.toInt() : 0;

  int _sum(Map<String, dynamic> values) =>
      values.values.fold(0, (total, value) => total + _number(value));

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final platform = data?['alcance'] == 'PLATAFORMA';
    final totals = _map(data?[platform ? 'plataforma' : 'empresa']);
    final vacancies = _map(totals['vacantes_por_estado']);
    final applications = _map(totals['postulaciones_por_etapa']);
    final trends = _list(data?['tendencias']);
    final activity = _list(data?['bitacora_reciente']);
    return Scaffold(
      backgroundColor: _paper,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 198,
              pinned: true,
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0E3026), Color(0xFF21694C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 65, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            platform
                                ? 'VISTA DE PLATAFORMA'
                                : 'VISTA DE EMPRESA',
                            style: const TextStyle(
                              letterSpacing: 2,
                              fontSize: 11,
                              color: Color(0xFFB9E5C9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 38,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Lo que está pasando, en tiempo real.',
                            style: TextStyle(color: Color(0xFFD2E7DB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data == null && _error == null)
                      const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_error != null)
                      _notice(_error!, Icons.wifi_off_rounded, error: true),
                    if (data != null) ...[
                      _notice(
                        _changed
                            ? 'Hay nuevos movimientos en el sistema'
                            : 'Actualizado automáticamente · ${_clock(_updated)}',
                        _changed
                            ? Icons.auto_awesome_rounded
                            : Icons.sync_rounded,
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle('En un vistazo', 'Indicadores clave'),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 12) / 2;
                          final cards = platform
                              ? <Widget>[
                                  _metric(
                                    'Empresas activas',
                                    totals['empresas_activas'],
                                    Icons.domain_rounded,
                                  ),
                                  _metric(
                                    'Usuarios',
                                    totals['usuarios_totales'],
                                    Icons.people_alt_rounded,
                                  ),
                                  _metric(
                                    'Vacantes publicadas',
                                    totals['vacantes_publicadas'],
                                    Icons.work_outline_rounded,
                                  ),
                                  _metric(
                                    'Postulaciones del mes',
                                    totals['postulaciones_del_mes'],
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                ]
                              : <Widget>[
                                  _metric(
                                    'Usuarios activos',
                                    totals['usuarios_activos'],
                                    Icons.people_alt_rounded,
                                  ),
                                  _metric(
                                    'Vacantes',
                                    _sum(vacancies),
                                    Icons.work_outline_rounded,
                                  ),
                                  _metric(
                                    'Postulaciones',
                                    _sum(applications),
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                  _metric(
                                    'Departamentos',
                                    totals['departamentos'],
                                    Icons.account_tree_outlined,
                                  ),
                                ];
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: cards
                                .map(
                                  (card) => SizedBox(width: width, child: card),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      _trendCard(trends),
                      if (!platform) ...[
                        const SizedBox(height: 18),
                        _distribution(
                          'Vacantes por estado',
                          vacancies,
                          const Color(0xFF16845B),
                        ),
                        const SizedBox(height: 18),
                        _distribution(
                          'Postulaciones por etapa',
                          applications,
                          const Color(0xFFD29A46),
                        ),
                      ],
                      const SizedBox(height: 25),
                      const _SectionTitle(
                        'Actividad reciente',
                        'Últimos movimientos',
                      ),
                      const SizedBox(height: 12),
                      if (activity.isEmpty)
                        _empty('Todavía no hay movimientos para mostrar.')
                      else
                        ...activity.take(8).map(_activityItem),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _clock(DateTime? date) => date == null
      ? '—'
      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _notice(String message, IconData icon, {bool error = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFECE8) : _mint,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: error ? Colors.red.shade700 : _green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? Colors.red.shade800 : _forest,
                  fontSize: 12,
                ),
              ),
            ),
            if (error)
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reintentar',
              ),
          ],
        ),
      );

  Widget _metric(String label, Object? count, IconData icon) => Container(
    height: 124,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green, size: 21),
        const Spacer(),
        Text(
          '${_number(count)}',
          style: const TextStyle(
            color: _forest,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF697A70), fontSize: 12),
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE3EAE3)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A153F30), blurRadius: 15, offset: Offset(0, 5)),
    ],
  );

  Widget _trendCard(List<Map<String, dynamic>> trends) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendencia de seis meses',
          style: TextStyle(
            color: _forest,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Vacantes y postulaciones registradas',
          style: TextStyle(color: Color(0xFF77867D), fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (trends.isEmpty)
          _empty('Aún no hay datos de tendencia.')
        else ...[
          SizedBox(
            height: 145,
            width: double.infinity,
            child: CustomPaint(painter: _TrendPainter(trends)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: trends.map((item) {
              final month = '${item['mes'] ?? ''}';
              return Text(
                month.length >= 7 ? month.substring(5, 7) : month,
                style: const TextStyle(fontSize: 10, color: Color(0xFF74827A)),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          const Wrap(
            spacing: 18,
            children: [
              _Legend('Vacantes', _green),
              _Legend('Postulaciones', Color(0xFFD29A46)),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _distribution(String title, Map<String, dynamic> values, Color color) {
    final entries =
        values.entries.where((entry) => _number(entry.value) > 0).toList()
          ..sort((a, b) => _number(b.value).compareTo(_number(a.value)));
    final maxValue = entries.isEmpty ? 1 : _number(entries.first.value);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          if (entries.isEmpty) _empty('Sin registros en esta sección.'),
          ...entries
              .take(7)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key.replaceAll('_', ' '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _forest,
                              ),
                            ),
                          ),
                          Text(
                            '${_number(entry.value)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _forest,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _number(entry.value) / maxValue,
                          minHeight: 7,
                          backgroundColor: _paper,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _activityItem(Map<String, dynamic> item) {
    final date = DateTime.tryParse('${item['fecha'] ?? ''}')?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, size: 18, color: _green),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['accion'] ?? 'Movimiento'}',
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['descripcion'] ?? item['modulo'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A70),
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}/${date.month}/${date.year} · ${_clock(date)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF82918A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF7A8980), fontSize: 12),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          color: _forest,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF77867D)),
      ),
    ],
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF697A70)),
      ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.data);
  final List<Map<String, dynamic>> data;

  @override
  void paint(Canvas canvas, Size size) {
    final maximum = math.max(
      1,
      data.fold<int>(
        0,
        (maxValue, row) => math.max(
          maxValue,
          math.max(_value(row['vacantes']), _value(row['postulaciones'])),
        ),
      ),
    );
    final grid = Paint()
      ..color = const Color(0xFFE8EEE8)
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = size.height * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _draw(canvas, size, maximum, 'vacantes', _green);
    _draw(canvas, size, maximum, 'postulaciones', const Color(0xFFD29A46));
  }

  static int _value(Object? value) => value is num ? value.toInt() : 0;

  void _draw(Canvas canvas, Size size, int maxValue, String key, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : size.width * i / (data.length - 1);
      final y =
          size.height -
          (_value(data[i][key]) / maxValue * (size.height - 8)) -
          4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.data.toString() != data.toString();
}
