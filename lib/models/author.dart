import 'book.dart';

class Author {
  final String id;
  final String name;
  final String image;
  final String? age;
  final String? born;
  final int? bornYear;
  final String? death;
  final int? deathYear;
  final String? bornLocation;
  final String? education;
  final String? occupation;
  final String? otherInfo;
  final List<Book> books;

  Author({
    required this.id,
    required this.name,
    required this.image,
    this.age,
    this.born,
    this.bornYear,
    this.death,
    this.deathYear,
    this.bornLocation,
    this.education,
    this.occupation,
    this.otherInfo,
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
      age: json['age'],
      born: json['born'],
      bornYear: json['bornYear'],
      death: json['death'],
      deathYear: json['deathYear'],
      bornLocation: json['bornLocation'],
      education: json['education'],
      occupation: json['occupation'],
      otherInfo: json['otherInfo'],
      books: (json['books'] as List<dynamic>?)
              ?.map((bookJson) =>
                  Book.fromJson(Map<String, dynamic>.from(bookJson as Map)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'age': age,
      'born': born,
      'bornYear': bornYear,
      'death': death,
      'deathYear': deathYear,
      'bornLocation': bornLocation,
      'education': education,
      'occupation': occupation,
      'otherInfo': otherInfo,
      'books': books.map((b) => b.toJson()).toList(),
    };
  }

  String get calculatedAge {
    if (bornYear == null) return age ?? 'অজানা';
    
    final int currentYear = DateTime.now().year;
    final int endYear = deathYear ?? currentYear;
    final int calculatedAgeNum = endYear - bornYear!;
    
    // Convert to Bengali digits
    final String ageStr = calculatedAgeNum.toString().replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২').replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫').replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮').replaceAll('9', '৯');
    
    if (deathYear == null) {
      return '$ageStr (মরেন নাই)';
    } else {
      return ageStr;
    }
  }
}
