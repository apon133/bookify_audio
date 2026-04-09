import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../models/isar_models.dart';
import 'storage_service.dart';

class ApiService {
  static const String defaultLanguage = 'bn';
  static const String defaultBrowseMode = 'writer';

  Isar get _isar => StorageService.isar;
  bool get _isHive => kIsWeb;

  // Helper to get or create settings
  AppSettingsEntity _getSettings() {
    if (_isHive) {
      final box = Hive.box<AppSettingsEntity>('settings');
      var settings = box.get('default');
      if (settings == null) {
        settings = AppSettingsEntity();
        box.put('default', settings);
      }
      return settings;
    } else {
      final settings = _isar.appSettingsEntitys.getBySettingsIdSync('default');
      if (settings == null) {
        final newSettings = AppSettingsEntity();
        _isar.writeTxnSync(() {
          _isar.appSettingsEntitys.putSync(newSettings);
        });
        return newSettings;
      }
      return settings;
    }
  }

  String get currentLanguage => _getSettings().language;

  String get currentBrowseMode => _getSettings().browseMode;

  Future<void> setLanguage(String languageCode) async {
    if (_isHive) {
      final box = Hive.box<AppSettingsEntity>('settings');
      final settings = box.get('default') ?? AppSettingsEntity();
      settings.language = languageCode;
      await box.put('default', settings);
    } else {
      await _isar.writeTxn(() async {
        final settings =
            await _isar.appSettingsEntitys.getBySettingsId('default');
        final s = settings ?? AppSettingsEntity();
        s.language = languageCode;
        await _isar.appSettingsEntitys.put(s);
      });
    }
  }

  Future<void> setBrowseMode(String mode) async {
    if (_isHive) {
      final box = Hive.box<AppSettingsEntity>('settings');
      final settings = box.get('default') ?? AppSettingsEntity();
      settings.browseMode = mode;
      await box.put('default', settings);
    } else {
      await _isar.writeTxn(() async {
        final settings =
            await _isar.appSettingsEntitys.getBySettingsId('default');
        final s = settings ?? AppSettingsEntity();
        s.browseMode = mode;
        await _isar.appSettingsEntitys.put(s);
      });
    }
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
    ];
  }

  List<Map<String, String>> getAvailableBrowseModes() {
    return [
      {'code': 'writer', 'name': 'Writer'},
      {'code': 'genre', 'name': 'Genre'},
    ];
  }
}
