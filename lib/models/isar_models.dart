import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class PlaylistEntity {
  Id id = Isar.autoIncrement;

  late String name;

  late DateTime createdAt;

  List<PlaylistItemEntity> items = [];
}

@embedded
class PlaylistItemEntity {
  late BookEntity book;
  late AuthorEntity author;
  late DateTime addedAt;
}

@collection
class HistoryItemEntity {
  Id id = Isar.autoIncrement;

  // We use this string ID for easier lookups if needed,
  // though Isar autoIncrement ID is efficient.
  // Let's index the episodeId since we look up by it.
  @Index(unique: true, replace: true)
  late String episodeId;

  late BookEntity book;
  late AuthorEntity author;
  late EpisodeEntity episode;

  late double position;
  late double duration;
  late DateTime lastPlayed;
}

@collection
class AppSettingsEntity {
  Id id = Isar.autoIncrement;

  // Singleton ID for easy access
  @Index(unique: true)
  String settingsId = 'default';

  String language = 'bn';
  String browseMode = 'writer';
  bool isDarkMode = false; // Add more settings as needed
}

@embedded
class BookEntity {
  late String originalId; // Maps to Book.id
  late String title;
  late String cover;
  List<EpisodeEntity> episodes = [];
  String? author;
  String? authorImage;
}

@embedded
class EpisodeEntity {
  late String id;
  late String bookName;
  late String audioUrl;
  late String voiceOwner;
}

@embedded
class AuthorEntity {
  late String id;
  late String name;
  late String image;
  // We don't store the full list of books for the author in the playlist item
}
