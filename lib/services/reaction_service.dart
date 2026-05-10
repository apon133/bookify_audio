import 'package:flutter/foundation.dart';
import 'isar_wrapper.dart';
import 'package:hive_ce/hive.dart';
import '../models/models.dart';
import '../models/isar_models.dart';
import 'storage_service.dart';

class ReactionService {
  Isar get _isar => StorageService.isar;
  bool get _isHive => kIsWeb;

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
    if (_isHive) {
      final box = Hive.box<ReactionEntity>('reactions');
      final existing = box.get(episode.id);

      if (existing != null) {
        if (existing.type == type) {
          await box.delete(episode.id);
        } else {
          existing.type = type;
          existing.createdAt = DateTime.now();
          await box.put(episode.id, existing);
        }
      } else {
        final reaction = ReactionEntity()
          ..episodeId = episode.id
          ..type = type
          ..book = _toBookEntity(book)
          ..author = _toAuthorEntity(author)
          ..episode = _toEpisodeEntity(episode)
          ..createdAt = DateTime.now();
        await box.put(episode.id, reaction);
      }
    } else {
      await _isar.writeTxn(() async {
        final existing = await _isar.reactionEntitys.getByEpisodeId(episode.id);
        if (existing != null) {
          if (existing.type == type) {
            await _isar.reactionEntitys.delete(existing.id);
          } else {
            existing.type = type;
            existing.createdAt = DateTime.now();
            await _isar.reactionEntitys.put(existing);
          }
        } else {
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
  }

  Future<ReactionType?> getReaction(String episodeId) async {
    if (_isHive) {
      final box = Hive.box<ReactionEntity>('reactions');
      return box.get(episodeId)?.type;
    } else {
      final reaction = await _isar.reactionEntitys.getByEpisodeId(episodeId);
      return reaction?.type;
    }
  }

  Stream<List<ReactionEntity>> watchReactions() {
    if (_isHive) {
      final box = Hive.box<ReactionEntity>('reactions');
      return box.watch().map((_) => box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    } else {
      return _isar.reactionEntitys
          .where()
          .sortByCreatedAtDesc()
          .watch(fireImmediately: true);
    }
  }

  List<ReactionEntity> getLikedAudios() {
    if (_isHive) {
      final box = Hive.box<ReactionEntity>('reactions');
      return box.values
          .where((r) => r.type == ReactionType.like)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      return _isar.reactionEntitys
          .filter()
          .typeEqualTo(ReactionType.like)
          .sortByCreatedAtDesc()
          .findAllSync();
    }
  }

  List<ReactionEntity> getDislikedAudios() {
    if (_isHive) {
      final box = Hive.box<ReactionEntity>('reactions');
      return box.values
          .where((r) => r.type == ReactionType.dislike)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      return _isar.reactionEntitys
          .filter()
          .typeEqualTo(ReactionType.dislike)
          .sortByCreatedAtDesc()
          .findAllSync();
    }
  }
}

