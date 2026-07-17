import 'package:flutter/material.dart';
import 'package:hosteday_flutter_example/features/posts/models/post_model.dart';
import 'package:hosteday_flutter_example/shared/widgets/app_bar.dart';

import '../../../../../core/errors/error_presenter.dart';
import '../../../../../shared/widgets/empty_box.dart';
import '../../../../../shared/widgets/example_header.dart';
import '../../../../../shared/widgets/feedback_boxes.dart';
import '../../../data/post_repository.dart';
import '../post_card.dart';

/// Fetches and displays a single post.
///
/// Expected API example:
/// `GET /api/posts/{id}`
class ShowPage extends StatefulWidget {
  /// The ID of the post to display.
  final Object postId;

  const ShowPage({required this.postId, super.key});

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  final PostRepository _repository = const PostRepository();

  PostModel? _post;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void didUpdateWidget(covariant ShowPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.postId != widget.postId) {
      _post = null;
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final post = await _repository.fetchPost(widget.postId);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = post;
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
    return Scaffold(
      appBar: AppBarMy(title: 'Post'),
      body: RefreshIndicator(
        onRefresh: _loadPost,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ExampleHeader(
              title: 'Post #${widget.postId}',
              subtitle: 'Single post loaded from /api/posts/${widget.postId}.',
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...<Widget>[
              ErrorBox(message: _errorMessage!),
              const SizedBox(height: 12),
            ],

            if (_loading && _post == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_post == null)
              Column(
                children: <Widget>[
                  const EmptyBox(message: 'Post not found.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _loadPost,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              )
            else ...<Widget>[
              PostCard(post: _post!),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: 'Reload',
                  onPressed: _loading ? null : _loadPost,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
