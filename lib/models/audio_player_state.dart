import 'episode.dart';
import 'book.dart';
import 'author.dart';

class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final Episode? currentEpisode;
  final Book? currentBook;
  final Author? currentAuthor;
  final String? audioUrl;
  final double playbackSpeed;

  AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.currentEpisode,
    this.currentBook,
    this.currentAuthor,
    this.audioUrl,
    this.playbackSpeed = 1.0,
  });

  AudioPlayerState copyWith({
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
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      currentBook: currentBook ?? this.currentBook,
      currentAuthor: currentAuthor ?? this.currentAuthor,
      audioUrl: audioUrl ?? this.audioUrl,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}
