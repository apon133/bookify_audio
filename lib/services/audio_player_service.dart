import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/download_service.dart';
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

  Future<void> playEpisode(Episode episode, Book book, Author author) async {
    try {
      // Check if the same episode is already playing
      if (currentEpisode != null &&
          currentEpisode!.id == episode.id &&
          isPlaying) {
        return;
      }

      // If a different episode is playing, stop it first
      if (isPlaying) {
        await stop();
      }

      // Reset download status when loading a new episode
      _updateState(
        isLoading: true,
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
        // Note: For now, local file playback is not implemented in the WebView-based controller.
        // If local playback is needed, we would need a different approach for offline.
      } else {
        // Load YouTube URL directly into the WebView controller
        await _controller.load(episode.audioUrl);
      }

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
      position: Duration.zero,
    );
  }

  void dispose() {
    _controller.dispose();
  }
}
