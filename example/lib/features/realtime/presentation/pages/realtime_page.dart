import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/info_tile.dart';

/// Shows realtime connection information and manual controls.
class RealtimePage extends StatefulWidget {
  const RealtimePage({super.key});

  @override
  State<RealtimePage> createState() => _RealtimePageState();
}

class _RealtimePageState extends State<RealtimePage> {
  bool _loading = false;
  String? _message;
  String? _errorMessage;

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.connectRealtime();

      setState(() {
        _message = 'Realtime client initialized.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = ErrorPresenter.messageFrom(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.disconnectRealtime();

      setState(() {
        _message = 'Realtime disconnected.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = ErrorPresenter.messageFrom(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = HosteDay.realtime.isConnected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const ExampleHeader(
          title: 'Realtime',
          subtitle: 'Connect to HosteDay realtime and receive live events.',
        ),
        const SizedBox(height: 16),
        InfoTile(label: 'Realtime host', value: HosteDay.config.realtimeHost),
        InfoTile(label: 'Realtime URL', value: HosteDay.config.realtimeUrl),
        InfoTile(label: 'Client initialized', value: connected ? 'Yes' : 'No'),
        const SizedBox(height: 16),
        if (_message != null) ...<Widget>[
          SuccessBox(message: _message!),
          const SizedBox(height: 12),
        ],
        if (_errorMessage != null) ...<Widget>[
          ErrorBox(message: _errorMessage!),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton(
              onPressed: _loading ? null : _connect,
              child: const Text('Connect realtime'),
            ),
            OutlinedButton(
              onPressed: _loading ? null : _disconnect,
              child: const Text('Disconnect'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'The Posts page also connects to realtime and listens for '
          'PostCreated events.',
        ),
      ],
    );
  }
}
