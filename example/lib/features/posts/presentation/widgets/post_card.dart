import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../models/post_model.dart';
import 'post/update_page.dart';

/// Displays one post item.
class PostCard extends StatelessWidget {
  final PostModel post;

  /// Called after the post has been updated successfully.
  final VoidCallback? onUpdated;

  const PostCard({required this.post, this.onUpdated, super.key});

  Future<void> _openUpdatePage(BuildContext context) async {
    final userId = post.userId;

    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The post does not have a valid user ID.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UpdatePage(
          id: post.id,
          relationField: 'user_id',
          relationValue: userId,
          initialTitle: post.title,
          initialBody: post.body ?? '',
          initialUserId: userId,
        ),
      ),
    );

    if (updated == true) {
      onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(post.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (post.body != null && post.body!.isNotEmpty) Text(post.body!),
            if (post.createdAtText.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                post.createdAtText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing:
            HosteDay.auth.currentUser != null &&
                HosteDay.auth.currentUser!.hasEmail
            ? IconButton(
                tooltip: 'Edit post',
                onPressed: () => _openUpdatePage(context),
                icon: const Icon(Icons.edit_outlined),
              )
            : SizedBox(),
        leading: post.status == 1
            ? Icon(Icons.check_circle_outline)
            : Icon(Icons.cancel_outlined, color: Colors.red),
      ),
    );
  }
}
