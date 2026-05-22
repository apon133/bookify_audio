import 'package:hive_ce/hive.dart';
import '../models/models.dart';
import '../models/isar_models.dart';

class HistoryService {
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

  HistoryItem? fromHistoryItemEntity(HistoryItemEntity entity) {
    try {
      // Safely access potentially uninitialized late fields
      return HistoryItem(
        episode: fromEpisodeEntity(entity.episode),
        book: fromBookEntity(entity.book),
        author: fromAuthorEntity(entity.author),
        position: entity.position,
        duration: entity.duration,
        lastPlayed: entity.lastPlayed,
      );
    } catch (e) {
      print('HistoryService: Skipping corrupt history item: $e');
      return null;
    }
  }

  static Future<void> init() async {}

  Future<void> savePosition(Episode episode, Book book, Author author,
      double position, double duration) async {
    final box = Hive.box<HistoryItemEntity>('history');
    // Use episodeId as the key in Hive to mimic Isar unique index
    final existingItem = box.get(episode.id);

    final item = existingItem ?? HistoryItemEntity();
    item
      ..episodeId = episode.id
      ..episode = _toEpisodeEntity(episode)
      ..book = _toBookEntity(book)
      ..author = _toAuthorEntity(author)
      ..position = position
      ..duration = duration
      ..lastPlayed = DateTime.now();

    await box.put(episode.id, item);
  }

  List<HistoryItem> getHistory({bool uniqueByBook = true}) {
    final box = Hive.box<HistoryItemEntity>('history');
    final items = box.values.toList()
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));

    final historyItems = items
        .map(fromHistoryItemEntity)
        .where((item) => item != null)
        .cast<HistoryItem>()
        .toList();

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
    final box = Hive.box<HistoryItemEntity>('history');
    await box.delete(episodeId);
  }

  Future<void> removeBookHistory(String bookId) async {
    final box = Hive.box<HistoryItemEntity>('history');
    final keysToRemove = box.keys.where((key) {
      final item = box.get(key);
      return item != null && item.book.originalId == bookId;
    }).toList();
    await box.deleteAll(keysToRemove);
  }

  Future<void> clear() async {
    final box = Hive.box<HistoryItemEntity>('history');
    await box.clear();
  }
}
