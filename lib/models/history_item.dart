import 'book.dart';
import 'author.dart';
import 'episode.dart';

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
