import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/models/action_feedback.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/current_session_section.dart';
import '../widgets/profile_section.dart';
import '../widgets/protected_api_section.dart';
import '../widgets/realtime_log_section.dart';
import '../widgets/realtime_section.dart';

class HosteDayHomePage extends StatefulWidget {
  const HosteDayHomePage({super.key, required this.user});

  final HosteDayUser user;

  @override
  State<HosteDayHomePage> createState() => _HosteDayHomePageState();
}

class _HosteDayHomePageState extends State<HosteDayHomePage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(user: widget.user);
  }

  Future<void> _run(Future<ActionFeedback?> operation) async {
    final feedback = await operation;

    if (!mounted || feedback == null) {
      return;
    }

    AppSnackbar.show(context, feedback);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading = _controller.isBusy;

        return Scaffold(
          appBar: AppBar(
            title: const Text('HosteDay Dashboard'),
            actions: <Widget>[
              IconButton(
                onPressed: isLoading ? null : () => _run(_controller.logout()),
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  CurrentSessionSection(
                    controller: _controller,
                    onReloadUser: () => _run(_controller.reloadUser()),
                    onVerifyEmail: () =>
                        _run(_controller.sendEmailVerification()),
                  ),
                  const SizedBox(height: 18),
                  ProfileSection(
                    controller: _controller,
                    onUpdate: () => _run(_controller.updateProfile()),
                  ),
                  const SizedBox(height: 18),
                  ProtectedApiSection(
                    controller: _controller,
                    onGetPosts: () => _run(_controller.getPosts()),
                  ),
                  if (_controller.apiResult != null) ...<Widget>[
                    const SizedBox(height: 18),
                    ApiResultSection(controller: _controller),
                  ],
                  const SizedBox(height: 18),
                  RealtimeSection(
                    controller: _controller,
                    onConnect: () => _run(_controller.connectRealtime()),
                    onSubscribe: () => _run(_controller.subscribeRealtime()),
                    onPublish: () => _run(_controller.publishRealtimeEvent()),
                    onUnsubscribe: () =>
                        _run(_controller.unsubscribeRealtime()),
                    onDisconnect: () => _run(_controller.disconnectRealtime()),
                  ),
                  const SizedBox(height: 18),
                  RealtimeLogSection(controller: _controller),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
