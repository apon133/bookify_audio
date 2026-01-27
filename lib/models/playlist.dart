import 'book.dart';
import 'author.dart';

class PlaylistItem {
  final Book book;
  final Author author;
  final DateTime addedAt;

  PlaylistItem({
    required this.book,
    required this.author,
    required this.addedAt,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      book: Book.fromJson(Map<String, dynamic>.from(json['book'])),
      author: Author.fromJson(Map<String, dynamic>.from(json['author'])),
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book.toJson(),
      'author': author.toJson(),
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}

class Playlist {
  final String id;
  final String name;
  final List<PlaylistItem> items;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) =>
                  PlaylistItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
