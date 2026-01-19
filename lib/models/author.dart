import 'package:hive/hive.dart';
import 'book.dart';

part 'author.g.dart';

@HiveType(typeId: 0)
class Author {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  @HiveField(3)
  final List<Book> books;

  Author({
    required this.id,
    required this.name,
    required this.image,
    required this.books,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    // Handle the _id field which is a nested object with $oid
    String id = '';
    if (json['_id'] is Map) {
      // Use string key for accessing the $oid field
      final idMap = json['_id'] as Map;
      id = idMap.containsKey('\$oid') ? idMap['\$oid']?.toString() ?? '' : '';
    } else {
      id = json['_id']?.toString() ?? '';
    }

    return Author(
      id: id,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      books: (json['books'] as List<dynamic>?)
              ?.map((bookJson) => Book.fromJson(bookJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'books': books.map((b) => b.toJson()).toList(),
    };
  }
}
