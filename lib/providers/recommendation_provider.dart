import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recommendation/recommendation_service.dart';
import '../providers/history_provider.dart';
import '../providers/reaction_provider.dart';
import '../providers/playlist_provider.dart';

class RecommendationNotifier extends ChangeNotifier {
  final RecommendationService _recommendationService = RecommendationService();
  List<RecommendedBook> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  List<RecommendedBook> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendations() async {
    _isLoading = true;
    _error = null;

    try {
      _recommendations = await _recommendationService.getRecommendations();
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

  final notifier = RecommendationNotifier();
  notifier.fetchRecommendations();
  return notifier;
});
