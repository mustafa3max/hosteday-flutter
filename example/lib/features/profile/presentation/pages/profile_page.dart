import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = false;
  bool _uploadingAvatar = false;

  String? _message;
  String? _errorMessage;

  HosteDayUser? get _user => HosteDay.auth.currentUser;

  bool get _isBusy => _loading || _uploadingAvatar;

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
    if (_isBusy) {
      return;
    }

    _startLoading();

    try {
      final user = await HosteDay.auth.reload();

      if (!mounted) {
        return;
      }

      _nameController.text = user.displayName ?? '';

      setState(() {
        _message = 'User profile reloaded.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      _stopLoading();
    }
  }

  Future<void> _updateProfile() async {
    if (_isBusy) {
      return;
    }

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _message = null;
        _errorMessage = 'Display name is required.';
      });

      return;
    }

    _startLoading();

    try {
      await HosteDay.auth.updateProfile(name: name);

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Profile updated.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      _stopLoading();
    }
  }

  Future<void> _sendEmailVerification() async {
    if (_isBusy) {
      return;
    }

    _startLoading();

    try {
      await HosteDay.auth.sendEmailVerification();

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Verification email has been sent.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      _stopLoading();
    }
  }

  Future<void> _showAvatarSourceDialog() async {
    if (_isBusy) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    await _pickAndUploadAvatar(source: ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    await _pickAndUploadAvatar(source: ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar({required ImageSource source}) async {
    if (_isBusy) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      _startAvatarUpload();

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        throw StateError('The selected image is empty.');
      }

      final extension = _extractImageExtension(image.name);

      await HosteDay.auth.updateAvatar(bytes: bytes, extension: extension);

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Avatar updated successfully.';
      });
    } catch (error) {
      _showError(error);
    } finally {
      _stopAvatarUpload();
    }
  }

  String _extractImageExtension(String fileName) {
    final normalizedFileName = fileName.trim().toLowerCase();
    final dotIndex = normalizedFileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == normalizedFileName.length - 1) {
      throw const FormatException(
        'The selected image does not have a valid extension.',
      );
    }

    final extension = normalizedFileName.substring(dotIndex + 1);

    const supportedExtensions = <String>{'jpg', 'jpeg', 'png', 'webp'};

    if (!supportedExtensions.contains(extension)) {
      throw FormatException(
        'Unsupported image extension: $extension. '
        'Supported extensions are jpg, jpeg, png, and webp.',
      );
    }

    return extension;
  }

  void _startLoading() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });
  }

  void _stopLoading() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  void _startAvatarUpload() {
    if (!mounted) {
      return;
    }

    setState(() {
      _uploadingAvatar = true;
      _message = null;
      _errorMessage = null;
    });
  }

  void _stopAvatarUpload() {
    if (!mounted) {
      return;
    }

    setState(() {
      _uploadingAvatar = false;
    });
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _message = null;
      _errorMessage = ErrorPresenter.messageFrom(error);
    });
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
            _ProfileAvatar(
              avatarUrl: user.avatarUrl,
              uploading: _uploadingAvatar,
              onPressed: _isBusy ? null : _showAvatarSourceDialog,
            ),
            const SizedBox(height: 20),
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
              enabled: !_isBusy,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Display name'),
              onSubmitted: (_) {
                if (!_isBusy) {
                  _updateProfile();
                }
              },
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
                FilledButton.icon(
                  onPressed: _isBusy ? null : _updateProfile,
                  icon: _loading
                      ? const _ButtonProgressIndicator()
                      : const Icon(Icons.save_outlined),
                  label: const Text('Update profile'),
                ),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _reloadUser,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload user'),
                ),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _sendEmailVerification,
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Send verification email'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.uploading,
    required this.onPressed,
  });

  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = avatarUrl?.trim();

    final hasAvatar =
        normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty;
    return Center(
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 112,
                height: 112,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: uploading
                    ? const Center(child: CircularProgressIndicator())
                    : hasAvatar
                    ? Image.network(
                        normalizedAvatarUrl,
                        key: ValueKey<String>(normalizedAvatarUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 56);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : const Icon(Icons.person, size: 56),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  tooltip: 'Change avatar',
                  onPressed: onPressed,
                  icon: uploading
                      ? const _ButtonProgressIndicator()
                      : const Icon(Icons.photo_camera_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.image_outlined),
            label: Text(uploading ? 'Uploading avatar...' : 'Change avatar'),
          ),
        ],
      ),
    );
  }
}

class _ButtonProgressIndicator extends StatelessWidget {
  const _ButtonProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: IconTheme.of(context).color,
      ),
    );
  }
}
