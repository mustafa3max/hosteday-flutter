import 'package:flutter/material.dart';

import '../../models/post.dart';

/// Displays one post item.
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({required this.post, super.key});

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
      ),
    );
  }
}
