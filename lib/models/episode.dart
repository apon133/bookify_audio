import 'package:hive/hive.dart';

part 'episode.g.dart';

@HiveType(typeId: 2)
class Episode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bookName;

  @HiveField(2)
  final String audioUrl;

  @HiveField(3)
  final String voiceOwner;

  Episode({
    required this.id,
    required this.bookName,
    required this.audioUrl,
    required this.voiceOwner,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    // Handle the _id field which is a nested object with $oid
    String id = '';
    if (json['_id'] is Map) {
      // Use string key for accessing the $oid field
      final idMap = json['_id'] as Map;
      id = idMap.containsKey('\$oid') ? idMap['\$oid']?.toString() ?? '' : '';
    } else {
      id = json['_id']?.toString() ?? '';
    }

    return Episode(
      id: id,
      bookName: json['book_name'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      voiceOwner: json['voice_owner'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_name': bookName,
      'audio_url': audioUrl,
      'voice_owner': voiceOwner,
    };
  }
}
