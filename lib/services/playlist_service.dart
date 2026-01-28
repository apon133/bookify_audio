import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../models/isar_models.dart';

class PlaylistService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        PlaylistEntitySchema,
        HistoryItemEntitySchema,
        AppSettingsEntitySchema,
        ReactionEntitySchema,
      ],
      directory: dir.path,
    );
  }

  // --- Mappers ---

  BookEntity _toBookEntity(Book book) {
    return BookEntity()
      ..originalId = book.id
      ..title = book.title
      ..cover = book.cover
      ..author = book.author
      ..authorImage = book.authorImage
      ..episodes = book.episodes.map(_toEpisodeEntity).toList();
  }

  EpisodeEntity _toEpisodeEntity(Episode episode) {
    return EpisodeEntity()
      ..id = episode.id
      ..bookName = episode.bookName
      ..audioUrl = episode.audioUrl
      ..voiceOwner = episode.voiceOwner;
  }

  AuthorEntity _toAuthorEntity(Author author) {
    return AuthorEntity()
      ..id = author.id
      ..name = author.name
      ..image = author.image;
  }

  Book _fromBookEntity(BookEntity entity) {
    return Book(
      id: entity.originalId,
      title: entity.title,
      cover: entity.cover,
      author: entity.author,
      authorImage: entity.authorImage,
      episodes: entity.episodes.map(_fromEpisodeEntity).toList(),
    );
  }

  Episode _fromEpisodeEntity(EpisodeEntity entity) {
    return Episode(
      id: entity.id,
      bookName: entity.bookName,
      audioUrl: entity.audioUrl,
      voiceOwner: entity.voiceOwner,
    );
  }

  Author _fromAuthorEntity(AuthorEntity entity) {
    return Author(
      id: entity.id,
      name: entity.name,
      image: entity.image,
      books: [], // We don't store unrelated books in the playlist item
    );
  }

  PlaylistItem _fromPlaylistItemEntity(PlaylistItemEntity entity) {
    return PlaylistItem(
      book: _fromBookEntity(entity.book),
      author: _fromAuthorEntity(entity.author),
      addedAt: entity.addedAt,
    );
  }

  Playlist _fromPlaylistEntity(PlaylistEntity entity) {
    return Playlist(
      id: entity.id.toString(),
      name: entity.name,
      items: entity.items.map(_fromPlaylistItemEntity).toList(),
      createdAt: entity.createdAt,
    );
  }

  // --- CRUD Operations ---

  List<Playlist> getPlaylists() {
    final entities =
        isar.playlistEntitys.where().sortByCreatedAtDesc().findAllSync();
    return entities.map(_fromPlaylistEntity).toList();
  }

  Future<void> createPlaylist(String name) async {
    final playlist = PlaylistEntity()
      ..name = name
      ..createdAt = DateTime.now()
      ..items = [];

    await isar.writeTxn(() async {
      await isar.playlistEntitys.put(playlist);
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final id = int.tryParse(playlistId);
    if (id != null) {
      await isar.writeTxn(() async {
        await isar.playlistEntitys.delete(id);
      });
    }
  }

  Future<void> addToPlaylist(
      String playlistId, Book book, Author author) async {
    final id = int.tryParse(playlistId);
    if (id == null) return;

    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(id);
      if (playlist != null) {
        // Check for duplicates
        if (playlist.items.any((item) => item.book.originalId == book.id)) {
          return;
        }

        final newItem = PlaylistItemEntity()
          ..book = _toBookEntity(book)
          ..author = _toAuthorEntity(author)
          ..addedAt = DateTime.now();

        // Isar lists are not observable in the same way, we verify we can modify the list
        // We must re-assign or modify the list
        final newItems = [...playlist.items, newItem];
        playlist.items = newItems; // embedded list update

        await isar.playlistEntitys.put(playlist);
      }
    });
  }

  Future<void> removeFromPlaylist(String playlistId, String bookId) async {
    final id = int.tryParse(playlistId);
    if (id == null) return;

    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(id);
      if (playlist != null) {
        // Filter out the item
        final originalLength = playlist.items.length;
        playlist.items = playlist.items
            .where((item) => item.book.originalId != bookId)
            .toList();

        if (playlist.items.length != originalLength) {
          await isar.playlistEntitys.put(playlist);
        }
      }
    });
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final id = int.tryParse(playlistId);
    if (id == null) return;

    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(id);
      if (playlist != null) {
        playlist.name = newName;
        await isar.playlistEntitys.put(playlist);
      }
    });
  }
}
