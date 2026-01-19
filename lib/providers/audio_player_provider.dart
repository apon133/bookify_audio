import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';

class AudioPlayerNotifier extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final DownloadService _downloadService = DownloadService();

  // Getters to expose the service state
  AudioPlayerState get state => _audioPlayerService.state;
  bool get isPlaying => _audioPlayerService.isPlaying;
  bool get isLoading => _audioPlayerService.isLoading;
  Duration get position => _audioPlayerService.position;
  Duration get duration => _audioPlayerService.duration;
  Episode? get currentEpisode => _audioPlayerService.currentEpisode;
  Book? get currentBook => _audioPlayerService.currentBook;
  Author? get currentAuthor => _audioPlayerService.currentAuthor;
  double get playbackSpeed => _audioPlayerService.state.playbackSpeed;
  bool get isDownloaded => _audioPlayerService.state.isDownloaded;
  bool get isDownloading => _audioPlayerService.state.isDownloading;
  double get downloadProgress => _audioPlayerService.state.downloadProgress;

  // Mini player visibility
  bool _isMiniPlayerVisible = false;
  bool get isMiniPlayerVisible =>
      _isMiniPlayerVisible && currentEpisode != null;

  AudioPlayerNotifier() {
    _audioPlayerService.stateStream.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    // Show mini player when an episode is loaded
    if (currentEpisode != null && !_isMiniPlayerVisible) {
      _isMiniPlayerVisible = true;
    }

    notifyListeners();
  }

  // Player control methods
  Future<void> playEpisode(Episode episode, Book book, Author author) async {
    await _audioPlayerService.playEpisode(episode, book, author);
    _isMiniPlayerVisible = true;
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlayerService.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayerService.pause();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayerService.setPlaybackSpeed(speed);
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayerService.stop();
    notifyListeners();
  }

  void hideMiniPlayer() {
    // Ensure we set this to false regardless of other conditions
    _isMiniPlayerVisible = false;

    // Force a rebuild of the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void showMiniPlayer() {
    if (currentEpisode != null) {
      _isMiniPlayerVisible = true;
      notifyListeners();
    }
  }

  // Download functionality
  Future<bool> isEpisodeDownloaded(Episode episode) async {
    return await _downloadService.isEpisodeDownloaded(episode);
  }

  Future<void> downloadEpisode(Episode episode) async {
    // Check if this episode is already downloaded
    if (await isEpisodeDownloaded(episode)) {
      // Update the UI to reflect that this episode is downloaded
      final localFilePath = await _downloadService.getLocalFilePath(episode);
      _audioPlayerService.updateDownloadStatus(
        false,
        1.0,
        isDownloaded: true,
        localFilePath: localFilePath,
      );
      notifyListeners();
      return;
    }

    // Start the download process
    _audioPlayerService.updateDownloadStatus(true, 0.0, isDownloaded: false);
    notifyListeners();

    await _downloadService.downloadEpisode(
      episode,
      onProgressUpdate: (task) {
        _audioPlayerService.updateDownloadStatus(
          true,
          task.progress,
          isDownloaded: false,
        );
        notifyListeners();
      },
    );

    // Check if download completed successfully
    final isDownloaded = await isEpisodeDownloaded(episode);
    if (isDownloaded) {
      final localFilePath = await _downloadService.getLocalFilePath(episode);
      _audioPlayerService.updateDownloadStatus(
        false,
        1.0,
        isDownloaded: true,
        localFilePath: localFilePath,
      );
    } else {
      _audioPlayerService.updateDownloadStatus(
        false,
        0.0,
        isDownloaded: false,
        localFilePath: null,
      );
    }

    notifyListeners();
  }

  Future<void> deleteDownloadedEpisode(Episode episode) async {
    final success = await _downloadService.deleteDownloadedEpisode(episode);
    if (success) {
      _audioPlayerService.updateDownloadStatus(
        false,
        0.0,
        isDownloaded: false,
        localFilePath: null,
      );
      notifyListeners();
    }
  }

  Future<void> cancelDownload() async {
    if (currentEpisode != null) {
      _downloadService.cancelDownload(currentEpisode!.id);
      _audioPlayerService.updateDownloadStatus(false, 0.0);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayerService.stateStream.removeListener(_onStateChanged);
    _audioPlayerService.dispose();
    _downloadService.dispose();
    super.dispose();
  }
}

// Riverpod provider
final audioPlayerProvider = ChangeNotifierProvider<AudioPlayerNotifier>((ref) {
  return AudioPlayerNotifier();
});
