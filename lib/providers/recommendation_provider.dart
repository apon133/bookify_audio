import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recommendation/recommendation_service.dart';
import '../providers/history_provider.dart';
import '../providers/reaction_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_player_provider.dart';

class RecommendationNotifier extends ChangeNotifier {
  final RecommendationService _recommendationService = RecommendationService();
  List<RecommendedBook> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  List<RecommendedBook> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendations({double speed = 1.0}) async {
    _isLoading = true;
    _error = null;

    try {
      _recommendations = await _recommendationService.getRecommendations(
          currentPlaybackSpeed: speed);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}

final recommendationProvider =
    ChangeNotifierProvider<RecommendationNotifier>((ref) {
  // Watch only significant changes to avoid "flipping" during playback
  // Only trigger when:
  // 1. Number of books in history changes (new book started)
  ref.watch(historyProvider.select((h) => h.length));
  // 2. Reactions change (liked/disliked)
  ref.watch(reactionProvider);
  // 3. Playlists change
  ref.watch(playlistProvider);
  // 4. Playback speed changes
  // We need to import audio_player_provider.dart to access it.
  // Assuming it is available or we need to import it.
  // We will assume import is needed or already there?
  // It is NOT in the imports list in view_file Step 62.
  // So we must add the import AND update the code.
  // We cannot easily add imports with replace_file_content if we don't know where to put it or if it's messy.
  // But we can try.

  // Wait, I recall seeing imports in Step 62.
  // audio_player_provider is not imported.
  // I need to add `import '../providers/audio_player_provider.dart';`

  final speed = ref.watch(audioPlayerProvider.select((p) => p.playbackSpeed));

  final notifier = RecommendationNotifier();
  notifier.fetchRecommendations(speed: speed);
  return notifier;
});
