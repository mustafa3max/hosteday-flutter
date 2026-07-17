import '../../../core/utils/api_response_reader.dart';

/// Simple post model used by the example custom table.
class PostModel {
  final int id;
  final String userId;
  final String title;
  final String? body;
  final String createdAtText;
  final Map<String, dynamic> data;

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.createdAtText = '',
    this.data = const <String, dynamic>{},
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final userId = ApiResponseReader.firstText(json, const <String>[
      'user_id',
      'userId',
      'author_id',
      'owner_id',
    ]);

    final title = ApiResponseReader.firstText(json, const <String>[
      'title',
      'name',
    ]);

    final body = ApiResponseReader.firstText(json, const <String>[
      'body',
      'content',
      'description',
    ]);

    final createdAtText =
        ApiResponseReader.firstText(json, const <String>[
          'created_at',
          'createdAt',
        ]) ??
        '';

    return PostModel(
      id: json['id'],
      userId: userId ?? '',
      title: title ?? 'Untitled post',
      body: body,
      createdAtText: createdAtText,
      data: Map<String, dynamic>.from(json),
    );
  }
}
