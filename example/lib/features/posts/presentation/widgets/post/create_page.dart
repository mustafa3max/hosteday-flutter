import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../../core/errors/error_presenter.dart';
import '../../../../../shared/widgets/feedback_boxes.dart';
import '../../../data/post_repository.dart';

/// Page used to create a new post.
///
/// Expected API:
/// `POST /api/posts`
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final PostRepository _repository = const PostRepository();

  final TextEditingController _titleController = TextEditingController(
    text: "Title Test 1",
  );
  final TextEditingController _bodyController = TextEditingController(
    text: "Body Test Post 1",
  );

  bool _creating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _creating) {
      return;
    }

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final title = _titleController.text.trim();
      final postBody = _bodyController.text.trim();
      final userId = HosteDay.auth.currentUser!.id;

      final requestBody = <String, dynamic>{
        'title': title,
        'body': postBody,
        if (userId.isNotEmpty) 'user_id': userId,
      };
      await _repository.createPost(body: requestBody);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = ErrorPresenter.messageFrom(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_creating,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create post')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_errorMessage != null) ...<Widget>[
                    ErrorBox(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _titleController,
                    enabled: !_creating,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 255,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(255),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Post title',
                      hintText: 'Enter the post title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Post title is required.';
                      }

                      if (title.length > 255) {
                        return 'Post title must not exceed 255 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    enabled: !_creating,
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Post body',
                      hintText: 'Enter at least 10 characters',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: (value) {
                      final body = value?.trim() ?? '';

                      if (body.isEmpty) {
                        return 'Post body is required.';
                      }

                      if (body.length < 10) {
                        return 'Post body must contain at least 10 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(HosteDay.auth.currentUser!.id),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _creating ? null : _createPost,
                    icon: _creating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(_creating ? 'Creating...' : 'Create post'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
