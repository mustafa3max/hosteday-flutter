import 'dart:async';

import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../models/post_model.dart';
import 'post_api_paths.dart';

/// Listens to realtime post events.
class PostRealtimeService {
  const PostRealtimeService();

  Future<StreamSubscription<dynamic>> listenToPostCreated({
    required void Function(PostModel? post) onPostCreated,
  }) async {
    await HosteDay.connectRealtime();

    return HosteDay.realtime.listenPublic(
      channel: PostApiPaths.postsChannel,
      event: PostApiPaths.postCreatedEvent,
      onEvent: (event) {
        final postJson = _extractPostFromRealtimePayload(event.payload);

        if (postJson == null) {
          onPostCreated(null);
          return;
        }

        onPostCreated(PostModel.fromJson(postJson));
      },
    );
  }

  Map<String, dynamic>? _extractPostFromRealtimePayload(
    Map<String, dynamic> payload,
  ) {
    final post = payload['post'];

    if (post is Map) {
      return Map<String, dynamic>.from(post);
    }

    final data = payload['data'];

    if (data is Map) {
      final nestedPost = data['post'];

      if (nestedPost is Map) {
        return Map<String, dynamic>.from(nestedPost);
      }

      return Map<String, dynamic>.from(data);
    }

    if (payload.containsKey('id') || payload.containsKey('title')) {
      return payload;
    }

    return null;
  }
}
