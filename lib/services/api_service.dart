import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class ApiService {
  static const String defaultLanguage = 'bn'; // Bengali as default

  // Get settings box
  Box get _settingsBox => Hive.box('settings');

  // Get current language
  String get currentLanguage =>
      _settingsBox.get('language', defaultValue: defaultLanguage);

  // Set language
  Future<void> setLanguage(String languageCode) async {
    await _settingsBox.put('language', languageCode);
  }

  // Get JSON path for current language
  String _getJsonPath(String languageCode) {
    return 'assets/data/authors_$languageCode.json';
  }

  /// Fetch authors from local JSON file based on selected language
  /// This is completely offline - no internet required!
  Future<List<Author>> fetchAuthors({String? languageCode}) async {
    try {
      final lang = languageCode ?? currentLanguage;
      final jsonPath = _getJsonPath(lang);

      print('Loading authors from: $jsonPath');

      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(jsonPath);

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

  /// Get list of available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'bn', 'name': 'বাংলা'},
      {'code': 'en', 'name': 'English'},
    ];
  }
}
