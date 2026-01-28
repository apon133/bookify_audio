import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../models/isar_models.dart';
import '../services/reaction_service.dart';

final reactionServiceProvider = Provider((ref) => ReactionService());

final reactionProvider =
    StateNotifierProvider<ReactionNotifier, Map<String, ReactionType?>>((ref) {
  return ReactionNotifier(ref.watch(reactionServiceProvider));
});

class ReactionNotifier extends StateNotifier<Map<String, ReactionType?>> {
  final ReactionService _service;

  ReactionNotifier(this._service) : super({});

  Future<void> checkReaction(String episodeId) async {
    final reaction = await _service.getReaction(episodeId);
    state = {...state, episodeId: reaction};
  }

  Future<void> toggleLike(Episode episode, Book book, Author author) async {
    await _service.toggleLike(episode, book, author);
    await checkReaction(episode.id);
  }

  Future<void> toggleDislike(Episode episode, Book book, Author author) async {
    await _service.toggleDislike(episode, book, author);
    await checkReaction(episode.id);
  }
}

final likedAudioProvider = FutureProvider<List<ReactionEntity>>((ref) async {
  // This is a simple future provider, but could be a stream provider
  // For now, let's just make it auto-refresh when re-entered settings
  return ref.watch(reactionServiceProvider).getLikedAudios();
});
