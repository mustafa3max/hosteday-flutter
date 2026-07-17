import 'package:flutter/material.dart';

/// Button used to delete an existing post.
///
/// The [postId] is appended to the request path.
///
/// [relationField] and [relationValue] are sent as query parameters.
class Delete extends StatelessWidget {
  /// The post ID appended to the request path.
  final int postId;

  /// The relation field sent as `relation_field`.
  final String relationField;

  /// The relation value sent as `relation_value`.
  final Object relationValue;

  /// Optional post title displayed in the confirmation dialog.
  final String? postTitle;

  /// Whether the delete request is currently running.
  final bool deleting;

  /// Called after the user confirms deletion.
  final VoidCallback onDelete;

  const Delete({
    required this.postId,
    required this.relationField,
    required this.relationValue,
    required this.deleting,
    required this.onDelete,
    this.postTitle,
    super.key,
  });

  String? _validateParameters() {
    final cleanRelationField = relationField.trim();

    if (cleanRelationField.isEmpty) {
      return 'Relation field is required.';
    }

    final validRelationField = RegExp(
      r'^[a-zA-Z0-9_]+$',
    ).hasMatch(cleanRelationField);

    if (!validRelationField) {
      return 'Relation field may contain only letters, numbers, and underscores.';
    }

    if (_isEmptyRelationValue(relationValue)) {
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

  Future<void> _confirmDelete(BuildContext context) async {
    final validationError = _validateParameters();

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanTitle = postTitle?.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Delete post?'),
          content: Text(
            cleanTitle != null && cleanTitle.isNotEmpty
                ? 'Are you sure you want to delete "$cleanTitle"? '
                      'This action cannot be undone.'
                : 'Are you sure you want to delete this post? '
                      'This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      onPressed: deleting ? null : () => _confirmDelete(context),
      icon: deleting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline),
      label: Text(deleting ? 'Deleting...' : 'Delete post'),
    );
  }
}
