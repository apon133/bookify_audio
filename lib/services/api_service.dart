import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

class ApiService {
  static const String localJsonPath = 'assets/data/authors.json';

  /// Fetch authors from local JSON file
  /// This is completely offline - no internet required!
  Future<List<Author>> fetchAuthors({bool forceRefresh = false}) async {
    try {
      print('Loading authors from local JSON file...');

      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(localJsonPath);

      // Parse the JSON
      final List<dynamic> decodedData = jsonDecode(jsonString) as List<dynamic>;

      // Convert to Author objects
      return decodedData.map((item) {
        if (item is Map) {
          return Author.fromJson(Map<String, dynamic>.from(item));
        } else {
          throw Exception('Invalid author data format: $item');
        }
      }).toList();
    } catch (e) {
      print('Error loading from local JSON: $e');
      rethrow;
    }
  }
}
