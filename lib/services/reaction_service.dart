import 'package:isar/isar.dart';
import '../models/models.dart';
import '../models/isar_models.dart';
import 'playlist_service.dart';

class ReactionService {
  Isar get _isar => PlaylistService.isar;

  // Reusing mappers from service (in a real app, I'd move these to a utility)
  BookEntity _toBookEntity(Book book) {
    return BookEntity()
      ..originalId = book.id
      ..title = book.title
      ..cover = book.cover
      ..author = book.author
      ..authorImage = book.authorImage
      ..episodes = book.episodes.map(_toEpisodeEntity).toList();
  }

  EpisodeEntity _toEpisodeEntity(Episode episode) {
    return EpisodeEntity()
      ..id = episode.id
      ..bookName = episode.bookName
      ..audioUrl = episode.audioUrl
      ..voiceOwner = episode.voiceOwner;
  }

  AuthorEntity _toAuthorEntity(Author author) {
    return AuthorEntity()
      ..id = author.id
      ..name = author.name
      ..image = author.image;
  }

  Future<void> toggleLike(Episode episode, Book book, Author author) async {
    await _toggleReaction(episode, book, author, ReactionType.like);
  }

  Future<void> toggleDislike(Episode episode, Book book, Author author) async {
    await _toggleReaction(episode, book, author, ReactionType.dislike);
  }

  Future<void> _toggleReaction(
      Episode episode, Book book, Author author, ReactionType type) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.reactionEntitys.getByEpisodeId(episode.id);

      if (existing != null) {
        if (existing.type == type) {
          // Toggle off (remove)
          await _isar.reactionEntitys.delete(existing.id);
        } else {
          // Switch reaction (e.g. from like to dislike)
          existing.type = type;
          existing.createdAt =
              DateTime.now(); // Update time or keep original? Update usually.
          await _isar.reactionEntitys.put(existing);
        }
      } else {
        // Create new
        final reaction = ReactionEntity()
          ..episodeId = episode.id
          ..type = type
          ..book = _toBookEntity(book)
          ..author = _toAuthorEntity(author)
          ..episode = _toEpisodeEntity(episode)
          ..createdAt = DateTime.now();
        await _isar.reactionEntitys.put(reaction);
      }
    });
  }

  Future<ReactionType?> getReaction(String episodeId) async {
    final reaction = await _isar.reactionEntitys.getByEpisodeId(episodeId);
    return reaction?.type;
  }

  Stream<List<ReactionEntity>> watchReactions() {
    return _isar.reactionEntitys
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  // For Settings Screen
  List<ReactionEntity> getLikedAudios() {
    return _isar.reactionEntitys
        .filter()
        .typeEqualTo(ReactionType.like)
        .sortByCreatedAtDesc()
        .findAllSync();
  }

  List<ReactionEntity> getDislikedAudios() {
    return _isar.reactionEntitys
        .filter()
        .typeEqualTo(ReactionType.dislike)
        .sortByCreatedAtDesc()
        .findAllSync();
  }
}
