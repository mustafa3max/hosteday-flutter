import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/info_tile.dart';

/// Displays and updates the authenticated user's profile.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();

  bool _loading = false;
  String? _message;
  String? _errorMessage;

  HosteDayUser? get _user => HosteDay.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reloadUser() async {
    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.auth.reload();

      final user = HosteDay.auth.currentUser;
      if (mounted && user != null) {
        _nameController.text = user.displayName ?? '';
      }

      setState(() {
        _message = 'User profile reloaded.';
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

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.auth.updateProfile(<String, dynamic>{
        'name': _nameController.text.trim(),
      });

      setState(() {
        _message = 'Profile updated.';
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

  Future<void> _sendEmailVerification() async {
    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.auth.sendEmailVerification();

      setState(() {
        _message = 'Verification email has been sent.';
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
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.userChanges(),
      initialData: HosteDay.auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const Center(child: Text('No authenticated user.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ExampleHeader(
              title: user.displayName ?? 'Current user',
              subtitle: user.email ?? 'No email',
            ),
            const SizedBox(height: 16),
            InfoTile(label: 'User ID', value: user.id),
            InfoTile(
              label: 'Email verified',
              value: user.emailVerified ? 'Yes' : 'No',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
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
                  onPressed: _loading ? null : _updateProfile,
                  child: const Text('Update profile'),
                ),
                OutlinedButton(
                  onPressed: _loading ? null : _reloadUser,
                  child: const Text('Reload user'),
                ),
                OutlinedButton(
                  onPressed: _loading ? null : _sendEmailVerification,
                  child: const Text('Send verification email'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
