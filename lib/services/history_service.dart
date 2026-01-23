import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HistoryItem {
  final Episode episode;
  final Book book;
  final Author author;
  final double position;
  final double duration;
  final DateTime lastPlayed;

  HistoryItem({
    required this.episode,
    required this.book,
    required this.author,
    required this.position,
    required this.duration,
    required this.lastPlayed,
  });

  bool get isFinished => duration > 0 && (position / duration) >= 0.95;

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      episode: Episode.fromJson(Map<String, dynamic>.from(json['episode'])),
      book: Book.fromJson(Map<String, dynamic>.from(json['book'])),
      author: Author.fromJson(Map<String, dynamic>.from(json['author'])),
      position: (json['position'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(json['lastPlayed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode': episode.toJson(),
      'book': book.toJson(),
      'author': author.toJson(),
      'position': position,
      'duration': duration,
      'lastPlayed': lastPlayed.millisecondsSinceEpoch,
    };
  }
}

class HistoryService {
  static const String boxName = 'playback_history';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  Future<void> savePosition(Episode episode, Book book, Author author,
      double position, double duration) async {
    final item = HistoryItem(
      episode: episode,
      book: book,
      author: author,
      position: position,
      duration: duration,
      lastPlayed: DateTime.now(),
    );

    await _box.put(episode.id, item.toJson());
  }

  List<HistoryItem> getHistory({bool uniqueByBook = true}) {
    final items = _box.values
        .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Sort by last played (newest first)
    items.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));

    if (!uniqueByBook) return items;

    final Map<String, HistoryItem> uniqueBooks = {};
    for (var item in items) {
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
    await _box.delete(episodeId);
  }

  Future<void> removeBookHistory(String bookId) async {
    final Map<dynamic, dynamic> history = _box.toMap();
    final List<dynamic> keysToRemove = [];

    history.forEach((key, value) {
      try {
        final item = HistoryItem.fromJson(Map<String, dynamic>.from(value));
        if (item.book.id == bookId) {
          keysToRemove.add(key);
        }
      } catch (e) {
        // Handle potential parsing errors for old/corrupt data
        print('Error parsing history item for removal: $e');
      }
    });

    for (var key in keysToRemove) {
      await _box.delete(key);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
