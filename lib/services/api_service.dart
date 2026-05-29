import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import '../models/models.dart';
import '../models/isar_models.dart';

class ApiService {
  static const String defaultLanguage = 'bn';
  static const String defaultBrowseMode = 'writer';

  // Helper to get or create settings
  AppSettingsEntity _getSettings() {
    final box = Hive.box<AppSettingsEntity>('settings');
    var settings = box.get('default');
    if (settings == null) {
      settings = AppSettingsEntity();
      box.put('default', settings);
    }
    return settings;
  }

  String get currentLanguage => _getSettings().language;

  String get currentBrowseMode => _getSettings().browseMode;

  Future<void> setLanguage(String languageCode) async {
    final box = Hive.box<AppSettingsEntity>('settings');
    final settings = box.get('default') ?? AppSettingsEntity();
    settings.language = languageCode;
    await box.put('default', settings);
  }

  Future<void> setBrowseMode(String mode) async {
    final box = Hive.box<AppSettingsEntity>('settings');
    final settings = box.get('default') ?? AppSettingsEntity();
    settings.browseMode = mode;
    await box.put('default', settings);
  }

  String _getJsonPath(String languageCode) {
    return 'assets/data/library_$languageCode.json';
  }

  Future<List<Author>> fetchAuthors(
      {String? languageCode, String? browseMode}) async {
    try {
      final lang = languageCode ?? currentLanguage;
      final mode = browseMode ?? currentBrowseMode;
      final jsonPath = _getJsonPath(lang);

      print('=== API SERVICE DEBUG ===');
      print('Loading library from: $jsonPath');
      print('Browse mode: $mode');

      final String jsonString = await rootBundle.loadString(jsonPath);

      final Map<String, dynamic> decodedData =
          jsonDecode(jsonString) as Map<String, dynamic>;

      final List<dynamic> dataArray;
      if (mode == 'genre') {
        dataArray = decodedData['genres'] as List<dynamic>;
        print('Loaded ${dataArray.length} genres');
      } else {
        dataArray = decodedData['authors'] as List<dynamic>;
        print('Loaded ${dataArray.length} authors');
      }
      print('========================');

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

  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'bn', 'name': 'বাংলা'},
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिंदी'},
    ];
  }

  List<Map<String, String>> getAvailableBrowseModes() {
    return [
      {'code': 'writer', 'name': 'Writer'},
      {'code': 'genre', 'name': 'Genre'},
    ];
  }
}
