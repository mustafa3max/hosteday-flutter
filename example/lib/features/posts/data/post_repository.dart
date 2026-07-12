import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../core/utils/api_response_reader.dart';
import '../models/post.dart';
import 'post_api_paths.dart';

/// Handles HTTP requests for the custom `posts` table.
class PostRepository {
  const PostRepository();

  Future<List<Post>> fetchPosts() async {
    final response = await HosteDay.client.get(
      PostApiPaths.postsPath,
      withAuth: true,
    );

    final posts =
        ApiResponseReader.readList(response).map(Post.fromJson).toList()
          ..sort((a, b) => b.createdAtText.compareTo(a.createdAtText));

    return posts;
  }

  Future<Post?> createPost({
    required String title,
    required String body,
  }) async {
    final response = await HosteDay.client.post(
      PostApiPaths.postsPath,
      withAuth: true,
      body: <String, dynamic>{'title': title, 'body': body},
    );

    final createdPostJson = ApiResponseReader.readObject(response);

    if (createdPostJson == null) {
      return null;
    }

    return Post.fromJson(createdPostJson);
  }
}
