import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/audio_player_service.dart';
import '../providers/history_provider.dart';

class AudioPlayerNotifier extends ChangeNotifier {
  final Ref _ref;
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  AudioPlayerService get service => _audioPlayerService;

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

  // Mini player visibility
  bool _isMiniPlayerVisible = false;
  bool _manuallyClosed = false;

  bool get isMiniPlayerVisible =>
      _isMiniPlayerVisible && currentEpisode != null;

  AudioPlayerNotifier(this._ref) {
    _audioPlayerService.stateStream.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    // Show mini player when an episode is loaded, unless it was manually closed
    if (currentEpisode != null && !_isMiniPlayerVisible && !_manuallyClosed) {
      _isMiniPlayerVisible = true;
    }

    // Save history through the provider for reactivity
    if (currentEpisode != null &&
        currentBook != null &&
        currentAuthor != null &&
        duration.inSeconds > 0) {
      _ref.read(historyProvider.notifier).savePosition(
            currentEpisode!,
            currentBook!,
            currentAuthor!,
            position.inSeconds.toDouble(),
            duration.inSeconds.toDouble(),
          );
    }

    notifyListeners();
  }

  // Player control methods
  Future<void> playEpisode(Episode episode, Book book, Author author,
      {double? savedPosition}) async {
    _manuallyClosed = false; // Reset when playing a new episode
    await _audioPlayerService.playEpisode(episode, book, author,
        savedPosition: savedPosition);
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
    _manuallyClosed = true;

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

  @override
  void dispose() {
    _audioPlayerService.stateStream.removeListener(_onStateChanged);
    _audioPlayerService.dispose();
    super.dispose();
  }
}

// Riverpod provider
final audioPlayerProvider = ChangeNotifierProvider<AudioPlayerNotifier>((ref) {
  return AudioPlayerNotifier(ref);
});
