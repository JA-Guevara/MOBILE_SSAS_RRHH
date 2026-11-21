import 'dart:convert';

import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({required this.api, super.key});
  final StaffApi api;

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  late Future<List<Map<String, dynamic>>> _courses = widget.api.myCourses();

  void _reload() => setState(() => _courses = widget.api.myCourses());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis cursos')),
    body: FutureBuilder(
      future: _courses,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No se pudieron cargar los cursos: ${snapshot.error}'),
                TextButton(onPressed: _reload, child: const Text('Reintentar')),
              ],
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('No tienes cursos asignados.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _courses;
          },
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text('${item['curso_titulo'] ?? 'Curso asignado'}'),
                subtitle: Text(
                  [
                    '${item['estado']} · ${item['progreso'] ?? 0}%',
                    if (item['curso_obligatorio'] == true) 'Obligatorio',
                    if (item['fecha_limite'] != null)
                      'Límite: ${item['fecha_limite']}',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _CoursePage(api: widget.api, enrollment: item),
                    ),
                  );
                  _reload();
                },
              );
            },
          ),
        );
      },
    ),
  );
}

class _CoursePage extends StatefulWidget {
  const _CoursePage({required this.api, required this.enrollment});
  final StaffApi api;
  final Map<String, dynamic> enrollment;

  @override
  State<_CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<_CoursePage> {
  late Map<String, dynamic> _enrollment = widget.enrollment;
  late final Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _data =
      _load();
  String? _error;
  bool _busy = false;

  Future<void> _certificate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await widget.api.certificate('${_enrollment['id']}');
      if (kIsWeb) {
        throw const StaffApiException(
          0,
          'La descarga del PDF está disponible en Android e iOS.',
        );
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/certificado-${_enrollment['id']}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw StaffApiException(0, result.message);
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaterial(Map<String, dynamic> lesson) async {
    final raw = lesson['contenido_url']?.toString();
    if (raw == null || raw.isEmpty) return;
    if (raw.startsWith('/api/v1/capacitacion/materiales/')) {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        if (kIsWeb) {
          throw const StaffApiException(
            0,
            'El material protegido se abre desde Android o iOS.',
          );
        }
        final bytes = await widget.api.downloadProtected(
          raw.replaceFirst('/api/v1', ''),
        );
        final name = Uri.parse(raw).pathSegments.last;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          throw StaffApiException(0, result.message);
        }
      } on Exception catch (e) {
        if (mounted) setState(() => _error = '$e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      setState(() => _error = 'El material requiere una URL pública válida.');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = 'No se pudo abrir el material.');
    }
  }

  Future<(Map<String, dynamic>, List<Map<String, dynamic>>)> _load() async {
    final id = '${_enrollment['curso_id']}';
    return (await widget.api.course(id), await widget.api.lessons(id));
  }

  Future<void> _complete(Map<String, dynamic> lesson) async {
    List<int>? answers;
    if (lesson['tipo'] == 'QUIZ') {
      final content =
          jsonDecode('${lesson['contenido_texto']}') as Map<String, dynamic>;
      final questions = (content['preguntas'] as List)
          .cast<Map<String, dynamic>>();
      final chosen = List<int?>.filled(questions.length, null);
      answers = await showDialog<List<int>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text('${lesson['titulo']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < questions.length; i++) ...[
                    Text('${questions[i]['enunciado']}'),
                    DropdownButton<int>(
                      hint: const Text('Selecciona una respuesta'),
                      value: chosen[i],
                      isExpanded: true,
                      items: [
                        for (
                          var j = 0;
                          j < (questions[i]['opciones'] as List).length;
                          j++
                        )
                          DropdownMenuItem<int>(
                            value: j,
                            child: Text('${questions[i]['opciones'][j]}'),
                          ),
                      ],
                      onChanged: (value) => update(() => chosen[i] = value),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: chosen.contains(null)
                    ? null
                    : () => Navigator.pop(context, chosen.cast<int>()),
                child: const Text('Enviar respuestas'),
              ),
            ],
          ),
        ),
      );
      if (answers == null) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.completeLesson(
        '${_enrollment['id']}',
        '${lesson['id']}',
        answers: answers,
      );
      if (mounted) setState(() => _enrollment = result);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Curso asignado')),
    body: FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('No se pudo cargar el curso: ${snapshot.error}'),
          );
        }
        final (course, lessons) = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${course['titulo']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${course['descripcion'] ?? ''}'),
            Text(
              'Estado: ${_enrollment['estado']} · Avance: ${_enrollment['progreso'] ?? 0}%',
            ),
            if (_enrollment['fecha_limite'] != null)
              Text('Fecha límite: ${_enrollment['fecha_limite']}'),
            if (_enrollment['aprobado'] == true)
              FilledButton.icon(
                onPressed: _busy ? null : _certificate,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Ver o descargar certificado'),
              ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            for (final lesson in lessons)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('${lesson['titulo']}'),
                      subtitle: Text(
                        '${lesson['tipo']}\n${lesson['contenido_texto'] == null || lesson['tipo'] == 'QUIZ' ? '' : lesson['contenido_texto']}',
                      ),
                      isThreeLine: true,
                      trailing: _busy
                          ? null
                          : TextButton(
                              onPressed: () => _complete(lesson),
                              child: const Text('Completar'),
                            ),
                    ),
                    if (lesson['contenido_url'] != null)
                      TextButton.icon(
                        onPressed: () => _openMaterial(lesson),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir material'),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
