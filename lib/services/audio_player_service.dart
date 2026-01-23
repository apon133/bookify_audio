import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/download_service.dart';
import '../services/history_service.dart';
import '../package/audio_player.dart';

class AudioPlayerService {
  // Custom audio player controller (WebView based)
  final BookifyAudioPlayerController _controller =
      BookifyAudioPlayerController();

  // Download service
  final DownloadService _downloadService = DownloadService();

  // Current state
  AudioPlayerState _state = AudioPlayerState();

  // Getters
  AudioPlayerState get state => _state;
  bool get isPlaying => _state.isPlaying;
  bool get isLoading => _state.isLoading;
  Duration get position => _state.position;
  Duration get duration => _state.duration;
  Episode? get currentEpisode => _state.currentEpisode;
  Book? get currentBook => _state.currentBook;
  Author? get currentAuthor => _state.currentAuthor;
  BookifyAudioPlayerController get controller => _controller;

  // Stream controllers for state updates
  final _stateController = ValueNotifier<AudioPlayerState>(AudioPlayerState());
  ValueNotifier<AudioPlayerState> get stateStream => _stateController;

  // History service
  final HistoryService _historyService = HistoryService();

  AudioPlayerService() {
    _initListeners();
  }

  void _initListeners() {
    _controller.addListener(() {
      final controllerState = _controller.value;

      _updateState(
        isPlaying: controllerState.isPlaying,
        isLoading: controllerState.isLoading,
        position: Duration(
            milliseconds: (controllerState.currentTime * 1000).toInt()),
        duration:
            Duration(milliseconds: (controllerState.duration * 1000).toInt()),
      );
    });
  }

  void _updateState({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    Episode? currentEpisode,
    Book? currentBook,
    Author? currentAuthor,
    String? audioUrl,
    double? playbackSpeed,
    bool? isDownloaded,
    String? localFilePath,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    _state = _state.copyWith(
      isPlaying: isPlaying,
      isLoading: isLoading,
      position: position,
      duration: duration,
      currentEpisode: currentEpisode,
      currentBook: currentBook,
      currentAuthor: currentAuthor,
      audioUrl: audioUrl,
      playbackSpeed: playbackSpeed,
      isDownloaded: isDownloaded,
      localFilePath: localFilePath,
      isDownloading: isDownloading,
      downloadProgress: downloadProgress,
    );

    _stateController.value = _state;
  }

  // Update download status
  void updateDownloadStatus(
    bool isDownloading,
    double progress, {
    bool? isDownloaded,
    String? localFilePath,
  }) {
    _updateState(
      isDownloading: isDownloading,
      downloadProgress: progress,
      isDownloaded: isDownloaded,
      localFilePath: localFilePath,
    );
  }

  Future<void> playEpisode(Episode episode, Book book, Author author,
      {double? savedPosition}) async {
    try {
      // Always stop the current playback to ensure clean state
      if (currentEpisode != null) {
        await _controller.pause();
        // Give more time for the previous audio to fully stop
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Determine the position to seek to first (Hive History or provided)
      double positionToSeek = savedPosition ?? 0.0;

      // If no explicit position was provided, check Hive history
      if (savedPosition == null) {
        final historyItems = _historyService.getHistory(uniqueByBook: false);
        final savedItem =
            historyItems.where((i) => i.episode.id == episode.id).firstOrNull;

        // Only use saved position if it's meaningful (> 5 seconds) and not finished
        if (savedItem != null &&
            !savedItem.isFinished &&
            savedItem.position > 5) {
          positionToSeek = savedItem.position;
        }
      }

      // Reset ALL state when loading a new episode, but set position to what we expect
      _updateState(
        isLoading: true,
        isPlaying: false,
        position:
            Duration(seconds: positionToSeek.toInt()), // Optimistic position
        duration: Duration.zero, // Reset duration to zero
        currentEpisode: episode,
        currentBook: book,
        currentAuthor: author,
        isDownloaded: false,
        localFilePath: null,
        isDownloading: false,
        downloadProgress: 0.0,
      );

      // Check if the episode is downloaded
      final isDownloaded = await _downloadService.isEpisodeDownloaded(episode);
      String? localFilePath;

      if (isDownloaded) {
        // Use local file if downloaded
        localFilePath = await _downloadService.getLocalFilePath(episode);
        _updateState(
          isDownloaded: true,
          localFilePath: localFilePath,
        );
      }

      // Always load the URL. Pass the startPosition to avoid starting at 0.
      await _controller.load(episode.audioUrl, startPosition: positionToSeek);

      // Give the WebView more time to initialize and load the video
      await Future.delayed(const Duration(milliseconds: 1000));

      _updateState(isLoading: false, isPlaying: true);
    } catch (e) {
      _updateState(isLoading: false, isPlaying: false);
      rethrow;
    }
  }

  Future<void> play() async {
    await _controller.play();
    _updateState(isPlaying: true);
  }

  Future<void> pause() async {
    await _controller.pause();
    _updateState(isPlaying: false);
  }

  Future<void> seek(Duration position) async {
    await _controller.seekTo(position.inSeconds.toDouble());
    _updateState(position: position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    // Note: Web player currently doesn't expose playback speed, but could be added via JS
    _updateState(playbackSpeed: speed);
  }

  Future<void> stop() async {
    await _controller
        .pause(); // WebView player doesn't have a strict 'stop', pause is fine
    _updateState(
      isPlaying: false,
      // position: Duration.zero, // REMOVED: Don't reset position so history is preserved
    );
  }

  void dispose() {
    _controller.dispose();
  }
}
