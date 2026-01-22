import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class ApiService {
  static const String defaultLanguage = 'bn'; // Bengali as default
  static const String defaultBrowseMode = 'writer'; // writer or genre

  // Get settings box
  Box get _settingsBox => Hive.box('settings');

  // Get current language
  String get currentLanguage =>
      _settingsBox.get('language', defaultValue: defaultLanguage);

  // Get current browse mode
  String get currentBrowseMode =>
      _settingsBox.get('browseMode', defaultValue: defaultBrowseMode);

  // Set language
  Future<void> setLanguage(String languageCode) async {
    await _settingsBox.put('language', languageCode);
  }

  // Set browse mode
  Future<void> setBrowseMode(String mode) async {
    await _settingsBox.put('browseMode', mode);
  }

  // Get JSON path for current language (uses combined library file)
  String _getJsonPath(String languageCode) {
    return 'assets/data/library_$languageCode.json';
  }

  /// Fetch authors from local JSON file based on selected language and browse mode
  /// This is completely offline - no internet required!
  Future<List<Author>> fetchAuthors(
      {String? languageCode, String? browseMode}) async {
    try {
      final lang = languageCode ?? currentLanguage;
      final mode = browseMode ?? currentBrowseMode;
      final jsonPath = _getJsonPath(lang);

      print('=== API SERVICE DEBUG ===');
      print('Loading library from: $jsonPath');
      print('Browse mode: $mode');

      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(jsonPath);

      // Parse the JSON
      final Map<String, dynamic> decodedData =
          jsonDecode(jsonString) as Map<String, dynamic>;

      // Extract the appropriate array based on browse mode
      final List<dynamic> dataArray;
      if (mode == 'genre') {
        dataArray = decodedData['genres'] as List<dynamic>;
        print('Loaded ${dataArray.length} genres');
      } else {
        dataArray = decodedData['authors'] as List<dynamic>;
        print('Loaded ${dataArray.length} authors');
      }
      print('========================');

      // Convert to Author objects
      return dataArray.map((item) {
        if (item is Map) {
          return Author.fromJson(Map<String, dynamic>.from(item));
        } else {
          throw Exception('Invalid author data format: $item');
        }
      }).toList();
    } catch (e) {
      print('❌ Error loading from local JSON: $e');
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

  /// Get list of available browse modes
  List<Map<String, String>> getAvailableBrowseModes() {
    return [
      {'code': 'writer', 'name': 'Writer'},
      {'code': 'genre', 'name': 'Genre'},
    ];
  }
}
