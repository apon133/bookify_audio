import 'package:isar/isar.dart'
    if (dart.library.js_interop) 'isar_stubs.dart'
    if (dart.library.html) 'isar_stubs.dart';
import 'package:hive_ce/hive.dart';

part 'isar_models.g.dart';

@collection
@HiveType(typeId: 0)
class PlaylistEntity {
  @HiveField(0)
  Id id = Isar.autoIncrement;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  List<PlaylistItemEntity> items = [];
}

@embedded
@HiveType(typeId: 1)
class PlaylistItemEntity {
  @HiveField(0)
  late BookEntity book;

  @HiveField(1)
  late AuthorEntity author;

  @HiveField(2)
  late DateTime addedAt;
}

@collection
@HiveType(typeId: 2)
class HistoryItemEntity {
  @HiveField(0)
  Id id = Isar.autoIncrement;

  @HiveField(1)
  @Index(unique: true, replace: true)
  late String episodeId;

  @HiveField(2)
  late BookEntity book;

  @HiveField(3)
  late AuthorEntity author;

  @HiveField(4)
  late EpisodeEntity episode;

  @HiveField(5)
  late double position;

  @HiveField(6)
  late double duration;

  @HiveField(7)
  late DateTime lastPlayed;
}

@collection
@HiveType(typeId: 3)
class AppSettingsEntity {
  @HiveField(0)
  Id id = Isar.autoIncrement;

  @HiveField(1)
  @Index(unique: true)
  String settingsId = 'default';

  @HiveField(2)
  String language = 'bn';

  @HiveField(3)
  String browseMode = 'writer';

  @HiveField(4)
  bool isDarkMode = false;
}

@embedded
@HiveType(typeId: 4)
class BookEntity {
  @HiveField(0)
  late String originalId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String cover;

  @HiveField(3)
  List<EpisodeEntity> episodes = [];

  @HiveField(4)
  String? author;

  @HiveField(5)
  String? authorImage;
}

@embedded
@HiveType(typeId: 5)
class EpisodeEntity {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String bookName;

  @HiveField(2)
  late String audioUrl;

  @HiveField(3)
  late String voiceOwner;
}

@embedded
@HiveType(typeId: 6)
class AuthorEntity {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String image;
}

@HiveType(typeId: 7)
enum ReactionType {
  @HiveField(0)
  like,
  @HiveField(1)
  dislike
}

@collection
@HiveType(typeId: 8)
class ReactionEntity {
  @HiveField(0)
  Id id = Isar.autoIncrement;

  @HiveField(1)
  @Index(unique: true, replace: true)
  late String episodeId;

  @HiveField(2)
  late BookEntity book;

  @HiveField(3)
  late AuthorEntity author;

  @HiveField(4)
  late EpisodeEntity episode;

  @HiveField(5)
  @enumerated
  late ReactionType type;

  @HiveField(6)
  late DateTime createdAt;
}
