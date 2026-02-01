import 'package:isar/isar.dart';
import '../models/models.dart';
import '../models/isar_models.dart';
import 'playlist_service.dart'; // To access the Isar instance

class HistoryService {
  // Use the Isar instance initialized in PlaylistService (or we can move init mostly to main)
  // For now, let's assume global access or singleton
  Isar get _isar => PlaylistService.isar;

  // --- Mappers ---
  // (Duplicated from PlaylistService, could extract to a shared Mapper or mixin but this is fine for now)

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

  Book fromBookEntity(BookEntity entity) {
    return Book(
      id: entity.originalId,
      title: entity.title,
      cover: entity.cover,
      author: entity.author,
      authorImage: entity.authorImage,
      episodes: entity.episodes.map(fromEpisodeEntity).toList(),
    );
  }

  Episode fromEpisodeEntity(EpisodeEntity entity) {
    return Episode(
      id: entity.id,
      bookName: entity.bookName,
      audioUrl: entity.audioUrl,
      voiceOwner: entity.voiceOwner,
    );
  }

  Author fromAuthorEntity(AuthorEntity entity) {
    return Author(
      id: entity.id,
      name: entity.name,
      image: entity.image,
      books: [],
    );
  }

  HistoryItem fromHistoryItemEntity(HistoryItemEntity entity) {
    return HistoryItem(
      episode: fromEpisodeEntity(entity.episode),
      book: fromBookEntity(entity.book),
      author: fromAuthorEntity(entity.author),
      position: entity.position,
      duration: entity.duration,
      lastPlayed: entity.lastPlayed,
    );
  }

  static Future<void> init() async {
    // No-op if PlaylistService.init() handles Isar opening.
    // If we want HistoryService to be independent, we check if isar is open.
    // But since we want one DB instance, let's rely on main calling a central init or PlaylistService.init
    // For safety, we can ensure schemas are included in the open call in PlaylistService.
  }

  Future<void> savePosition(Episode episode, Book book, Author author,
      double position, double duration) async {
    await _isar.writeTxn(() async {
      final existingItem =
          await _isar.historyItemEntitys.getByEpisodeId(episode.id);

      final item = existingItem ?? HistoryItemEntity();

      item
        ..episodeId = episode.id
        ..episode = _toEpisodeEntity(episode)
        ..book = _toBookEntity(book)
        ..author = _toAuthorEntity(author)
        ..position = position
        ..duration = duration
        ..lastPlayed = DateTime.now();

      await _isar.historyItemEntitys.put(item);
    });
  }

  List<HistoryItem> getHistory({bool uniqueByBook = true}) {
    final items =
        _isar.historyItemEntitys.where().sortByLastPlayedDesc().findAllSync();

    final historyItems = items.map(fromHistoryItemEntity).toList();

    if (!uniqueByBook) return historyItems;

    final Map<String, HistoryItem> uniqueBooks = {};
    for (var item in historyItems) {
      if (!uniqueBooks.containsKey(item.book.id)) {
        uniqueBooks[item.book.id] = item;
      }
    }
    return uniqueBooks.values.toList();
  }

  List<HistoryItem> getContinueWatching() {
    return getHistory(uniqueByBook: true)
        .where((item) => !item.isFinished)
        .toList();
  }

  List<HistoryItem> getFinishedHistory() {
    return getHistory(uniqueByBook: true)
        .where((item) => item.isFinished)
        .toList();
  }

  Future<void> remove(String episodeId) async {
    await _isar.writeTxn(() async {
      await _isar.historyItemEntitys.deleteByEpisodeId(episodeId);
    });
  }

  Future<void> removeBookHistory(String bookId) async {
    await _isar.writeTxn(() async {
      // Find all history items for this book
      // Isar filter by embedded object property is tricky if not indexed,
      // but we can iterate since history isn't huge, or filter in Isar.
      // Filtering embedded objects via query:
      // We can use filter()
      await _isar.historyItemEntitys
          .filter()
          .book((q) => q.originalIdEqualTo(bookId))
          .deleteAll();
    });
  }

  Future<void> clear() async {
    await _isar.writeTxn(() async {
      await _isar.historyItemEntitys.clear();
    });
  }
}
