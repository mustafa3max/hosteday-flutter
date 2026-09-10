import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import '../auth/presentation/auth_gate.dart';
import '../realtime/presentation/pages/realtime_page.dart';

/// Interactive requests against the configured project; no fixture data.
class ApiExplorerPage extends StatefulWidget {
  const ApiExplorerPage({super.key});
  @override
  State<ApiExplorerPage> createState() => _ApiExplorerPageState();
}

class _ApiExplorerPageState extends State<ApiExplorerPage> {
  final _path = TextEditingController(text: '/products');
  final _search = TextEditingController();
  final _query = TextEditingController(text: '{"page": 1}');
  final _body = TextEditingController(text: '{}');
  final _slug = TextEditingController(text: 'info');
  final _media = TextEditingController(text: 'products/image.png');
  String _method = 'GET';
  String _output =
      'Choose an endpoint that exists in your project, then send a request.';
  bool _withAuth = false;
  bool _busy = false;
  List<Map<String, dynamic>> _rows = [];

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _rows = [];
    });
    try {
      final query = Map<String, Object?>.from(jsonDecode(_query.text) as Map);
      final response = _method == 'GET'
          ? await Hosteday.client.get(
              _path.text,
              search: _search.text,
              queryParameters: query,
              withAuth: _withAuth,
            )
          : await Hosteday.client.request(
              method: _method,
              path: _path.text,
              body: Map<String, dynamic>.from(jsonDecode(_body.text) as Map),
              queryParameters: query,
              withAuth: _withAuth,
            );
      final data = response['data'];
      final list = data is List ? data : (data is Map ? data['data'] : null);
      if (!mounted) return;
      setState(() {
        _output = const JsonEncoder.withIndent('  ').convert(response);
        if (list is List) {
          _rows = list
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
        }
      });
    } on HostedayException catch (error) {
      if (mounted) {
        setState(
          () => _output =
              '${error.statusCode ?? "Transport"}: ${error.displayMessage}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _output = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showUrls() {
    try {
      setState(
        () => _output =
            '${Hosteday.client.staticPages[_slug.text]}\n${Hosteday.client.storageUrl(_media.text)}',
      );
    } catch (error) {
      setState(() => _output = error.toString());
    }
  }

  @override
  void dispose() {
    for (final c in [_path, _search, _query, _body, _slug, _media]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hosteday API explorer'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AuthGate())),
          child: const Text('Account'),
        ),
        TextButton(
          onPressed: Hosteday.config.hasRealtime
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RealtimePage()),
                )
              : null,
          child: const Text('Realtime'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SelectableText(
          'Host: ${Hosteday.client.host}\nAPI: ${Hosteday.client.apiBaseUrl}',
        ),
        const SizedBox(height: 16),
        DropdownButton<String>(
          value: _method,
          items: [
            for (final m in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'])
              DropdownMenuItem(value: m, child: Text(m)),
          ],
          onChanged: _busy ? null : (v) => setState(() => _method = v!),
        ),
        TextField(
          controller: _path,
          decoration: const InputDecoration(
            labelText: 'Endpoint, e.g. /products or /products/15',
          ),
        ),
        TextField(
          controller: _search,
          decoration: const InputDecoration(labelText: 'Search (GET)'),
        ),
        TextField(
          controller: _query,
          decoration: const InputDecoration(
            labelText: 'Query parameters (JSON object)',
          ),
        ),
        if (_method != 'GET')
          TextField(
            controller: _body,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Request body (JSON object)',
            ),
          ),
        SwitchListTile(
          title: const Text('Use signed-in user token'),
          value: _withAuth,
          onChanged: _busy ? null : (v) => setState(() => _withAuth = v),
        ),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: Text(_busy ? 'Loading…' : 'Send $_method'),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _slug,
          decoration: const InputDecoration(labelText: 'Static page slug'),
        ),
        TextField(
          controller: _media,
          decoration: const InputDecoration(labelText: 'Public image path'),
        ),
        OutlinedButton(onPressed: _showUrls, child: const Text('Resolve URLs')),
        const SizedBox(height: 16),
        for (final row in _rows)
          ListTile(
            title: Text('${row['name'] ?? row['title'] ?? row['id']}'),
            subtitle: Text('${row['description'] ?? ''}'),
            leading:
                row['image'] is String && (row['image'] as String).isNotEmpty
                ? Image.network(
                    Hosteday.client.storageUrl(row['image'] as String),
                    width: 48,
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : null,
          ),
        SelectableText(_output),
      ],
    ),
  );
}
