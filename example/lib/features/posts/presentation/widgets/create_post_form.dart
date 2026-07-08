import 'package:flutter/material.dart';

/// Form used to create a post.
class CreatePostForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final bool creating;
  final VoidCallback onCreate;

  const CreatePostForm({
    required this.titleController,
    required this.bodyController,
    required this.creating,
    required this.onCreate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Post title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bodyController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Post body'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: creating ? null : onCreate,
          icon: const Icon(Icons.add),
          label: Text(creating ? 'Creating...' : 'Create post'),
        ),
      ],
    );
  }
}
