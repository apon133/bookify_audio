import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/isar_models.dart';

class StorageService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

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
  }

  // Generic methods to handle Hive
  static Box<T> getBox<T>(String name) => Hive.box<T>(name);
}
