import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_models.dart';

class StorageService {
  static late Isar isar;
  static bool _initialized = false;
  static final bool _isHive = kIsWeb;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (_isHive) {
      await Hive.initFlutter();

      // Register Hive Adapters
      Hive.registerAdapter(PlaylistEntityAdapter());
      Hive.registerAdapter(PlaylistItemEntityAdapter());
      Hive.registerAdapter(HistoryItemEntityAdapter());
      Hive.registerAdapter(AppSettingsEntityAdapter());
      Hive.registerAdapter(BookEntityAdapter());
      Hive.registerAdapter(EpisodeEntityAdapter());
      Hive.registerAdapter(AuthorEntityAdapter());
      Hive.registerAdapter(ReactionTypeAdapter());
      Hive.registerAdapter(ReactionEntityAdapter());

      // Open Hive Boxes
      await Hive.openBox<PlaylistEntity>('playlists');
      await Hive.openBox<HistoryItemEntity>('history');
      await Hive.openBox<AppSettingsEntity>('settings');
      await Hive.openBox<ReactionEntity>('reactions');
    } else {
      String? directory;
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;

      isar = await Isar.open(
        [
          PlaylistEntitySchema,
          HistoryItemEntitySchema,
          AppSettingsEntitySchema,
          ReactionEntitySchema,
        ],
        directory: directory,
      );
    }
  }

  static bool get isHive => _isHive;

  // Generic methods to handle both Isar and Hive
  
  static Box<T> getBox<T>(String name) => Hive.box<T>(name);
}
