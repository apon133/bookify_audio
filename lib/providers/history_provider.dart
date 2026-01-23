import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/history_service.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  final HistoryService _historyService = HistoryService();

  HistoryNotifier() : super([]) {
    loadHistory();
  }

  void loadHistory() {
    // Load all episodes, not just unique by book
    state = _historyService.getHistory(uniqueByBook: false);
  }

  Future<void> savePosition(dynamic episode, dynamic book, dynamic author,
      double position, double duration) async {
    await _historyService.savePosition(
        episode, book, author, position, duration);
    loadHistory(); // Refresh state
  }

  List<HistoryItem> get continueWatching =>
      state.where((item) => !item.isFinished).toList();

  List<HistoryItem> get playHistory => state;

  Future<void> remove(String episodeId) async {
    await _historyService.remove(episodeId);
    loadHistory();
  }

  Future<void> removeBookHistory(String bookId) async {
    await _historyService.removeBookHistory(bookId);
    loadHistory();
  }
}
