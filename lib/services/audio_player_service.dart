import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/history_service.dart';
import '../package/audio_player.dart';

class AudioPlayerService {
  // Custom audio player controller (WebView based)
  final BookifyAudioPlayerController _controller =
      BookifyAudioPlayerController();

  // Download service

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
    );

    _stateController.value = _state;
  }

  // Update download status

  Future<void> playEpisode(Episode episode, Book book, Author author,
      {double? savedPosition}) async {
    try {
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

      // 1. UPDATE STATE IMMEDIATELY AND SYNCHRONOUSLY
      // This ensures UI updates (like showing the pause button) happen instantly
      _updateState(
        isLoading: true,
        isPlaying: true, // Optimistically show playing/pause state
        position:
            Duration(seconds: positionToSeek.toInt()), // Optimistic position
        duration: Duration.zero, // Reset duration to zero
        currentEpisode: episode,
        currentBook: book,
        currentAuthor: author,
      );

      // 2. Then do the heavy lifting
      // Always stop the current playback to ensure clean state
      // (We don't await this if it's not strictly necessary, or keep it short)
      await _controller.pause();

      // Always load the URL. Pass the startPosition to avoid starting at 0.
      await _controller.load(episode.audioUrl, startPosition: positionToSeek);

      // Give the WebView a bit of time to initialize
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
        // Explicitly play to ensure audio starts on mobile
        await _controller.play();
      }

      _updateState(isLoading: false);
    } catch (e) {
      print('AudioPlayerService: Error playing episode: $e');
      _updateState(isLoading: false, isPlaying: false);
      rethrow;
    }
  }

  Future<void> play() async {
    await _controller.play();
  }

  Future<void> pause() async {
    await _controller.pause();
  }

  Future<void> seek(Duration position) async {
    await _controller.seekTo(position.inSeconds.toDouble());
    _updateState(position: position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _controller.setPlaybackRate(speed);
    _updateState(playbackSpeed: speed);
  }

  Future<void> stop() async {
    await _controller.stop();
  }

  void dispose() {
    _controller.dispose();
  }
}
