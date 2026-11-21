import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class IndicatorsPage extends StatefulWidget {
  const IndicatorsPage({required this.api, this.companyId, super.key});
  final StaffApi api;
  final String? companyId;
  @override
  State<IndicatorsPage> createState() => _IndicatorsPageState();
}

class _IndicatorsPageState extends State<IndicatorsPage> {
  late DateTime _to = DateTime.now();
  late DateTime _from = DateTime(_to.year, _to.month, 1);
  late Future<Map<String, dynamic>> _data = _load();
  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<Map<String, dynamic>> _load() => widget.api.indicators(
    _date(_from),
    _date(_to),
    companyId: widget.companyId,
  );

  Future<void> _pick(bool start) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _from = selected;
      } else {
        _to = selected;
      }
      if (_from.isAfter(_to)) _to = _from;
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Indicadores')),
    body: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _pick(true),
                child: Text('Desde ${_date(_from)}'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _pick(false),
                child: Text('Hasta ${_date(_to)}'),
              ),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder(
            future: _data,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No se pudieron cargar los indicadores: ${snapshot.error}',
                      ),
                      TextButton(
                        onPressed: () => setState(() => _data = _load()),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final data = snapshot.data!;
              final rotation = data['rotacion'] as Map<String, dynamic>;
              final absence = data['ausentismo'] as Map<String, dynamic>;
              final hiring =
                  data['tiempo_promedio_contratacion'] as Map<String, dynamic>;
              final initial = (rotation['dotacion_inicial'] as num).toDouble();
              final finalCount = (rotation['dotacion_final'] as num).toDouble();
              final variation = initial == 0
                  ? null
                  : (finalCount - initial) * 100 / initial;
              Widget card(String title, String value, String detail) => Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(detail),
                  trailing: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              );
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _data = _load());
                  await _data;
                },
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    card(
                      'Dotación',
                      '${rotation['dotacion_final']}',
                      'Inicial: ${rotation['dotacion_inicial']} · Variación: ${variation == null ? 'Sin base' : '${variation.toStringAsFixed(1)}%'}',
                    ),
                    card(
                      'Rotación',
                      '${rotation['porcentaje']}%',
                      'Ingresos: ${rotation['ingresos']} · Salidas: ${rotation['salidas']}',
                    ),
                    card(
                      'Ausentismo',
                      '${absence['porcentaje']}%',
                      '${absence['dias_habiles_ausentes']} días hábiles ausentes',
                    ),
                    card(
                      'Contratación',
                      hiring['dias'] == null
                          ? 'Sin datos'
                          : '${hiring['dias']} días',
                      '${hiring['contrataciones_medir']} contrataciones medidas',
                    ),
                    for (final dept
                        in (data['headcount_por_departamento'] as List)
                            .cast<Map<String, dynamic>>())
                      card(
                        '${dept['departamento']}',
                        '${dept['empleados']}',
                        'Personal por departamento',
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
