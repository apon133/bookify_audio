import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage download metadata using Hive
class HiveDownloadService {
  static const String downloadsBoxName = 'downloads';

  // Get the Hive box for downloads
  Box<Map<dynamic, dynamic>> get _downloadsBox =>
      Hive.box<Map<dynamic, dynamic>>(downloadsBoxName);

  // Save download metadata
  Future<void> saveDownloadMetadata({
    required String episodeId,
    required String episodeName,
    required String filePath,
    required DateTime downloadedAt,
  }) async {
    await _downloadsBox.put(episodeId, {
      'episodeId': episodeId,
      'episodeName': episodeName,
      'filePath': filePath,
      'downloadedAt': downloadedAt.toIso8601String(),
    });
  }

  // Get download metadata
  Map<String, dynamic>? getDownloadMetadata(String episodeId) {
    final data = _downloadsBox.get(episodeId);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  // Check if episode is downloaded
  bool isEpisodeDownloaded(String episodeId) {
    return _downloadsBox.containsKey(episodeId);
  }

  // Delete download metadata
  Future<void> deleteDownloadMetadata(String episodeId) async {
    await _downloadsBox.delete(episodeId);
  }

  // Get all downloaded episodes
  List<Map<String, dynamic>> getAllDownloads() {
    return _downloadsBox.values
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  // Clear all download metadata
  Future<void> clearAllDownloads() async {
    await _downloadsBox.clear();
  }
}
