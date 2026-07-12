import '../../../core/utils/api_response_reader.dart';

/// Simple post model used by the example custom table.
class Post {
  final String id;
  final String title;
  final String? body;
  final String createdAtText;
  final Map<String, dynamic> data;

  const Post({
    required this.id,
    required this.title,
    this.body,
    this.createdAtText = '',
    this.data = const <String, dynamic>{},
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final id = ApiResponseReader.firstText(json, const <String>[
      'id',
      'post_id',
      'uuid',
    ]);

    final title = ApiResponseReader.firstText(json, const <String>[
      'title',
      'name',
    ]);

    return Post(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title ?? 'Untitled post',
      body: ApiResponseReader.firstText(json, const <String>[
        'body',
        'content',
        'description',
      ]),
      createdAtText:
          ApiResponseReader.firstText(json, const <String>[
            'created_at',
            'createdAt',
          ]) ??
          '',
      data: Map<String, dynamic>.from(json),
    );
  }
}
