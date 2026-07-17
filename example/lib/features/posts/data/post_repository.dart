import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../core/utils/api_response_reader.dart';
import '../models/post_model.dart';
import 'post_api_paths.dart';

/// Handles HTTP requests for the custom `posts` table.
class PostRepository {
  const PostRepository();

  Future<List<PostModel>> fetchPosts() async {
    final response = await HosteDay.client.get(PostApiPaths.postsPath);

    final posts =
        ApiResponseReader.readList(response).map(PostModel.fromJson).toList()
          ..sort((a, b) => b.createdAtText.compareTo(a.createdAtText));

    return posts;
  }

  Future<PostModel> fetchPost(Object id) async {
    final response = await HosteDay.client.get(PostApiPaths.postsPath, id: id);

    final json = ApiResponseReader.readObject(response);

    if (json == null) {
      throw const FormatException('Post data was not found in the response.');
    }

    return PostModel.fromJson(json);
  }

  Future createPost({required Map<String, dynamic> body}) async {
    final response = await HosteDay.client.post(
      PostApiPaths.postsPath,
      body: body,
      withAuth: true,
    );
    final json = ApiResponseReader.readObject(response);

    if (json == null) {
      return null;
    }

    return PostModel.fromJson(json);
  }

  Future<PostModel?> updatePost({
    required int id,
    required String relationField,
    required Object relationValue,
    required Map<String, dynamic> body,
  }) async {
    final response = await HosteDay.client.put(
      PostApiPaths.postsPath,
      id: id,
      relationField: relationField,
      relationValue: relationValue,
      body: body,
    );

    final json = ApiResponseReader.readObject(response);

    return json == null ? null : PostModel.fromJson(json);
  }
}
