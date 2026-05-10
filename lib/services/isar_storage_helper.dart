import 'isar_wrapper.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_models.dart';

class IsarStorageHelper {
  static late Isar isar;
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        PlaylistEntitySchema,
        HistoryItemEntitySchema,
        AppSettingsEntitySchema,
        ReactionEntitySchema,
      ],
      directory: dir.path,
    );
  }
}
