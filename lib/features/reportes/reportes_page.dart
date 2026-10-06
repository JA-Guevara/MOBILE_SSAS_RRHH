import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/features/reportes/report_config.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({
    super.key,
    required this.api,
    required this.permissions,
    this.empresaId,
  });

  final StaffApi api;
  final Set<String> permissions;
  final String? empresaId;

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final _prompt = TextEditingController();
  static final SpeechToText _speech = SpeechToText();
  static _ReportesPageState? _activeVoicePage;
  List<Map<String, dynamic>>? _catalog;
  List<Map<String, dynamic>> _saved = [];
  String? _source;
  List<String> _columns = [];
  List<ReportFilter> _filters = [];
  List<ReportOrder> _order = [];
  Map<String, dynamic>? _preview;
  String? _savedId;
  String? _savedName;
  String? _error;
  String? _hint;
  bool _loading = true;
  bool _busy = false;
  bool _listening = false;
  int _page = 1;
  int _revision = 0;

  bool get _platform =>
      widget.permissions.contains('platform:reportes:gestionar');
  bool _can(String permission) =>
      _platform || widget.permissions.contains(permission);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (identical(_activeVoicePage, this)) {
      _activeVoicePage = null;
      _speech.cancel();
    }
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await widget.api.reportCatalog();
      final saved = await widget.api.savedReports(empresaId: widget.empresaId);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _saved = saved;
        if (_source == null && catalog.isNotEmpty) {
          _source = catalog.first['codigo'] as String;
          _columns = (catalog.first['columnas'] as List)
              .cast<String>()
              .take(4)
              .toList();
        }
      });
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar el catálogo de reportes.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> get _availableColumns {
    for (final source in _catalog ?? const <Map<String, dynamic>>[]) {
      if (source['codigo'] == _source) {
        return (source['columnas'] as List).cast<String>();
      }
    }
    return [];
  }

  String _label(String value) => value.replaceAll('_', ' ');

  void _invalidate() {
    _revision++;
    _page = 1;
    _preview = null;
    _error = null;
  }

  void _edit(void Function() change) => setState(() {
    change();
    _invalidate();
  });

  void _chooseSource(String source) => _edit(() {
    _source = source;
    _columns = _availableColumns.take(4).toList();
    _filters = [];
    _order = [];
    _savedId = null;
    _savedName = null;
  });

  ReportConfig? _config() {
    if (_source == null || _columns.isEmpty) {
      setState(() => _error = 'Selecciona al menos una columna.');
      return null;
    }
    return ReportConfig(
      source: _source!,
      columns: List.of(_columns),
      filters: List.of(_filters),
      order: List.of(_order),
    );
  }

  void _applyConfig(ReportConfig config, {String? id, String? name}) {
    final source = (_catalog ?? []).where(
      (item) => item['codigo'] == config.source,
    );
    if (source.isEmpty) {
      setState(() => _error = 'La fuente propuesta ya no está disponible.');
      return;
    }
    final allowed = (source.first['columnas'] as List).cast<String>().toSet();
    if (config.columns.isEmpty ||
        config.columns.length > 20 ||
        config.columns.toSet().length != config.columns.length ||
        config.filters.length > 10 ||
        config.order.length > 5 ||
        !config.columns.every(allowed.contains) ||
        !config.filters.every((item) => allowed.contains(item.field)) ||
        !config.order.every((item) => allowed.contains(item.field))) {
      setState(
        () => _error =
            'La configuración del reporte no es válida para esta fuente.',
      );
      return;
    }
    _edit(() {
      _source = config.source;
      _columns = List.of(config.columns);
      _filters = config.filters.map(_normalizeDateFilter).toList();
      _order = List.of(config.order);
      _savedId = id;
      _savedName = name;
    });
  }

  ReportFilter _normalizeDateFilter(ReportFilter filter) {
    final dateField =
        filter.field.startsWith('fecha_') || filter.field == 'ultimo_acceso';
    if (!dateField) {
      return filter;
    }
    String endOfDay(Object value) {
      final text = '$value';
      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)
          ? '${text}T23:59:59.999999'
          : text;
    }

    if (filter.operator == 'menor_igual') {
      return ReportFilter(
        field: filter.field,
        operator: filter.operator,
        value: endOfDay(filter.value),
      );
    }
    if (filter.operator == 'entre' &&
        filter.value is List &&
        (filter.value as List).length == 2) {
      final values = filter.value as List;
      return ReportFilter(
        field: filter.field,
        operator: filter.operator,
        value: [values.first, endOfDay(values.last)],
      );
    }
    return filter;
  }

  Future<void> _interpret() async {
    final text = _prompt.text.trim();
    if (text.length < 3 || text.length > 500) {
      setState(() => _error = 'Escribe una consulta de 3 a 500 caracteres.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _hint = null;
    });
    try {
      final response = await widget.api.interpretReport(
        text,
        empresaId: widget.empresaId,
      );
      if (!mounted) {
        return;
      }
      final proposed = response['config'];
      if (proposed is Map<String, dynamic>) {
        _applyConfig(ReportConfig.fromJson(proposed));
        if (_error == null) {
          setState(() => _hint = 'Revisa la configuración antes de consultar.');
        }
      } else {
        setState(
          () => _hint =
              '${response['aclaracion'] ?? 'Aclara qué reporte necesitas.'}',
        );
      }
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = 'La IA devolvió una configuración inválida.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggleSpeech() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }
    setState(() => _error = null);
    try {
      _activeVoicePage = this;
      final available = await _speech.initialize(
        onStatus: (status) {
          final page = _activeVoicePage;
          if (page != null && page.mounted && status != 'listening') {
            page.setState(() => page._listening = false);
          }
        },
        onError: (error) {
          final page = _activeVoicePage;
          if (page != null && page.mounted) {
            page.setState(() {
              page._listening = false;
              page._error =
                  'No se pudo reconocer la voz. Puedes escribir la consulta.';
            });
          }
        },
        options: [SpeechToText.androidNoBluetooth],
      );
      if (!mounted) {
        return;
      }
      if (!available) {
        if (mounted) {
          setState(
            () => _error =
                'El micrófono o el servicio de voz no está disponible.',
          );
        }
        return;
      }
      final locales = await _speech.locales();
      if (!mounted) {
        return;
      }
      String? locale;
      for (final candidate in ['es_BO', 'es-BO', 'es_ES', 'es-ES']) {
        for (final item in locales) {
          if (item.localeId == candidate) {
            locale = item.localeId;
          }
        }
        if (locale != null) {
          break;
        }
      }
      locale ??= locales
          .where((item) => item.localeId.startsWith('es'))
          .firstOrNull
          ?.localeId;
      final prefix = _prompt.text.trim();
      await _speech.listen(
        listenOptions: SpeechListenOptions(localeId: locale),
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) {
            return;
          }
          final words = result.recognizedWords.trim();
          _prompt.text = [
            prefix,
            words,
          ].where((item) => item.isNotEmpty).join(' ');
          _prompt.selection = TextSelection.collapsed(
            offset: _prompt.text.length,
          );
        },
      );
      if (mounted) {
        setState(() => _listening = _speech.isListening);
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar el reconocimiento de voz.');
      }
    }
  }

  Future<void> _runPreview({int page = 1}) async {
    final config = _config();
    if (config == null) {
      return;
    }
    final revision = _revision;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.api.previewReport(
        config,
        empresaId: widget.empresaId,
        page: page,
      );
      if (mounted && revision == _revision) {
        setState(() {
          _preview = preview;
          _page = page;
        });
      }
    } on StaffApiException catch (error) {
      if (mounted && revision == _revision) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _save() async {
    final config = _config();
    if (config == null) {
      return;
    }
    final name = TextEditingController(text: _savedName);
    final entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _savedId == null ? 'Guardar reporte' : 'Actualizar reporte',
        ),
        content: TextField(
          controller: name,
          autofocus: true,
          maxLength: 160,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    if (!mounted) {
      return;
    }
    if (entered == null) {
      return;
    }
    if (entered.length < 3) {
      setState(() => _error = 'El nombre debe tener al menos 3 caracteres.');
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = _savedId == null
          ? await widget.api.createReport(
              entered,
              config,
              empresaId: widget.empresaId,
            )
          : await widget.api.updateReport(
              _savedId!,
              entered,
              config,
              empresaId: widget.empresaId,
            );
      final list = await widget.api.savedReports(empresaId: widget.empresaId);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedId = saved['id'] as String?;
        _savedName = entered;
        _saved = list;
        _error = null;
        _hint = 'Reporte guardado.';
      });
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _export(String format) async {
    final config = _config();
    if (config == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await widget.api.exportReport(
        format,
        config,
        empresaId: widget.empresaId,
      );
      if (!mounted) {
        return;
      }
      final mime = switch (format) {
        'pdf' => 'application/pdf',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        _ => 'text/html',
      };
      final uri = await FilePicker.saveFile(
        fileName: 'reporte.$format',
        bytes: bytes,
        mimeType: mime,
      );
      if (mounted && uri != null) {
        setState(() => _hint = 'Reporte guardado.');
      }
    } on StaffApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el archivo.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _editFilter([int? index]) async {
    if (index == null && _filters.length >= 10) {
      return;
    }
    final result = await showDialog<ReportFilter>(
      context: context,
      builder: (_) => _FilterDialog(
        fields: _availableColumns,
        initial: index == null ? null : _filters[index],
      ),
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    _edit(() {
      if (index == null) {
        _filters = [..._filters, result];
      } else {
        _filters[index] = result;
      }
    });
  }

  Future<void> _editOrder() async {
    if (_order.length >= 5) {
      return;
    }
    final field = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ordenar por'),
        children: [
          for (final item in _availableColumns.where(
            (column) => !_order.any((item) => item.field == column),
          ))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(_label(item)),
            ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (field == null) {
      return;
    }
    _edit(() {
      _order = [..._order, ReportOrder(field: field, direction: 'asc')];
    });
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reportes')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _catalog == null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'No se pudieron cargar los reportes.'),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_hint!),
                ),
              if (_saved.isNotEmpty)
                DropdownButtonFormField<String?>(
                  key: ValueKey(_savedId),
                  isExpanded: true,
                  initialValue: _savedId,
                  decoration: const InputDecoration(
                    labelText: 'Reportes guardados',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nuevo reporte'),
                    ),
                    for (final report in _saved)
                      DropdownMenuItem<String?>(
                        value: report['id'] as String,
                        child: Text(
                          '${report['nombre']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == null) {
                      _edit(() {
                        _savedId = null;
                        _savedName = null;
                      });
                      return;
                    }
                    final report = _saved.firstWhere(
                      (item) => item['id'] == id,
                    );
                    _applyConfig(
                      ReportConfig.fromJson(report),
                      id: id,
                      name: report['nombre'] as String?,
                    );
                  },
                ),
              if (_can('reportes:ejecutar')) ...[
                _section('Solicitar con IA'),
                TextField(
                  controller: _prompt,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Describe el reporte',
                    hintText: 'Postulaciones del mes ordenadas por fecha',
                    suffixIcon: IconButton(
                      tooltip: _listening
                          ? 'Detener dictado'
                          : 'Dictar consulta',
                      onPressed: _busy ? null : _toggleSpeech,
                      icon: Icon(
                        _listening
                            ? Icons.stop_circle_outlined
                            : Icons.mic_none,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'El teléfono puede usar su servicio de voz. Solo el texto confirmado se envía para interpretarlo.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _interpret,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Interpretar'),
                  ),
                ),
              ],
              _section('Fuente y columnas'),
              DropdownButtonFormField<String>(
                key: ValueKey(_source),
                isExpanded: true,
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Fuente'),
                items: [
                  for (final item in _catalog!)
                    DropdownMenuItem(
                      value: item['codigo'] as String,
                      child: Text('${item['nombre']}'),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          _chooseSource(value);
                        }
                      },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  for (final column in _availableColumns)
                    FilterChip(
                      label: Text(_label(column)),
                      selected: _columns.contains(column),
                      onSelected: _busy
                          ? null
                          : (selected) => _edit(() {
                              if (selected && _columns.length < 20) {
                                _columns = [..._columns, column];
                              }
                              if (!selected) {
                                _columns = _columns
                                    .where((item) => item != column)
                                    .toList();
                              }
                            }),
                    ),
                ],
              ),
              _section('Filtros'),
              for (var i = 0; i < _filters.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_label(_filters[i].field)} · ${_label(_filters[i].operator)}',
                  ),
                  subtitle: Text('${_filters[i].value}'),
                  onTap: _busy ? null : () => _editFilter(i),
                  trailing: IconButton(
                    tooltip: 'Quitar filtro',
                    onPressed: _busy
                        ? null
                        : () => _edit(() => _filters.removeAt(i)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              TextButton.icon(
                onPressed:
                    _busy || _filters.length >= 10 || _availableColumns.isEmpty
                    ? null
                    : () => _editFilter(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar filtro'),
              ),
              _section('Orden'),
              for (var i = 0; i < _order.length; i++)
                Builder(
                  builder: (context) {
                    final index = i;
                    final item = _order[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${index + 1}. ${_label(item.field)}',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar orden',
                              onPressed: _busy
                                  ? null
                                  : () => _edit(() => _order.removeAt(index)),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'asc', label: Text('Asc')),
                            ButtonSegment(value: 'desc', label: Text('Desc')),
                          ],
                          selected: {item.direction},
                          onSelectionChanged: _busy
                              ? null
                              : (value) => _edit(() {
                                  _order[index] = ReportOrder(
                                    field: item.field,
                                    direction: value.first,
                                  );
                                }),
                        ),
                      ],
                    );
                  },
                ),
              TextButton.icon(
                onPressed:
                    _busy ||
                        _order.length >= 5 ||
                        _order.length >= _availableColumns.length
                    ? null
                    : _editOrder,
                icon: const Icon(Icons.sort),
                label: const Text('Elegir orden'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_can('reportes:ejecutar'))
                    FilledButton.icon(
                      onPressed: _busy ? null : _runPreview,
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Vista previa'),
                    ),
                  if ((_savedId == null && _can('reportes:crear')) ||
                      (_savedId != null && _can('reportes:editar')))
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_savedId == null ? 'Guardar' : 'Actualizar'),
                    ),
                  if (_can('reportes:exportar'))
                    PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: 'Exportar reporte',
                      onSelected: _export,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'pdf', child: Text('PDF')),
                        PopupMenuItem(value: 'xlsx', child: Text('Excel')),
                        PopupMenuItem(value: 'html', child: Text('HTML')),
                      ],
                      icon: const Icon(Icons.download_outlined),
                    ),
                ],
              ),
              if (_preview != null) ...[
                _section('Resultados'),
                Text('${_preview!['total'] ?? 0} registros'),
                const SizedBox(height: 8),
                if ((_preview!['items'] as List? ?? []).isEmpty)
                  const Text('No hay resultados para estos filtros.'),
                if ((_preview!['items'] as List? ?? []).isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 90,
                      columns: [
                        for (final name
                            in (_preview!['columnas'] as List).cast<String>())
                          DataColumn(label: Text(_label(name))),
                      ],
                      rows: [
                        for (final raw in (_preview!['items'] as List))
                          DataRow(
                            cells: [
                              for (final name
                                  in (_preview!['columnas'] as List)
                                      .cast<String>())
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 220,
                                    ),
                                    child: Text(
                                      '${(raw as Map<String, dynamic>)[name] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Página anterior',
                      onPressed: _busy || _page <= 1
                          ? null
                          : () => _runPreview(page: _page - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Página $_page'),
                    IconButton(
                      tooltip: 'Página siguiente',
                      onPressed:
                          _busy ||
                              _page * 25 >= (_preview!['total'] as int? ?? 0)
                          ? null
                          : () => _runPreview(page: _page + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ],
          ),
  );
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({required this.fields, this.initial});

  final List<String> fields;
  final ReportFilter? initial;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String _field;
  late String _operator;
  late final TextEditingController _first;
  late final TextEditingController _second;
  bool _boolValue = true;
  String? _error;

  bool get _date => _field.startsWith('fecha_') || _field == 'ultimo_acceso';
  bool get _numeric => _field == 'puntaje' || _field == 'cantidad_vacantes';
  bool get _boolean => _field == 'activo';

  @override
  void initState() {
    super.initState();
    _field = widget.initial?.field ?? widget.fields.first;
    _operator = widget.initial?.operator ?? 'igual';
    final value = widget.initial?.value;
    _boolValue = value == null || value == true || value == 'true';
    String display(Object? item) {
      final text = item?.toString() ?? '';
      return _date && text.length >= 10 ? text.substring(0, 10) : text;
    }

    _first = TextEditingController(
      text: display(value is List ? value.first : value),
    );
    _second = TextEditingController(
      text: display(value is List && value.length > 1 ? value[1] : null),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController target) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.tryParse(target.text) ?? DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    if (selected != null) {
      target.text = selected.toIso8601String().substring(0, 10);
    }
  }

  void _submit() {
    if (_boolean) {
      Navigator.pop(
        context,
        ReportFilter(field: _field, operator: 'igual', value: _boolValue),
      );
      return;
    }
    final a = _first.text.trim();
    final b = _second.text.trim();
    if (a.isEmpty || (_operator == 'entre' && b.isEmpty)) {
      setState(() => _error = 'Completa el valor del filtro.');
      return;
    }
    if (_numeric &&
        (num.tryParse(a) == null ||
            (_operator == 'entre' && num.tryParse(b) == null))) {
      setState(() => _error = 'Introduce un número válido.');
      return;
    }
    if (_date &&
        (DateTime.tryParse(a) == null ||
            (_operator == 'entre' && DateTime.tryParse(b) == null))) {
      setState(() => _error = 'Introduce una fecha válida.');
      return;
    }
    if (_operator == 'entre' &&
        ((_numeric && num.parse(a) > num.parse(b)) ||
            (_date && DateTime.parse(a).isAfter(DateTime.parse(b))))) {
      setState(() => _error = 'El valor inicial no puede superar al final.');
      return;
    }
    final start = _date && _operator != 'contiene' ? '${a}T00:00:00' : a;
    final end = _date ? '${b}T23:59:59.999999' : b;
    final operator = _date && _operator == 'igual' ? 'entre' : _operator;
    final value = _date && _operator == 'igual'
        ? <Object>[start, '${a}T23:59:59.999999']
        : _operator == 'entre'
        ? <Object>[
            _numeric ? num.parse(a) : start,
            _numeric ? num.parse(b) : end,
          ]
        : (_numeric
              ? num.parse(a)
              : _date && _operator == 'menor_igual'
              ? '${a}T23:59:59.999999'
              : start);
    Navigator.pop(
      context,
      ReportFilter(field: _field, operator: operator, value: value),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Filtro'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _field,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Campo'),
            items: [
              for (final field in widget.fields)
                DropdownMenuItem(
                  value: field,
                  child: Text(field.replaceAll('_', ' ')),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _field = value;
                  _operator = 'igual';
                  _first.clear();
                  _second.clear();
                });
              }
            },
          ),
          if (!_boolean)
            DropdownButtonFormField<String>(
              initialValue: _operator,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Operador'),
              items: const [
                DropdownMenuItem(value: 'igual', child: Text('Igual')),
                DropdownMenuItem(value: 'contiene', child: Text('Contiene')),
                DropdownMenuItem(
                  value: 'mayor_igual',
                  child: Text('Mayor o igual'),
                ),
                DropdownMenuItem(
                  value: 'menor_igual',
                  child: Text('Menor o igual'),
                ),
                DropdownMenuItem(value: 'entre', child: Text('Entre')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _operator = value);
                }
              },
            ),
          if (_boolean)
            SwitchListTile(
              title: const Text('Activo'),
              value: _boolValue,
              onChanged: (value) => setState(() => _boolValue = value),
            ),
          if (!_boolean)
            TextField(
              controller: _first,
              keyboardType: _numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              readOnly: _date,
              onTap: _date ? () => _pickDate(_first) : null,
              decoration: InputDecoration(
                labelText: _operator == 'entre' ? 'Desde' : 'Valor',
                suffixIcon: _date
                    ? const Icon(Icons.calendar_today_outlined)
                    : null,
              ),
            ),
          if (!_boolean && _operator == 'entre')
            TextField(
              controller: _second,
              keyboardType: _numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              readOnly: _date,
              onTap: _date ? () => _pickDate(_second) : null,
              decoration: InputDecoration(
                labelText: 'Hasta',
                suffixIcon: _date
                    ? const Icon(Icons.calendar_today_outlined)
                    : null,
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Aplicar')),
    ],
  );
}
