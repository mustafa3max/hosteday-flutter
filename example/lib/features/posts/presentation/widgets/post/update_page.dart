import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/errors/error_presenter.dart';
import '../../../../../shared/widgets/feedback_boxes.dart';
import '../../../data/post_repository.dart';

/// Page used to update an existing post.
///
/// Expected API:
/// `PUT /api/posts/{id}?relation_field=...&relation_value=...`
class UpdatePage extends StatefulWidget {
  final int id;
  final String relationField;
  final Object relationValue;

  final String initialTitle;
  final String initialBody;
  final String? initialUserId;

  const UpdatePage({
    required this.id,
    required this.relationField,
    required this.relationValue,
    required this.initialTitle,
    required this.initialBody,
    this.initialUserId,
    super.key,
  });

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PostRepository _repository = const PostRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _userIdController;

  late final String _initialTitle;
  late final String _initialBody;
  late final String _initialUserId;

  bool _updating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _initialTitle = widget.initialTitle.trim();
    _initialBody = widget.initialBody.trim();
    _initialUserId = widget.initialUserId?.trim() ?? '';

    _titleController = TextEditingController(text: _initialTitle);

    _bodyController = TextEditingController(text: _initialBody);

    _userIdController = TextEditingController(text: _initialUserId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    FocusScope.of(context).unfocus();

    final parameterError = _validateRequestParameters();

    if (parameterError != null) {
      setState(() {
        _errorMessage = parameterError;
      });
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _updating) {
      return;
    }

    final title = _titleController.text.trim();
    final postBody = _bodyController.text.trim();
    final userId = _userIdController.text.trim();

    final requestBody = <String, dynamic>{
      if (title.isNotEmpty && title != _initialTitle) 'title': title,
      if (postBody.isNotEmpty && postBody != _initialBody) 'body': postBody,
      if (userId.isNotEmpty && userId != _initialUserId) 'user_id': userId,
    };

    if (requestBody.isEmpty) {
      setState(() {
        _errorMessage = 'No changes were made.';
      });
      return;
    }

    setState(() {
      _updating = true;
      _errorMessage = null;
    });

    try {
      await _repository.updatePost(
        id: widget.id,
        relationField: widget.relationField.trim(),
        relationValue: widget.relationValue,
        body: requestBody,
      );

      if (!mounted) {
        return;
      }

      // Returns true so the previous page can reload the post.
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
          _updating = false;
        });
      }
    }
  }

  String? _validateRequestParameters() {
    final relationField = widget.relationField.trim();

    if (relationField.isEmpty) {
      return 'Relation field is required.';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(relationField)) {
      return 'Relation field may contain only letters, numbers, and underscores.';
    }

    if (_isEmptyRelationValue(widget.relationValue)) {
      return 'Relation value is required.';
    }

    return null;
  }

  bool _isEmptyRelationValue(Object value) {
    if (value is String) {
      return value.trim().isEmpty;
    }

    if (value is Iterable) {
      return value.isEmpty;
    }

    if (value is Map) {
      return value.isEmpty;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_updating,
      child: Scaffold(
        appBar: AppBar(title: const Text('Update post')),
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
                    enabled: !_updating,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 255,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(255),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Post title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return null;
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
                    enabled: !_updating,
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
                        return null;
                      }

                      if (body.length < 10) {
                        return 'Post body must contain at least 10 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _userIdController,
                    enabled: !_updating,
                    textInputAction: TextInputAction.done,
                    maxLength: 255,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(255),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'User ID (optional)',
                      hintText: 'Leave unchanged to keep the current user',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onFieldSubmitted: (_) => _updatePost(),
                    validator: (value) {
                      final userId = value?.trim() ?? '';

                      if (userId.length > 255) {
                        return 'User ID must not exceed 255 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _updating ? null : _updatePost,
                    icon: _updating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit),
                    label: Text(_updating ? 'Updating...' : 'Update post'),
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
