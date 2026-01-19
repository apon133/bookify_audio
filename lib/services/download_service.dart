import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/models.dart';
import 'hive_download_service.dart';

class DownloadTask {
  final String title;
  final String id;
  double progress;
  String status;
  final bool audioOnly;

  DownloadTask(
    this.title,
    this.id,
    this.progress,
    this.status, {
    this.audioOnly = true,
  });
}

class DownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, DownloadTask> _activeTasks = {};
  final HiveDownloadService _hiveDownloadService = HiveDownloadService();
  bool _isCanceled = false;

  // Singleton pattern
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Map<String, DownloadTask> get activeTasks => _activeTasks;

  // Get the downloads directory based on platform
  Future<Directory> getDownloadsDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Downloads not supported on web platform');
    }

    Directory downloadsDir;
    if (Platform.isAndroid) {
      // Android specific directory
      downloadsDir = Directory('/storage/emulated/0/Download/BookifyAudio');
    } else if (Platform.isIOS) {
      // iOS documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      downloadsDir = Directory('${appDocDir.path}/BookifyAudio');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms
      final appDocDir = await getApplicationDocumentsDirectory();
      downloadsDir = Directory('${appDocDir.path}/BookifyAudio');
    } else {
      throw UnsupportedError('Unsupported platform for downloads');
    }

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    return downloadsDir;
  }

  // Check if an episode is downloaded
  Future<bool> isEpisodeDownloaded(Episode episode) async {
    try {
      // Check Hive metadata first
      if (_hiveDownloadService.isEpisodeDownloaded(episode.id)) {
        final metadata = _hiveDownloadService.getDownloadMetadata(episode.id);
        if (metadata != null) {
          final filePath = metadata['filePath'] as String?;
          if (filePath != null && File(filePath).existsSync()) {
            return true;
          } else {
            // File doesn't exist, remove metadata
            await _hiveDownloadService.deleteDownloadMetadata(episode.id);
          }
        }
      }

      // Fallback: check file system
      final downloadsDir = await getDownloadsDirectory();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(episode.bookName)}_${episode.id}.mp3';
      final exists = File(filePath).existsSync();

      // If file exists but no metadata, add metadata
      if (exists) {
        await _hiveDownloadService.saveDownloadMetadata(
          episodeId: episode.id,
          episodeName: episode.bookName,
          filePath: filePath,
          downloadedAt: DateTime.now(),
        );
      }

      return exists;
    } catch (e) {
      debugPrint('Error checking if episode is downloaded: $e');
      return false;
    }
  }

  // Get the local file path for a downloaded episode
  Future<String?> getLocalFilePath(Episode episode) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(episode.bookName)}_${episode.id}.mp3';
      final file = File(filePath);

      if (file.existsSync()) {
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local file path: $e');
      return null;
    }
  }

  // Download an episode for offline playback
  Future<void> downloadEpisode(Episode episode,
      {Function(DownloadTask)? onProgressUpdate}) async {
    if (_activeTasks.containsKey(episode.id)) {
      // Already downloading
      return;
    }

    final task = DownloadTask(
      episode.bookName,
      episode.id,
      0.0,
      'Initializing',
      audioOnly: true,
    );

    _activeTasks[episode.id] = task;
    _isCanceled = false;

    try {
      await _downloadAudio(episode, task, onProgressUpdate);
    } catch (e) {
      task.status = 'Error: $e';
      if (onProgressUpdate != null) {
        onProgressUpdate(task);
      }
      _activeTasks.remove(episode.id);
    }
  }

  // Cancel a download
  void cancelDownload(String episodeId) {
    _isCanceled = true;
    _activeTasks.remove(episodeId);
  }

  // Delete a downloaded episode
  Future<bool> deleteDownloadedEpisode(Episode episode) async {
    try {
      final localFilePath = await getLocalFilePath(episode);
      if (localFilePath != null) {
        final file = File(localFilePath);
        if (file.existsSync()) {
          await file.delete();
          // Remove from Hive metadata
          await _hiveDownloadService.deleteDownloadMetadata(episode.id);
          return true;
        }
      }
      // Also remove metadata if file doesn't exist
      await _hiveDownloadService.deleteDownloadMetadata(episode.id);
      return false;
    } catch (e) {
      debugPrint('Error deleting downloaded episode: $e');
      return false;
    }
  }

  // Internal method to download audio
  Future<void> _downloadAudio(Episode episode, DownloadTask task,
      Function(DownloadTask)? onProgressUpdate) async {
    final downloadsDir = await getDownloadsDirectory();

    try {
      final videoId = _extractVideoId(episode.audioUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      // final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      if (manifest.audioOnly.isEmpty) {
        throw Exception('No audio streams available for download.');
      }

      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(episode.bookName)}_${episode.id}.mp3';
      final file = File(filePath);
      final stream = _yt.videos.streamsClient.get(streamInfo);

      final totalBytes = streamInfo.size.totalBytes;
      var downloadedBytes = 0;
      final output = file.openWrite();

      task.status = 'Downloading';
      if (onProgressUpdate != null) {
        onProgressUpdate(task);
      }

      await for (final chunk in stream) {
        if (_isCanceled) break;

        downloadedBytes += chunk.length;
        output.add(chunk);

        final progress = downloadedBytes / totalBytes;
        task.progress = progress;
        task.status = 'Downloading ${(progress * 100).toStringAsFixed(1)}%';

        if (onProgressUpdate != null) {
          onProgressUpdate(task);
        }
      }

      await output.flush();
      await output.close();

      if (!_isCanceled) {
        task.status = 'Completed';

        // Save download metadata to Hive
        await _hiveDownloadService.saveDownloadMetadata(
          episodeId: episode.id,
          episodeName: episode.bookName,
          filePath: filePath,
          downloadedAt: DateTime.now(),
        );

        if (onProgressUpdate != null) {
          onProgressUpdate(task);
        }
      }

      _activeTasks.remove(episode.id);
    } catch (e) {
      task.status = 'Error: $e';
      if (onProgressUpdate != null) {
        onProgressUpdate(task);
      }
      _activeTasks.remove(episode.id);
      rethrow;
    }
  }

  // Helper method to extract YouTube video ID
  String? _extractVideoId(String url) {
    try {
      return VideoId.parseVideoId(url);
    } catch (e) {
      return null;
    }
  }

  // Helper method to sanitize file names
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  void dispose() {
    _yt.close();
  }
}
