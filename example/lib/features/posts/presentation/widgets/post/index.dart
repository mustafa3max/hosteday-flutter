import 'package:flutter/material.dart';
import 'package:hosteday_flutter_example/features/posts/presentation/widgets/post/show_page.dart';

import '../../../../../core/errors/error_presenter.dart';
import '../../../../../shared/widgets/empty_box.dart';
import '../../../../../shared/widgets/example_header.dart';
import '../../../../../shared/widgets/feedback_boxes.dart';
import '../../../data/post_repository.dart';
import '../../../models/post_model.dart';
import '../post_card.dart';

/// Fetches, displays, and refreshes posts.
///
/// Expected API:
/// `GET /api/posts`
class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final PostRepository _repository = const PostRepository();
  final List<PostModel> _posts = <PostModel>[];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _repository.fetchPosts();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const ExampleHeader(
            title: 'Posts',
            subtitle: 'Posts loaded from /api/posts.',
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...<Widget>[
            ErrorBox(message: _errorMessage!),
            const SizedBox(height: 12),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Posts: ${_posts.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Reload',
                onPressed: _loading ? null : _loadPosts,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading && _posts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_posts.isEmpty)
            const EmptyBox(message: 'No posts found.')
          else
            ..._posts.map(
              (post) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => ShowPage(postId: post.id),
                    ),
                  );

                  if (changed == true && mounted) {
                    await _loadPosts();
                  }
                },
                child: PostCard(post: post),
              ),
            ),
        ],
      ),
    );
  }
}
