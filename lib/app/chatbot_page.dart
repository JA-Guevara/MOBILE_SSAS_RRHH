import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ssas_rrhh/core/constants/app_constants.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage.publico({super.key, required this.slug}) : staffApi = null;
  const ChatbotPage.personal({super.key, required this.staffApi}) : slug = null;

  final String? slug;
  final StaffApi? staffApi;

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _client = http.Client();
  final _messages = <_ChatMessage>[];
  List<String> _suggestions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Uri _url(String path) => Uri.parse(
    '${AppConstants.apiBaseUrl}/chatbot/publico/'
    '${Uri.encodeComponent(widget.slug!)}/$path',
  );

  Future<Object?> _publicRequest(
    String method,
    String path, [
    String? question,
  ]) async {
    try {
      final response =
          await (method == 'GET'
                  ? _client.get(_url(path))
                  : _client.post(
                      _url(path),
                      headers: {'content-type': 'application/json'},
                      body: jsonEncode({'pregunta': question}),
                    ))
              .timeout(const Duration(seconds: 60));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StaffApiException(
          response.statusCode,
          data is Map && data['detail'] is String
              ? data['detail'] as String
              : 'No se pudo consultar.',
        );
      }
      return data;
    } on StaffApiException {
      rethrow;
    } on Exception {
      throw const StaffApiException(0, 'No se pudo conectar con el servidor.');
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final items = widget.staffApi != null
          ? await widget.staffApi!.chatbotSuggestions()
          : (await _publicRequest('GET', 'sugerencias') as List).cast<String>();
      if (mounted) setState(() => _suggestions = items);
    } on Exception {
      // El chat sigue disponible aunque no haya preguntas sugeridas.
    }
  }

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _controller.text).trim();
    if (text.length < 3 || _loading) return;
    setState(() {
      _controller.clear();
      _error = null;
      _messages.add(_ChatMessage(text, true));
      _loading = true;
    });
    try {
      final data = widget.staffApi != null
          ? await widget.staffApi!.askChatbot(text)
          : await _publicRequest('POST', 'mensajes', text)
                as Map<String, dynamic>;
      final result = data;
      final sources = (result['fuentes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                _ChatSource('${item['id'] ?? ''}', '${item['titulo'] ?? ''}'),
          )
          .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
          .toList();
      final links = (result['enlaces'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                _ChatLink('${item['titulo'] ?? ''}', '${item['ruta'] ?? ''}'),
          )
          .where((item) => item.title.isNotEmpty && _isLocalRoute(item.route))
          .toList();
      if (mounted) {
        setState(
          () => _messages.add(
            _ChatMessage(
              '${result['respuesta'] ?? 'Sin respuesta.'}',
              false,
              sources,
              links,
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _controller.text = text;
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  bool _isLocalRoute(String route) {
    final uri = Uri.tryParse(route);
    return uri != null &&
        route.startsWith('/') &&
        !route.startsWith('//') &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  bool _canOpenRoute(String route) {
    if (widget.staffApi != null) {
      return const {
        '/reportes',
        '/postulantes',
        '/vacantes',
        '/seleccion',
      }.contains(route);
    }
    final parts = Uri.parse(route).pathSegments;
    return parts.length >= 2 &&
        parts[0] == 'empleos' &&
        parts[1] == widget.slug &&
        (parts.length == 2 || (parts.length == 4 && parts[2] == 'vacantes'));
  }

  void _openLink(_ChatLink link) {
    if (_canOpenRoute(link.route)) {
      Navigator.of(context).pop(link.route);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta sección está disponible en la web.')),
    );
  }

  Future<void> _openSource(_ChatSource source) async {
    try {
      final article = widget.staffApi != null
          ? await widget.staffApi!.readChatbotArticle(source.id)
          : await _publicRequest('GET', 'articulos/${source.id}')
                as Map<String, dynamic>;
      if (!mounted) return;
      final data = article;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${data['titulo'] ?? source.title}'),
          content: SingleChildScrollView(
            child: Text('${data['contenido'] ?? ''}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Asistente RRHH')),
    body: SafeArea(
      child: Column(
        children: [
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, index) => ActionChip(
                  label: Text(_suggestions[index]),
                  onPressed: _loading ? null : () => _send(_suggestions[index]),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (_messages.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Hola. ¿En qué puedo ayudarte?'),
                      ),
                    ),
                  ),
                for (final item in _messages)
                  Align(
                    alignment: item.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Card(
                        color: item.fromUser ? const Color(0xFFDCF1E7) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.text),
                              if (item.sources.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                for (final source in item.sources)
                                  TextButton(
                                    onPressed: () => _openSource(source),
                                    child: Text(source.title),
                                  ),
                              ],
                              if (item.links.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                for (final link in item.links)
                                  TextButton.icon(
                                    onPressed: () => _openLink(link),
                                    icon: Icon(
                                      _canOpenRoute(link.route)
                                          ? Icons.open_in_new
                                          : Icons.language,
                                      size: 18,
                                    ),
                                    label: Text(link.title),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 350,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu pregunta',
                      counterText: '',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar pregunta',
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatMessage {
  const _ChatMessage(
    this.text,
    this.fromUser, [
    this.sources = const [],
    this.links = const [],
  ]);
  final String text;
  final bool fromUser;
  final List<_ChatSource> sources;
  final List<_ChatLink> links;
}

class _ChatLink {
  const _ChatLink(this.title, this.route);
  final String title;
  final String route;
}

class _ChatSource {
  const _ChatSource(this.id, this.title);
  final String id;
  final String title;
}
