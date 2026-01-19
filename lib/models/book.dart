import 'episode.dart';

class Book {
  final String id;
  final String title;
  final String cover;
  final List<Episode> episodes;

  Book({
    required this.id,
    required this.title,
    required this.cover,
    required this.episodes,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Handle the _id field which is a nested object with $oid
    String id = '';
    if (json['_id'] is Map) {
      // Use string key for accessing the $oid field
      final idMap = json['_id'] as Map;
      id = idMap.containsKey('\$oid') ? idMap['\$oid']?.toString() ?? '' : '';
    } else {
      id = json['_id']?.toString() ?? '';
    }

    return Book(
      id: id,
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((episodeJson) => Episode.fromJson(episodeJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}
