import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/empty_box.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../data/post_realtime_service.dart';
import '../../data/post_repository.dart';
import '../../models/post.dart';
import '../widgets/create_post_form.dart';
import '../widgets/post_card.dart';

/// Fetches, displays, creates, refreshes, and listens to posts.
///
/// Expected API examples:
/// - `GET  /api/posts`
/// - `POST /api/posts`
///
/// Expected realtime event example:
/// - channel: `posts`
/// - event: `PostCreated`
class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final PostRepository _repository = const PostRepository();
  final PostRealtimeService _realtimeService = const PostRealtimeService();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<Post> _posts = <Post>[];

  StreamSubscription<dynamic>? _postCreatedSubscription;

  bool _loading = true;
  bool _creating = false;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePostsPage();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _postCreatedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePostsPage() async {
    await _loadPosts();
    await _listenToRealtimePosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _repository.fetchPosts();

      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
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

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Post title is required.';
      });
      return;
    }

    setState(() {
      _creating = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final post = await _repository.createPost(title: title, body: body);

      if (post != null) {
        _insertOrReplacePost(post);
      } else {
        await _loadPosts();
      }

      _titleController.clear();
      _bodyController.clear();

      setState(() {
        _message = 'Post created.';
      });
    } catch (error) {
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

  Future<void> _listenToRealtimePosts() async {
    try {
      _postCreatedSubscription ??= await _realtimeService.listenToPostCreated(
        onPostCreated: (post) {
          if (post == null) {
            _loadPosts();
            return;
          }

          if (!mounted) {
            return;
          }

          setState(() {
            _message = 'New post received from realtime.';
          });

          _insertOrReplacePost(post);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Realtime listener failed: ${ErrorPresenter.messageFrom(error)}';
      });
    }
  }

  void _insertOrReplacePost(Post post) {
    setState(() {
      final index = _posts.indexWhere((item) => item.id == post.id);

      if (index == -1) {
        _posts.insert(0, post);
      } else {
        _posts[index] = post;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const ExampleHeader(
            title: 'Posts',
            subtitle: 'Example custom table loaded from /api/posts with '
                'realtime updates.',
          ),
          const SizedBox(height: 16),
          CreatePostForm(
            titleController: _titleController,
            bodyController: _bodyController,
            creating: _creating,
            onCreate: _createPost,
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
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_posts.isEmpty)
            const EmptyBox(message: 'No posts yet.')
          else
            ..._posts.map((post) => PostCard(post: post)),
        ],
      ),
    );
  }
}
